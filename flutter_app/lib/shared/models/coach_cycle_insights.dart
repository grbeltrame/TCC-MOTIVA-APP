// lib/shared/models/coach_cycle_insights.dart

/// Tópico dentro de uma categoria do ciclo.
/// Ex.: título: "ESTÍMULO REPETIDO", messages: [ 'texto 1', 'texto 2' ]
class CoachCycleTopicInsights {
  final String key;
  final String title;
  final List<String> messages;

  CoachCycleTopicInsights({
    required this.key,
    required this.title,
    required this.messages,
  });
}

/// Categoria de insights do ciclo.
/// Ex.: "Alertas Técnicos", contendo vários tópicos.
class CoachCycleCategoryInsights {
  final String key;
  final String title;
  final List<CoachCycleTopicInsights> topics;

  CoachCycleCategoryInsights({
    required this.key,
    required this.title,
    required this.topics,
  });
}

/// Pacote completo de insights de um CICLO (mês).
/// [month] representa o mês (considera só ano/mês, dia = 1).
class CoachCycleOverviewInsights {
  final DateTime month;
  final List<CoachCycleCategoryInsights> categories;

  CoachCycleOverviewInsights({required this.month, required this.categories});
}
