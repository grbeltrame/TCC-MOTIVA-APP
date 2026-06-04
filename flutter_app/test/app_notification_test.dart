import 'package:flutter_app/shared/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotification.displayTitle', () {
    AppNotification notification(AppNotificationRole role) {
      return AppNotification(
        id: 'n1',
        role: role,
        type: 'test',
        title: 'Análise pronta',
        body: 'Mensagem',
        status: 'unread',
        createdAt: null,
        readAt: null,
        routeName: null,
        routeArgs: const {},
        sourceId: null,
      );
    }

    test('does not prefix simple athlete profiles', () {
      expect(
        notification(AppNotificationRole.athlete).displayTitle('athlete'),
        'Análise pronta',
      );
    });

    test('does not prefix simple coach profiles', () {
      expect(
        notification(AppNotificationRole.coach).displayTitle('coach'),
        'Análise pronta',
      );
    });

    test('prefixes athlete notification for hybrid profiles', () {
      expect(
        notification(AppNotificationRole.athlete).displayTitle('athleteCoach'),
        '[atleta] Análise pronta',
      );
    });

    test('prefixes coach notification for hybrid profiles', () {
      expect(
        notification(AppNotificationRole.coach).displayTitle('athleteIntern'),
        '[coach] Análise pronta',
      );
    });
  });
}
