class CoachGeneralSettings {
  bool weeklySummary;
  bool weeklyInsightsAlerts;

  bool prefMorning;
  bool prefAfternoon;
  bool prefNight;

  String unit; // 'kg' | 'lb'
  String language; // ex.: 'Português - BR'

  CoachGeneralSettings({
    required this.weeklySummary,
    required this.weeklyInsightsAlerts,
    required this.prefMorning,
    required this.prefAfternoon,
    required this.prefNight,
    required this.unit,
    required this.language,
  });

  factory CoachGeneralSettings.defaults() => CoachGeneralSettings(
    weeklySummary: true,
    weeklyInsightsAlerts: true,
    prefMorning: false,
    prefAfternoon: false,
    prefNight: false,
    unit: 'kg',
    language: 'Português - BR',
  );
}

/// ✅ MOCK service: hoje salva em memória
/// TODO(BACKEND): trocar para API/Firestore/DB e persistir por usuário
class CoachSettingsService {
  static CoachGeneralSettings _cache = CoachGeneralSettings.defaults();

  Future<CoachGeneralSettings> fetchGeneralSettings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _cache;
  }

  Future<void> updateGeneralSettings(CoachGeneralSettings next) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _cache = next;
  }
}
