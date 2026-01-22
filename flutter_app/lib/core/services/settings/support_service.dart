class SupportTicket {
  final String message;
  final DateTime createdAt;

  SupportTicket({required this.message, required this.createdAt});
}

/// ✅ MOCK
/// TODO(BACKEND): enviar para endpoint/Helpdesk
class SettingsSupportService {
  Future<void> sendSupportMessage(String message) async {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> sendFeedback(String message, int rating) async {
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> sendBugReport(String message, {String? steps}) async {
    await Future.delayed(const Duration(milliseconds: 250));
  }
}
