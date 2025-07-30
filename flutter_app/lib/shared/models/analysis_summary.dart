import 'package:flutter_app/core/services/analysis_service.dart';
import 'dart:math';

/// Para o heatmap de frequência.
class HeatMapModel {
  final String day; // ex. 'D', 'S', ...
  final String week; // ex. 'Semana 1', 'Semana 2', ...
  final double value; // número de treinos naquele dia
  HeatMapModel({required this.day, required this.week, required this.value});
}

/// Um único ponto genérico do gráfico de linha/área/radar.
class ChartData {
  final DateTime x;
  final double y;
  ChartData({required this.x, required this.y});
}

/// Summary dos dados para um tipo de análise.
/// Agora com um campo opcional de heatmapData.
class AnalysisSummary {
  final AnalysisType type;
  final List<ChartData>? data; // para line / area / radar
  final List<HeatMapModel>? heatMapData; // para frequency
  final String highlight;
  final int intervalDays;

  AnalysisSummary({
    required this.type,
    this.data,
    this.heatMapData,
    required this.highlight,
    required this.intervalDays,
  });

  /// Máximo valor de Y do conjunto de dados, com 10% de folga.
  double get yMax {
    if (data == null || data!.isEmpty) return 100.0;
    final maxY = data!.map((d) => d.y).reduce(max);
    return maxY * 1.1;
  }
}
