class TrainingAnalysis {
  final Map<String, String> alerts; // Chave -> Mensagem
  final Map<String, String> insights; // Chave -> Detalhe
  final String overview;
  final List<String> keyMetrics;

  TrainingAnalysis({
    required this.alerts,
    required this.insights,
    required this.overview,
    required this.keyMetrics,
  });

  factory TrainingAnalysis.fromJson(Map<String, dynamic> json) {
    // 1. Processar Alertas
    final alertsMap = <String, String>{};
    if (json['alerts'] != null && json['alerts'] is Map) {
      (json['alerts'] as Map).forEach((key, value) {
        if (value is Map && value['message'] != null) {
          alertsMap[key] = value['message'].toString();
        }
      });
    }

    // 2. Processar Insights
    final insightsMap = <String, String>{};
    if (json['insights'] != null && json['insights'] is Map) {
      (json['insights'] as Map).forEach((key, value) {
        if (value is Map && value['detail'] != null) {
          insightsMap[key] = value['detail'].toString();
        }
      });
    }

    // 3. Processar Summary
    String overviewText = "";
    List<String> metricsList = [];

    if (json['summary'] != null && json['summary'] is Map) {
      final sum = json['summary'];
      overviewText = sum['overview'] ?? "";
      if (sum['key_metrics'] != null) {
        metricsList = List<String>.from(sum['key_metrics']);
      }
    }

    return TrainingAnalysis(
      alerts: alertsMap,
      insights: insightsMap,
      overview: overviewText,
      keyMetrics: metricsList,
    );
  }
}
