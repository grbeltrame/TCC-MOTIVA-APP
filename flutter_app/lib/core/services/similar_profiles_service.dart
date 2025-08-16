import 'dart:async';

/// Ponto simples para gráfico (categoria no eixo X e valor numérico no eixo Y)
class ChartPoint {
  final String x;
  final double y;
  ChartPoint(this.x, this.y);
}

/// Bundle com dados das curvas (até 3 séries) para um gráfico
class ChartSeriesBundle {
  final List<ChartPoint> serieA;
  final List<ChartPoint> serieB;
  final List<ChartPoint> serieC;

  ChartSeriesBundle({
    required this.serieA,
    required this.serieB,
    required this.serieC,
  });
}

/// Serviço mock para predição/curvas de “perfis semelhantes”.
/// TODO(back): trocar por chamadas reais aos endpoints da IA/analytics.
class SimilarProfilesService {
  /// Texto de predição para o item que o usuário está consultando.
  /// Se vier [benchmarkName], assume WOD; caso contrário, usa [movementName].
  Future<String> fetchPredictedResultText({
    String? benchmarkName,
    String? movementName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (benchmarkName != null) {
      // Ex.: “190 segundos (3min e 10s)”
      return '190 segundos (3min e 10s)\nDe acordo com suas performances anteriores';
    }
    // movimento (ex.: load ou reps)
    return '62.5 kg (média esperada)\nDe acordo com suas performances anteriores';
  }

  /// Curvas de “Resultados” (tempo/reps/score) para perfis semelhantes.
  Future<ChartSeriesBundle> fetchSimilarResultsSeries({
    required int lastDays,
    String? benchmarkName,
    String? movementName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // Mock simples por ano (labels curtos para ficar clean)
    final labels = ['2018', '2019', '2020', '2021', '2022', '2023', '2024'];
    final a = <ChartPoint>[
      for (var i = 0; i < labels.length; i++) ChartPoint(labels[i], 20 + i * 8),
    ];
    final b = <ChartPoint>[
      for (var i = 0; i < labels.length; i++) ChartPoint(labels[i], 18 + i * 6),
    ];
    final c = <ChartPoint>[
      for (var i = 0; i < labels.length; i++) ChartPoint(labels[i], 25 + i * 5),
    ];
    return ChartSeriesBundle(serieA: a, serieB: b, serieC: c);
  }

  /// Curvas de “Cargas” para perfis semelhantes.
  Future<ChartSeriesBundle> fetchSimilarLoadsSeries({
    required int lastDays,
    String? benchmarkName,
    String? movementName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final labels = ['2018', '2019', '2020', '2021', '2022', '2023', '2024'];
    final a = <ChartPoint>[
      for (var i = 0; i < labels.length; i++) ChartPoint(labels[i], 40 + i * 5),
    ];
    final b = <ChartPoint>[
      for (var i = 0; i < labels.length; i++) ChartPoint(labels[i], 35 + i * 6),
    ];
    final c = <ChartPoint>[
      for (var i = 0; i < labels.length; i++) ChartPoint(labels[i], 30 + i * 7),
    ];
    return ChartSeriesBundle(serieA: a, serieB: b, serieC: c);
  }
}
