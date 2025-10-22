import 'dart:async';
import 'dart:math';
import 'package:flutter_app/shared/models/hourly_metric_pont.dart';

/// Métricas do RESUMO DO DIA por categoria (WOD/LPO/Ginastica/Endurance)
/// TODO(back): substituir mocks por chamadas reais ao backend.
class DailyTrainingAnalyticsService {
  /// Frequência por horário (qtd de alunos presentes) daquele tipo no dia.
  static Future<List<HourlyMetricPoint>> fetchHourlyFrequency({
    required String boxId,
    required DateTime date,
    required String category, // "WOD" | "LPO" | "Ginastica" | "Endurance"
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final rnd = Random(date.day + category.hashCode);
    final hours = const ['06h', '07h', '08h', '12h', '18h', '19h', '20h'];
    return [for (final h in hours) HourlyMetricPoint(h, 5 + rnd.nextInt(20))];
  }

  /// Registros por horário (ex.: resultados lançados no app) no dia.
  static Future<List<HourlyMetricPoint>> fetchHourlyRegistrations({
    required String boxId,
    required DateTime date,
    required String category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final rnd = Random(date.month + category.hashCode);
    final hours = const ['06h', '07h', '08h', '12h', '18h', '19h', '20h'];
    return [for (final h in hours) HourlyMetricPoint(h, rnd.nextInt(15))];
  }

  /// Esforço médio do dia para a categoria (0..10) somando todas as turmas.
  static Future<double> fetchAverageEffortScore({
    required String boxId,
    required DateTime date,
    required String category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 180));
    final seed = date.day + date.month + category.hashCode;
    final rnd = Random(seed);
    return 4 + rnd.nextDouble() * 6; // 4.0 .. 10.0
  }
}
