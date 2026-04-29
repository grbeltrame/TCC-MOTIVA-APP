class TrainingAnalysis {
  final Map<String, String>
  alerts; // ex: {'risco_ombro': 'Cuidado com volume...'}
  final Map<String, String>
  insights; // ex: {'dica_mobilidade': 'Faça alongamento...'}
  final String overview; // Resumo geral do treino
  final List<String> keyMetrics; // ex: ['Força', 'Cardio']

  TrainingAnalysis({
    required this.alerts,
    required this.insights,
    required this.overview,
    required this.keyMetrics,
  });

  /// Factory seguro para converter o JSON, mesmo que venham campos nulos
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

    // 3. Processar Summary e Métricas
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

/// Representa um treino individual.
class Training {
  final String id;
  final String title;
  final String? description;
  final DateTime date;
  final String status;

  // Guarda a estrutura crua das partes (WOD, Skill, LPO, etc)
  final Map<String, dynamic> partes;

  // NOVO CAMPO: Guarda a análise da IA (opcional, pois nem todo treino tem)
  final TrainingAnalysis? analysis;

  Training({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.status = 'publicado',
    this.partes = const {},
    this.analysis, // Adicionado como opcional
  });
}

/// Resumo de um treino para o card “resumo do dia”.
class DailyWorkoutSummary {
  final String category;
  final List<String> stimuli;
  final String objectiveShort;
  final String quote;

  DailyWorkoutSummary({
    required this.category,
    required this.stimuli,
    required this.objectiveShort,
    required this.quote,
  });
}
