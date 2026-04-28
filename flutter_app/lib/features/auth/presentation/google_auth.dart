import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/core/services/auth_service.dart';

class GoogleSignInService {
  static Future<UserCredential?> signInWithGoogle() async {
    final result = await AuthService.instance.signInWithGoogle();
    return result.userCredential;
  }

  static Future<void> signOut() {
    return AuthService.instance.signOut();
  }

  static User? getCurrentUser() {
    return AuthService.instance.currentUser;
  }
}
