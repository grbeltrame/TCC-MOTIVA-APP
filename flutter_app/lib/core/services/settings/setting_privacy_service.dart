class SettingsPrivacyState {
  bool shareAnalytics;
  bool shareCrashReports;

  SettingsPrivacyState({
    required this.shareAnalytics,
    required this.shareCrashReports,
  });

  factory SettingsPrivacyState.defaults() =>
      SettingsPrivacyState(shareAnalytics: true, shareCrashReports: true);
}

/// ✅ MOCK
/// TODO(BACKEND): persistir por usuário
class SettingsPrivacyService {
  static SettingsPrivacyState _cache = SettingsPrivacyState.defaults();

  Future<SettingsPrivacyState> fetch() async {
    await Future.delayed(const Duration(milliseconds: 180));
    return _cache;
  }

  Future<void> update(SettingsPrivacyState next) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _cache = next;
  }
}
