// lib/core/services/insights_service.dart

import 'package:flutter_app/shared/models/inisght_model.dart';

/// Serviço responsável por buscar insights diários.
/// TODO: substituir mocks por chamadas reais ao backend.
class InsightsService {
  /// Tipo usado para insights de desempenho do atleta.
  static const String performanceType = 'athlete_performance';

  /// Retorna o conjunto de tipos de insights que o usuário deixou habilitados.
  Future<Set<String>> fetchEnabledInsightTypes() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // TODO: buscar preferência real do usuário
    return {'training_performance', 'sleep_insight', performanceType};
  }

  /// Mostrar/esconder a section de insights de desempenho.
  /// TODO BACKEND: preferência específica do usuário para esta section
  Future<bool> fetchShowPerformanceInsightsSection() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true; // mock: ligado
  }

  /// Busca todos os insights gerados para o dia corrente.
  Future<List<InsightsModel>> fetchDailyInsights(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: chamar API de IA[p] que gera insights para a data fornecida
    return [
      InsightsModel(
        type: 'training_performance',
        message:
            'Você fez um treino com ênfase similar há 2 semanas.\n'
            'Carga média: 75 kg\n'
            'Tente bater esse número hoje!',
      ),
      InsightsModel(
        type: 'sleep_insight',
        message:
            'Seu sono médio caiu 1h nos últimos 3 dias.\n'
            'Considere dormir 30 min a mais hoje.',
      ),
      InsightsModel(
        type: performanceType,
        message:
            'Você se sente mais constante quando treina de manhã.'
            'Já reparou?',
      ),
    ];
  }

  /// Apenas insights de desempenho para a data.
  /// TODO BACKEND: aceitar filtro ?type=athlete_performance no endpoint.
  Future<List<InsightsModel>> fetchDailyPerformanceInsights(
    DateTime date,
  ) async {
    final all = await fetchDailyInsights(date);
    return all.where((i) => i.type == performanceType).toList();
  }

  /// insights específicos para o contexto de ADAPTAÇÕES.
  /// Reaproveita este service, mantendo a tipagem única de InsightsModel.
  /// TODO(back): endpoint que aceite filtros de contexto (categoria/wod/movimentos).
  Future<List<InsightsModel>> fetchAdaptationInsights({
    required String category, // "WOD", "LPO", "Ginastica", "Endurance"
    String? wodName, // se vier de um WOD específico
    DateTime? date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // mocks contextualizados
    final base = <InsightsModel>[
      InsightsModel(
        type: 'adaptation_tip',
        message:
            'Com essa adaptação você fica entre os 3% melhores resultados do seu tipo de perfil!',
      ),
      InsightsModel(
        type: 'fatigue',
        message:
            'Reduzir complexidade mantém a cadência e reduz a fadiga acumulada.',
      ),
    ];

    if (category == 'LPO') {
      base.add(
        InsightsModel(
          type: 'load_prog',
          message:
              'Ajuste cargas em passos de 2.5 kg para preservar a técnica.',
        ),
      );
    }

    if (category == 'WOD' && (wodName ?? '').isNotEmpty) {
      base.add(
        InsightsModel(
          type: 'wod_specific',
          message: 'Para $wodName, quebre as reps em blocos consistentes.',
        ),
      );
    }

    return base;
  }
}
