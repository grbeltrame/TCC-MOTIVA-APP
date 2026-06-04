import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/core/services/auth_service.dart';

class AccountService {
  AccountService({
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
    AuthService? authService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'us-central1'),
       _authService = authService ?? AuthService.instance;

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final AuthService _authService;

  Future<void> requestPasswordReset({required String email}) {
    return _authService.sendPasswordResetEmail(email);
  }

  Future<void> sendCurrentUserPasswordResetAndSignOut() async {
    final email = _auth.currentUser?.email;
    if (email == null || email.trim().isEmpty) {
      throw StateError('Usuario logado nao possui email cadastrado.');
    }

    await requestPasswordReset(email: email);
    await _authService.signOut();
  }

  Future<void> deactivateCurrentAccount() async {
    await _functions.httpsCallable('deactivate_current_user_account').call();
    await _authService.signOut();
  }

  Future<void> reactivateCurrentAccount() async {
    await _functions.httpsCallable('reactivate_current_user_account').call();
  }

  Future<void> deleteCurrentAccount() async {
    await _functions.httpsCallable('delete_current_user_account').call();
    await _authService.signOut();
  }
}
