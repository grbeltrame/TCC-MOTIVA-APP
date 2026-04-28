import 'package:flutter_app/core/services/settings/general_settings_service.dart';

typedef SettingsPrivacyState = PrivacySettingsState;

class SettingsPrivacyService {
  SettingsPrivacyService({UserSettingsService? settingsService})
    : _settingsService = settingsService ?? UserSettingsService.instance;

  final UserSettingsService _settingsService;

  Future<SettingsPrivacyState> fetch() {
    return _settingsService.fetchPrivacySettings();
  }

  Future<void> update(SettingsPrivacyState next) {
    return _settingsService.updatePrivacySettings(next);
  }
}
