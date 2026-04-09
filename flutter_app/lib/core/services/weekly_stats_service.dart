// lib/core/services/weekly_stats_service.dart

import 'package:flutter_app/core/services/athlete_stats_service.dart';

class WeeklyStatsType {
  static const String cargas = 'cargas_semana';
  static const String frequencia = 'frequencia_semana';
  static const String esforco = 'esforco_semana';
  static const String tipos = 'tipos_treino';
  static const String descanso = 'descanso';
}

class WeeklyStatsService {
  /// Retorna o valor formatado para cada card de estatística semanal.
  /// Lê do summary pré-calculado — 1 doc read, sem query pesada.
  static Future<String> getWeeklyStat({required String tipo}) async {
    final summary = await AthleteStatsService.fetchSummary();

    if (summary == null) {
      return tipo == WeeklyStatsType.esforco ? '–/10' : '–';
    }

    switch (tipo) {
      case WeeklyStatsType.frequencia:
        final count = summary.currentWeekTrainingDays;
        return '$count ${count == 1 ? 'treino' : 'treinos'}';

      case WeeklyStatsType.esforco:
        final effort = summary.averageEffortCurrentWeek;
        return effort > 0 ? '${effort.toStringAsFixed(1)}/10' : '–/10';

      case WeeklyStatsType.cargas:
        // Carga será implementada em melhoria futura (campo opcional no registro)
        return '–';

      default:
        return '–';
    }
  }

  /// Retorna valor formatado para um período customizado [from, to].
  /// [trainingType] filtra por tipo (null = todos).
  static Future<String> getStatForPeriod({
    required String tipo,
    required DateTime from,
    required DateTime to,
    String? trainingType,
  }) async {
    if (tipo == WeeklyStatsType.cargas) return '–';

    final series = await AthleteStatsService.fetchEffortSeries(
      from: from,
      to: to,
      wodType: trainingType,
    );

    if (tipo == WeeklyStatsType.frequencia) {
      final uniqueDays =
          series
              .map((e) => '${e.date.year}-${e.date.month}-${e.date.day}')
              .toSet();
      final count = uniqueDays.length;
      return '$count ${count == 1 ? 'treino' : 'treinos'}';
    }

    if (tipo == WeeklyStatsType.esforco) {
      if (series.isEmpty) return '–/10';
      final avg =
          series.map((e) => e.percent).reduce((a, b) => a + b) / series.length;
      return '${avg.toStringAsFixed(1)}/10';
    }

    if (tipo == WeeklyStatsType.descanso) {
      final count = await AthleteStatsService.fetchRestCount(
        from: from,
        to: to,
      );
      return '$count ${count == 1 ? 'dia' : 'dias'}';
    }

    if (tipo == WeeklyStatsType.tipos) {
      final types = await AthleteStatsService.fetchTrainingTypes(
        from: from,
        to: to,
      );
      if (types.isEmpty) return '–';
      return types.join(' · ');
    }

    return '–';
  }
}
