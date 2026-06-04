const Map<String, String> coachCycleComparisonLabels = {
  'distribution': 'Distribuição',
  'effort': 'Esforço Percebido',
  'progression': 'Progressão',
  'variation': 'Variação',
};

String formatCoachCycleInsightTitle(String key) {
  if (key.isEmpty) return key;
  final spaced = key.replaceAll('_', ' ');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

String formatCoachCycleInsightMessage(String title, String description) {
  return '$title\n$description';
}

List<String> buildCoachCycleTechnicalAlertMessages(Map<String, dynamic> data) {
  final alerts = data['technical_alerts'];
  if (alerts is! Map) return const [];

  final messages = <String>[];
  alerts.forEach((key, value) {
    if (value is Map && value['description'] != null) {
      final title = formatCoachCycleInsightTitle(key.toString());
      final description = value['description'].toString();
      messages.add(formatCoachCycleInsightMessage(title, description));
    }
  });
  return messages;
}

List<String> buildCoachCycleComparisonMessages(Map<String, dynamic> data) {
  final comparison = data['comparison'];
  if (comparison is! Map) return const [];

  final messages = <String>[];
  coachCycleComparisonLabels.forEach((key, title) {
    if (comparison[key] != null) {
      messages.add(
        formatCoachCycleInsightMessage(title, comparison[key].toString()),
      );
    }
  });
  return messages;
}

List<String> buildCoachCycleRecommendationMessages(Map<String, dynamic> data) {
  final recommendations = data['recommendations'];
  if (recommendations is! Map) return const [];

  final messages = <String>[];
  recommendations.forEach((key, value) {
    if (value is Map && value['description'] != null) {
      final title = formatCoachCycleInsightTitle(key.toString());
      final description = value['description'].toString();
      messages.add(formatCoachCycleInsightMessage(title, description));
    }
  });
  return messages;
}

/// Modelo principal que representa a tela inteira de Insights do Ciclo
class CoachCycleOverviewInsights {
  final String overview;
  final List<CoachCycleCategoryInsights> categories;

  CoachCycleOverviewInsights({
    required this.overview,
    required this.categories,
  });

  factory CoachCycleOverviewInsights.fromFirestore(Map<String, dynamic> data) {
    final List<CoachCycleCategoryInsights> parsedCategories = [];

    // 1. Technical Alerts
    final technicalAlerts = buildCoachCycleTechnicalAlertMessages(data);
    if (technicalAlerts.isNotEmpty) {
      parsedCategories.add(
        CoachCycleCategoryInsights(
          key: 'technical_alerts',
          title: 'Alertas Técnicos',
          topics: [
            CoachCycleTopicInsights(
              key: 'technical_alerts_list',
              title: 'Alertas do Mês',
              messages: technicalAlerts,
            ),
          ],
        ),
      );
    }

    // 2. Positive Points
    if (data['positives'] != null && data['positives'] is List) {
      final List<dynamic> positives = data['positives'];
      if (positives.isNotEmpty) {
        parsedCategories.add(
          CoachCycleCategoryInsights(
            key: 'positive_points',
            title: 'Pontos Positivos',
            topics: [
              CoachCycleTopicInsights(
                key: 'positives_list',
                title: 'Destaques do Mês',
                messages: positives.map((e) => e.toString()).toList(),
              ),
            ],
          ),
        );
      }
    }

    // 3. Comparison
    final comparisonMessages = buildCoachCycleComparisonMessages(data);
    if (comparisonMessages.isNotEmpty) {
      parsedCategories.add(
        CoachCycleCategoryInsights(
          key: 'cycle_comparison',
          title: 'Análise do Ciclo',
          topics: [
            CoachCycleTopicInsights(
              key: 'cycle_comparison_list',
              title: 'Resumo Comparativo',
              messages: comparisonMessages,
            ),
          ],
        ),
      );
    }

    // 4. Recommendations
    final recommendationMessages = buildCoachCycleRecommendationMessages(data);
    if (recommendationMessages.isNotEmpty) {
      parsedCategories.add(
        CoachCycleCategoryInsights(
          key: 'smart_recommendations',
          title: 'Recomendações Inteligentes',
          topics: [
            CoachCycleTopicInsights(
              key: 'smart_recommendations_list',
              title: 'Plano Sugerido',
              messages: recommendationMessages,
            ),
          ],
        ),
      );
    }

    return CoachCycleOverviewInsights(
      overview: data['overview']?.toString() ?? '',
      categories: parsedCategories,
    );
  }
}

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

// ✅ CLASSE NOVA ADICIONADA PARA A TELA DE DETALHES
class CoachCycleInsightItem {
  final DateTime date;
  final String message;

  CoachCycleInsightItem({required this.date, required this.message});
}
