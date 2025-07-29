/// lib/core/services/weekly_stats_service.dart

class WeeklyStatsType {
  static const String cargas = 'cargas_semana';
  static const String frequencia = 'frequencia_semana';
  static const String esforco = 'esforco_semana';
}

class WeeklyStatsService {
  /// Mock hard‑coded — depois integra ao backend real.
  static Future<String> getWeeklyStat({required String tipo}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    switch (tipo) {
      case WeeklyStatsType.cargas:
        return '30 kg'; // soma total de cargas da semana
      case WeeklyStatsType.frequencia:
        return '2 treinos'; // quantos treinos esta semana
      case WeeklyStatsType.esforco:
        return '7.1/10'; // média de esforço na semana
      default:
        return 'N/A';
    }
  }
}
