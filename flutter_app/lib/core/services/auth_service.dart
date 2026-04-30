import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/shared/models/profile_option.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _googleSignInServerClientId =
    '430412921098-2c7uaur967aij1p6qs5h76r2h1ftkn3o.apps.googleusercontent.com';

class GoogleAuthResult {
  final UserCredential userCredential;
  final bool hasCompletedProfile;

  const GoogleAuthResult({
    required this.userCredential,
    required this.hasCompletedProfile,
  });
}

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  static final AuthService instance = AuthService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  Future<void>? _googleSignInInitialization;

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    required ProfileOption profile,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = userCredential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Usuario criado, mas nao retornado pelo Firebase Auth.',
      );
    }

    final trimmedName = name.trim();
    await _users.doc(user.uid).set({
      'uid': user.uid,
      'name': trimmedName,
      'email': user.email,
      'photoURL': user.photoURL ?? '',
      'profile': profile.storageValue,
      'provider': 'email',
      'accountStatus': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await user.updateDisplayName(trimmedName);
    return userCredential;
  }

  Future<GoogleAuthResult> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    final googleUser = await _googleSignIn.authenticate();
    final idToken = googleUser.authentication.idToken;
    final authorizationClient = googleUser.authorizationClient;

    var authorization = await authorizationClient.authorizationForScopes([
      'email',
      'profile',
    ]);
    var accessToken = authorization?.accessToken;

    if (accessToken == null) {
      authorization = await authorizationClient.authorizationForScopes([
        'email',
        'profile',
      ]);
      accessToken = authorization?.accessToken;
    }

    if (accessToken == null && idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-token',
        message: 'Nao foi possivel obter credenciais do Google.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Login realizado, mas usuario nao retornado pelo Firebase.',
      );
    }

    final hasCompletedProfile = await _ensureGoogleUserDocument(user);
    return GoogleAuthResult(
      userCredential: userCredential,
      hasCompletedProfile: hasCompletedProfile,
    );
  }

  Future<void> completeCurrentUserProfile({
    required ProfileOption profile,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario nao esta logado. Tente novamente.');
    }

    await _users.doc(user.uid).set({
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoURL': user.photoURL ?? '',
      'profile': profile.storageValue,
      'provider': 'google',
      'accountStatus': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String?> fetchUserProfileType(String uid) async {
    final doc = await _users.doc(uid).get();
    final data = doc.data();
    final profile = data?['profile'];
    if (profile is String && profile.trim().isNotEmpty) {
      return profile;
    }
    return null;
  }

  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.data();
  }

  bool isAccountDisabled(Map<String, dynamic>? userData) {
    return userData?['accountStatus'] == 'disabled';
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.setLanguageCode('pt-BR');
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleSignInInitialized();
      await _googleSignIn.signOut();
    } finally {
      await _auth.signOut();
    }
  }

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitialization ??= _googleSignIn.initialize(
      serverClientId: _googleSignInServerClientId,
    );
  }

  Future<bool> _ensureGoogleUserDocument(User user) async {
    final userDoc = _users.doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'provider': 'google',
        'accountStatus': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return false;
    }

    final profile = docSnapshot.data()?['profile'];
    return profile is String && profile.trim().isNotEmpty;
  }
}
