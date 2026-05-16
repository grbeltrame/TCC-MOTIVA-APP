import 'package:flutter_app/core/services/settings/general_settings_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PrivacySettingsState defaults allow personalized AI', () {
    final settings = PrivacySettingsState.defaults();

    expect(settings.aiPersonalizationEnabled, isTrue);
    expect(settings.diagnosticsEnabled, isTrue);
  });
}
