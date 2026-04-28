import 'package:cloud_functions/cloud_functions.dart';

class SettingsSupportService {
  SettingsSupportService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<void> sendSupportMessage(String message) {
    return _submit(type: 'support', message: message);
  }

  Future<void> sendFeedback(String message, int rating) {
    return _submit(type: 'feedback', message: message, rating: rating);
  }

  Future<void> sendBugReport(String message, {String? steps}) {
    return _submit(type: 'bug_report', message: message, steps: steps);
  }

  Future<void> _submit({
    required String type,
    required String message,
    int? rating,
    String? steps,
  }) async {
    await _functions.httpsCallable('submit_support_ticket').call({
      'type': type,
      'message': message,
      if (rating != null) 'rating': rating,
      if (steps != null && steps.trim().isNotEmpty) 'steps': steps,
    });
  }
}
