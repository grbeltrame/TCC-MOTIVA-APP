import 'dart:math';
import 'package:flutter_app/shared/models/analysis_summary.dart';

enum AnalysisDisplayMode { simple, complex }

enum AnalysisType { effort, frequency, volume, load }

class AnalysisService {
  static Future<AnalysisDisplayMode> fetchDisplayMode() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return AnalysisDisplayMode.simple;
  }

  static Future<Set<AnalysisType>> fetchEnabledAnalysisTypes() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      AnalysisType.effort,
      AnalysisType.frequency,
      AnalysisType.volume,
      AnalysisType.load,
    };
  }

  /// Gera mocks de dados para cada tipo de análise.
  static Future<List<AnalysisSummary>> fetchSimpleAnalyses({
    int intervalDays = 30,
  }) async {
    final enabled = await fetchEnabledAnalysisTypes();
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final rnd = Random();
    final List<AnalysisSummary> list = [];

    for (var type in enabled) {
      String highlight;
      switch (type) {
        case AnalysisType.effort:
          highlight = 'Seu esforço médio caiu 10% nas últimas 2 semanas.';
          // gera uma série de pontos
          final data = List.generate(intervalDays, (i) {
            return ChartData(
              x: now.subtract(Duration(days: intervalDays - i - 1)),
              y: 2 + rnd.nextDouble() * 8, // entre 2 e 10
            );
          });
          list.add(
            AnalysisSummary(
              type: type,
              data: data,
              heatMapData: null,
              highlight: highlight,
              intervalDays: intervalDays,
            ),
          );
          break;

        case AnalysisType.frequency:
          highlight = 'Você treinou 4x por semana no último mês.';
          // gera um heatmap: semanas no eixo Y, dias da semana no X
          final weeks = (intervalDays / 7).ceil();
          final weekdays = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
          final heat = <HeatMapModel>[];
          for (var w = 0; w < weeks; w++) {
            for (var d = 0; d < 7; d++) {
              heat.add(
                HeatMapModel(
                  week: 'Semana ${w + 1}',
                  day: weekdays[d],
                  value: rnd.nextInt(3).toDouble(), // 0–2 treinos
                ),
              );
            }
          }
          list.add(
            AnalysisSummary(
              type: type,
              data: null,
              heatMapData: heat,
              highlight: highlight,
              intervalDays: intervalDays,
            ),
          );
          break;

        case AnalysisType.volume:
          highlight = 'Volume semanal caiu após pico em abril.';
          // gera área empilhada: 3 séries fictícias
          final data = List.generate(intervalDays, (i) {
            final base = rnd.nextDouble() * 50 + 50;
            return ChartData(
              x: now.subtract(Duration(days: intervalDays - i - 1)),
              y: base,
            );
          });
          list.add(
            AnalysisSummary(
              type: type,
              data: data,
              heatMapData: null,
              highlight: highlight,
              intervalDays: intervalDays,
            ),
          );
          break;

        case AnalysisType.load:
          highlight = 'Carga total 18% acima do último ciclo.';
          // gera radar: valor por “região” (vamos fingir 5 categorias)
          final today = now;
          final data = List.generate(5, (i) {
            return ChartData(
              x: today.add(Duration(days: i)), // só para X usar categorias
              y: rnd.nextDouble() * 100,
            );
          });
          list.add(
            AnalysisSummary(
              type: type,
              data: data,
              heatMapData: null,
              highlight: highlight,
              intervalDays: intervalDays,
            ),
          );
          break;
      }
    }

    return list;
  }

  static Future<List<AnalysisSummary>> fetchComplexAnalyses({
    required int intervalDays,
  }) async {
    return [];
  }
}
