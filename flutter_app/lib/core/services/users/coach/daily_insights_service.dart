import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:intl/intl.dart';
import 'package:flutter_app/shared/models/coach_cycle_insights.dart';

// ============================================================
// MODELOS AUXILIARES (Caso não estejam em arquivo separado)
// ============================================================

class CoachInsightModel {
  final String type;
  final String message;
  CoachInsightModel({required this.type, required this.message});
}

class CoachDayOverviewInsightsBucket {
  final String key;
  final String title;
  final List<String> messages;
  CoachDayOverviewInsightsBucket({
    required this.key,
    required this.title,
    required this.messages,
  });
}

class CoachDayOverviewInsights {
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<CoachDayOverviewInsightsBucket> buckets;
  CoachDayOverviewInsights({
    required this.periodStart,
    required this.periodEnd,
    required this.buckets,
  });
}

// ============================================================
// SERVICE PRINCIPAL
// ============================================================

class CoachDailyInsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // 1. INSIGHTS DO CICLO (CORRIGIDO: Busca na Raiz)
  // ---------------------------------------------------------------------------

  /// Busca o overview completo do ciclo na coleção 'cycles' pelo ID 'MM-yyyy'.
  Future<CoachCycleOverviewInsights> fetchCycleOverviewInsights({
    required String
    boxId, // Mantido para compatibilidade, mas ignorado na busca
    required DateTime month,
  }) async {
    try {
      // Formata ID como "02-2026"
      final docId = DateFormat('MM-yyyy').format(month);

      // Busca direta na coleção raiz (evita erro de permissão)
      final docRef = _firestore.collection('cycles').doc(docId);
      final snapshot = await docRef.get();

      if (!snapshot.exists || snapshot.data() == null) {
        // Mês sem dados
        return CoachCycleOverviewInsights(overview: '', categories: []);
      }

      return CoachCycleOverviewInsights.fromFirestore(snapshot.data()!);
    } catch (e) {
      debugPrint('Erro fetchCycleOverviewInsights: $e');
      return CoachCycleOverviewInsights(overview: '', categories: []);
    }
  }

  /// Busca detalhes de um tópico específico (também na coleção raiz).
  Future<List<CoachCycleInsightItem>> fetchCycleTopicInsights({
    required String boxId,
    required DateTime month,
    required String categoryKey,
    required String topicKey,
  }) async {
    try {
      final docId = DateFormat('MM-yyyy').format(month);
      final docRef = _firestore.collection('cycles').doc(docId);
      final snapshot = await docRef.get();

      if (!snapshot.exists || snapshot.data() == null) {
        return [];
      }

      final data = snapshot.data()!;
      final List<CoachCycleInsightItem> items = [];

      // Data de referência (dia 1 do mês) para exibição
      final refDate = DateTime(month.year, month.month, 1);

      if (categoryKey == 'technical_alerts') {
        final messages = buildCoachCycleTechnicalAlertMessages(data);
        for (final message in messages) {
          items.add(CoachCycleInsightItem(date: refDate, message: message));
        }
      } else if (categoryKey == 'positive_points') {
        final list = data['positives'] as List<dynamic>?;
        if (list != null) {
          for (var msg in list) {
            items.add(
              CoachCycleInsightItem(date: refDate, message: msg.toString()),
            );
          }
        }
      } else if (categoryKey == 'cycle_comparison') {
        final messages = buildCoachCycleComparisonMessages(data);
        for (final message in messages) {
          items.add(CoachCycleInsightItem(date: refDate, message: message));
        }
      } else if (categoryKey == 'smart_recommendations') {
        final messages = buildCoachCycleRecommendationMessages(data);
        for (final message in messages) {
          items.add(CoachCycleInsightItem(date: refDate, message: message));
        }
      }

      return items;
    } catch (e) {
      debugPrint('Erro fetchCycleTopicInsights: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // 2. MÉTODOS LEGADOS / DAILY (MOCKS ATUAIS)
  // Mantidos retornando vazio/fixo conforme sua solicitação para focar no ciclo.
  // ---------------------------------------------------------------------------

  Future<Set<String>> fetchEnabledCoachInsightTypes(String boxId) async {
    // Retorna tipos padrão para exibir a UI do carrossel (mesmo que vazio)
    return {'WOD', 'LPO', 'Ginastica', 'Endurance'};
  }

  Future<Set<String>> fetchExistingCategoriesForDay({
    required String boxId,
    required DateTime date,
  }) async {
    // Mock: finge que tem WOD e Ginástica para habilitar a busca
    return {'WOD', 'Ginastica'};
  }

  Future<List<CoachInsightModel>> fetchCoachInsightsForDay({
    required String boxId,
    required DateTime date,
  }) async {
    // Retorna vazio para o Daily aparecer como "Sem insights"
    // (mas mostrando os botões de ação que configuramos)
    return [];
  }

  Future<List<CoachInsightModel>> fetchCoachInsightsForTraining({
    required String boxId,
    required String trainingId,
    required DateTime date,
    required String category,
  }) async {
    return [];
  }

  Future<CoachDayOverviewInsights> fetchDayOverviewInsights({
    required String boxId,
    required DateTime date,
  }) async {
    return CoachDayOverviewInsights(
      periodStart: date,
      periodEnd: date,
      buckets: [],
    );
  }
}
