// auth_service.dart
// Serviço de autenticação: Email/Password + Google Sign-In (compatível com google_sign_in v7+).
// Mantém documento /users/{uid} com role controlada e helpers para Cloud Function setUserRole.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show debugPrint;

// Substitua pelo path correto onde seu enum ProfileOption está definido.
import 'package:flutter_app/features/auth/presentation/signup_screen.dart' show ProfileOption;

class AuthService {
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Google Sign-In (v7+: singleton API)
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  AuthService();

  /// Inicializa GoogleSignIn (v7+). Só marca `_googleInitialized = true` se a inicialização for bem-sucedida.
  Future<void> initializeGoogleSignIn({String? clientId, String? serverClientId}) async {
    if (_googleInitialized) return;
    try {
      await _googleSignIn.initialize(clientId: clientId, serverClientId: serverClientId);
      _googleInitialized = true;
    } catch (e, st) {
      _googleInitialized = false;
      debugPrint('Erro ao inicializar GoogleSignIn: $e\n$st');
      rethrow;
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /* -------------------- E-mail / Senha -------------------- */

  /// Cadastro com e-mail e senha.
  Future<User?> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required ProfileOption profile,
    bool forceRole = false,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;

      if (user != null) {
        // atualiza displayName no Auth (se disponível na versão do SDK)
        try {
          await user.updateDisplayName(name);
          await user.reload();
        } catch (e) {
          debugPrint('updateDisplayName falhou (compatibilidade de SDK): $e');
        }

        await _createOrUpdateUserInFirestore(user: user, name: name, profile: profile, forceRole: forceRole);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      throw Exception('Erro desconhecido durante cadastro com email: $e');
    }
  }

  Future<User?> signInWithEmailAndPassword({required String email, required String password}) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw Exception('Erro desconhecido durante login com email: $e');
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Erro ao enviar email para redefinição de senha: $e');
    }
  }

  /* -------------------- Google Sign-In -------------------- */

  /// Faz login com Google. Recebe o ProfileOption (não assume valores do enum).
  Future<User?> signInWithGoogle({
    required ProfileOption profile,
    String? clientId,
    String? serverClientId,
    bool forceRole = false,
  }) async {
    try {
      await initializeGoogleSignIn(clientId: clientId, serverClientId: serverClientId);

      GoogleSignInAccount? googleUser;
      try {
        // Nova API v7+: authenticate()
        googleUser = await _googleSignIn.authenticate();
      } catch (e) {
        // Fallback para versões anteriores (mantive dentro de try/catch)
        try {
          googleUser = await (_googleSignIn as dynamic).signIn();
        } catch (e2) {
          debugPrint('GoogleSignIn fallback falhou: $e2');
          rethrow;
        }
      }

      if (googleUser == null) return null; // usuário cancelou

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Em google_sign_in v7 o accessToken pode não existir; idToken é suficiente para signInWithCredential.
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        throw Exception('idToken do Google é nulo. Não foi possível autenticar.');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(idToken: idToken);

      try {
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final User? user = userCredential.user;

        if (user != null) {
          await _createOrUpdateUserInFirestore(
            user: user,
            name: user.displayName ?? 'Usuário Google',
            profile: profile,
            forceRole: forceRole,
          );
        }
        return user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          // fetchSignInMethodsForEmail foi removido/limitado em versões recentes do Firebase Auth (evita email enumeration).
          // Em vez de tentar buscar métodos, informamos o usuário com o email em conflito e orientamos os próximos passos.
          final conflictingEmail = googleUser.email ?? e.email;
          final msgBase =
              'Já existe uma conta com o mesmo e-mail usando outro provedor. Por favor, entre com o provedor original ou use a recuperação de senha.';
          final msg = (conflictingEmail != null) ? '$msgBase Email: $conflictingEmail' : msgBase;
          throw FirebaseAuthException(code: e.code, message: msg);
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Erro durante login com Google: $e');
    }
  }

  /// Chama Cloud Function 'setUserRole' para solicitar alteração de role.
  Future<HttpsCallableResult> requestRoleChange({required String uid, required String newRole}) async {
    try {
      final callable = _functions.httpsCallable('setUserRole');
      final result = await callable.call({'uid': uid, 'role': newRole});
      return result;
    } catch (e) {
      throw Exception('Erro ao solicitar alteração de role: $e');
    }
  }

  /// Método perigoso: altera role direto no Firestore pelo cliente. NÃO usar em produção salvo regras específicas.
  Future<void> adminSetUserRoleClient({required String uid, required String role}) async {
    final userRef = _firestore.collection('users').doc(uid);
    await userRef.set({'role': role}, SetOptions(merge: true));
  }

  /* -------------------- Conta / Perfil -------------------- */

  Future<String?> getUserRole(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) return docSnapshot.data()?['role'] as String?;
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar role: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> updateDisplayName(String displayName) async {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Nenhum usuário autenticado.');
    try {
      await u.updateDisplayName(displayName);
      await u.reload();
    } catch (e) {
      throw Exception('Falha ao atualizar displayName: $e');
    }
  }

  /// Verificação recomendada para atualização de e-mail: envia um e-mail para confirmar o novo endereço.
  Future<void> updateEmail(String newEmail) async {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Nenhum usuário autenticado.');
    try {
      await u.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
            code: e.code, message: 'Operação sensível: reautentique o usuário e tente novamente.');
      }
      rethrow;
    } catch (e) {
      throw Exception('Falha ao iniciar fluxo de atualização de e-mail: $e');
    }
  }

  /// Atualiza senha localmente. Atenção: algumas operações exigem reautenticação prévia.
  Future<void> updatePassword(String newPassword) async {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Nenhum usuário autenticado.');
    try {
      await u.updatePassword(newPassword);
      await u.reload();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw FirebaseAuthException(
            code: e.code, message: 'Operação sensível: reautentique o usuário e tente novamente.');
      }
      rethrow;
    } catch (e) {
      throw Exception('Falha ao atualizar senha: $e');
    }
  }

  /* -------------------- Firestore helper -------------------- */

  Future<void> _createOrUpdateUserInFirestore({
    required User user,
    required String name,
    required ProfileOption profile,
    bool forceRole = false,
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    final doc = await userRef.get();

    // Role derivada do ProfileOption. Evitamos referenciar constantes enum específicas
    // (ex: ProfileOption.aluno) para não quebrar se o enum tiver nomes diferentes.
    final roleFromProfile = _roleFromProfileOption(profile);

    if (doc.exists) {
      final data = doc.data() ?? {};
      final existingRole = data['role'] as String?;

      final roleToWrite = (existingRole == null || forceRole) ? roleFromProfile : existingRole;

      await userRef.set(
        {
          'nome': name,
          'email': user.email,
          'role': roleToWrite,
          'uid': user.uid,
          'dataAtualizacao': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } else {
      await userRef.set(
        {
          'nome': name,
          'email': user.email,
          'role': roleFromProfile,
          'uid': user.uid,
          'dataCriacao': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  /// Faz o mapeamento entre ProfileOption (qualquer nome que o enum tenha) e os strings 'aluno'/'coach'.
  String _roleFromProfileOption(ProfileOption profile) {
    final raw = profile.toString().split('.').last.toLowerCase();
    if (raw.contains('coach') || raw.contains('treinador') || raw.contains('instrutor')) {
      return 'coach';
    }
    // default para 'aluno' caso não detecte 'coach'
    return 'aluno';
  }
}
