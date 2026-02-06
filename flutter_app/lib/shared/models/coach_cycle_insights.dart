import 'package:cloud_firestore/cloud_firestore.dart';

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
    if (data['technical_alerts'] != null && data['technical_alerts'] is Map) {
      final Map<String, dynamic> alerts = data['technical_alerts'];
      final List<CoachCycleTopicInsights> topics = [];
      alerts.forEach((key, value) {
        if (value is Map && value['description'] != null) {
          topics.add(CoachCycleTopicInsights(
            key: key,
            title: _formatKeyToTitle(key),
            messages: [value['description'].toString()],
          ));
        }
      });
      if (topics.isNotEmpty) {
        parsedCategories.add(CoachCycleCategoryInsights(
          key: 'technical_alerts',
          title: 'Alertas Técnicos',
          topics: topics,
        ));
      }
    }

    // 2. Positive Points
    if (data['positives'] != null && data['positives'] is List) {
      final List<dynamic> positives = data['positives'];
      if (positives.isNotEmpty) {
        parsedCategories.add(CoachCycleCategoryInsights(
          key: 'positive_points',
          title: 'Pontos Positivos',
          topics: [
            CoachCycleTopicInsights(
              key: 'positives_list',
              title: 'Destaques do Mês',
              messages: positives.map((e) => e.toString()).toList(),
            ),
          ],
        ));
      }
    }

    // 3. Comparison
    if (data['comparison'] != null && data['comparison'] is Map) {
      final Map<String, dynamic> comp = data['comparison'];
      final List<CoachCycleTopicInsights> topics = [];
      final labels = {
        'distribution': 'Distribuição',
        'effort': 'Esforço Percebido',
        'progression': 'Progressão',
        'variation': 'Variação',
      };
      labels.forEach((key, title) {
        if (comp[key] != null) {
          topics.add(CoachCycleTopicInsights(
            key: key,
            title: title,
            messages: [comp[key].toString()],
          ));
        }
      });
      if (topics.isNotEmpty) {
        parsedCategories.add(CoachCycleCategoryInsights(
          key: 'cycle_comparison',
          title: 'Análise do Ciclo',
          topics: topics,
        ));
      }
    }

    // 4. Recommendations
    if (data['recommendations'] != null && data['recommendations'] is Map) {
      final Map<String, dynamic> recs = data['recommendations'];
      final List<CoachCycleTopicInsights> topics = [];
      recs.forEach((key, value) {
        if (value is Map && value['description'] != null) {
          topics.add(CoachCycleTopicInsights(
            key: key,
            title: _formatKeyToTitle(key),
            messages: [value['description'].toString()],
          ));
        }
      });
      if (topics.isNotEmpty) {
        parsedCategories.add(CoachCycleCategoryInsights(
          key: 'smart_recommendations',
          title: 'Recomendações Inteligentes',
          topics: topics,
        ));
      }
    }

    return CoachCycleOverviewInsights(
      overview: data['overview']?.toString() ?? '',
      categories: parsedCategories,
    );
  }

  static String _formatKeyToTitle(String key) {
    if (key.isEmpty) return key;
    final spaced = key.replaceAll('_', ' ');
    return spaced[0].toUpperCase() + spaced.substring(1);
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

  CoachCycleInsightItem({
    required this.date,
    required this.message,
  });
}