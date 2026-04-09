// lib/core/services/weekly_summary_service.dart

import 'package:flutter_app/core/services/athlete_stats_service.dart';

// =============================================================================
// Models (mantidos para compatibilidade com os widgets existentes)
// =============================================================================

class InsightModel {
  final String type;
  final String message;
  InsightModel({required this.type, required this.message});
}

/// Intervalo da semana (seg → dom).
class WeekRange {
  final DateTime start;
  final DateTime end;
  WeekRange(this.start, this.end);
}

class StimulusCount {
  final String name;
  final int count;
  StimulusCount(this.name, this.count);
}

class TotalLoad {
  final double totalKg;
  final double previousWeekKg;
  TotalLoad({required this.totalKg, required this.previousWeekKg});

  double get differenceKg => totalKg - previousWeekKg;
  double get percentChange =>
      previousWeekKg > 0 ? (differenceKg / previousWeekKg) * 100 : 0;
  double get absolutePercentChange => percentChange.abs();

  String get changeComment {
    final p = absolutePercentChange.toStringAsFixed(1);
    if (percentChange > 0) return '$p% maior que a semana anterior';
    if (percentChange < 0) return '$p% menor que a semana anterior';
    return 'Mesmo total da semana anterior';
  }
}

class PRModel {
  final String label;
  PRModel(this.label);
}

class EffortModel {
  final double score;
  final String comment;
  EffortModel(this.score, this.comment);
}

// =============================================================================
// WeeklySummaryService
// =============================================================================

class WeeklySummaryService {
  /// Semana atual (seg → dom) calculada localmente — sem Firestore.
  WeekRange fetchCurrentWeekRange() {
    final now = DateTime.now();
    // weekday: 1=seg, 7=dom
    final daysFromMonday = now.weekday - 1;
    final monday = now.subtract(Duration(days: daysFromMonday));
    final sunday = monday.add(const Duration(days: 6));
    return WeekRange(
      monday.copyWith(hour: 0, minute: 0, second: 0, microsecond: 0),
      sunday.copyWith(hour: 23, minute: 59, second: 59, microsecond: 0),
    );
  }

  /// Dias treinados nesta semana — lê do summary pré-calculado.
  Future<Set<DateTime>> fetchDaysTrained() async {
    final summary = await AthleteStatsService.fetchSummary();
    if (summary == null) return {};

    final days = <DateTime>{};
    summary.currentWeekCalendar.forEach((dateStr, type) {
      if (type == DayActivityType.wod) {
        try {
          days.add(DateTime.parse(dateStr));
        } catch (_) {}
      }
    });
    return days;
  }

  /// Estímulos da semana — lê do summary pré-calculado.
  Future<List<StimulusCount>> fetchStimuliCounts() async {
    final summary = await AthleteStatsService.fetchSummary();
    if (summary == null) return [];

    return summary.stimuliSorted
        .map((e) => StimulusCount(e.key, e.value))
        .toList();
  }

  /// Carga total — pendente de implementação futura.
  Future<TotalLoad> fetchTotalLoad() async {
    return TotalLoad(totalKg: 0, previousWeekKg: 0);
  }

  /// PRs da semana — pendente de implementação futura.
  Future<List<PRModel>> fetchPRs() async {
    return [];
  }

  /// Esforço médio da semana — lê do summary pré-calculado.
  Future<EffortModel> fetchEffort() async {
    final summary = await AthleteStatsService.fetchSummary();
    if (summary == null) return EffortModel(0, 'Nenhum treino registrado');

    final score = summary.averageEffortCurrentWeek;
    final comment = switch (score) {
      0 => 'Nenhum treino registrado',
      < 4 => 'Semana tranquila',
      < 6 => 'Intensidade moderada',
      < 8 => 'Semana intensa',
      _ => 'Semana muito intensa',
    };

    return EffortModel(score, comment);
  }

  /// Estímulos de um período customizado — consulta results/ diretamente.
  Future<List<StimulusCount>> fetchStimuliCountsForPeriod(
    DateTime from,
    DateTime to,
  ) async {
    final raw = await AthleteStatsService.fetchStimuliCountsForPeriod(
      from: from,
      to: to,
    );
    return raw.entries.map((e) => StimulusCount(e.key, e.value)).toList();
  }

  /// Insights — placeholder para Fase B (IA).
  /// Por enquanto retorna lista vazia; quando a IA estiver pronta,
  /// basta ler de users/{uid}/weekly_insights/current.
  Future<List<InsightModel>> fetchInsights() async {
    return [];
  }
}

// Extensão para facilitar copyWith em DateTime
extension _DateTimeCopyWith on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? microsecond,
  }) => DateTime(
    year ?? this.year,
    month ?? this.month,
    day ?? this.day,
    hour ?? this.hour,
    minute ?? this.minute,
    second ?? this.second,
    microsecond ?? this.microsecond,
  );
}
