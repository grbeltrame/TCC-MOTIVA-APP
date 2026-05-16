import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/shared/models/profile_option.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static final AuthService instance = AuthService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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

  Future<void> signOut() => _auth.signOut();
}
