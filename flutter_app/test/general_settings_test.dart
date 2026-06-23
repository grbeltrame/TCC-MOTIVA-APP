import 'package:flutter_app/core/services/settings/general_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AthleteGeneralSettings', () {
    test('defaults keep every athlete notification category enabled', () {
      final settings = AthleteGeneralSettings.defaults();

      expect(settings.weeklyInsights, isTrue);
      expect(settings.evolutionInsights, isTrue);
      expect(settings.preWorkoutInsights, isTrue);
      expect(settings.trainingReminders, isTrue);
    });

    test('fromMap preserves missing values as enabled defaults', () {
      final settings = AthleteGeneralSettings.fromMap({
        'weeklyInsights': false,
      });

      expect(settings.weeklyInsights, isFalse);
      expect(settings.evolutionInsights, isTrue);
      expect(settings.preWorkoutInsights, isTrue);
      expect(settings.trainingReminders, isTrue);
    });
  });

  group('CoachGeneralSettings', () {
    test('defaults keep every coach notification category enabled', () {
      final settings = CoachGeneralSettings.defaults();

      expect(settings.dailyTrainingAnalysis, isTrue);
      expect(settings.cycleAnalysis, isTrue);
      expect(settings.missingTrainingReminder, isTrue);
    });
  });

  test('PrivacySettingsState defaults allow personalized AI', () {
    final settings = PrivacySettingsState.defaults();

    expect(settings.aiPersonalizationEnabled, isTrue);
    expect(settings.diagnosticsEnabled, isTrue);
  });
}
