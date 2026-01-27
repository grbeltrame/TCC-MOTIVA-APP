class AccountService {
  /// TODO(BACKEND): disparar reset password via backend/auth provider
  Future<void> requestPasswordReset({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  /// TODO(BACKEND): criar request de download e retornar protocolo
  Future<String> requestDataDownload() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'REQ-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// TODO(BACKEND): desativar conta (soft delete / suspensão)
  Future<void> requestDeactivateAccount() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// TODO(BACKEND): solicitar exclusão permanente (LGPD)
  Future<void> requestDeleteAccount() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
