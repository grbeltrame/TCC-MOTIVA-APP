// lib/core/services/insights_service.dart

import 'package:flutter_app/shared/models/inisght_model.dart';

/// Serviço responsável por buscar insights diários.
/// TODO: substituir mocks por chamadas reais ao backend.
class InsightsService {
  /// Retorna o conjunto de tipos de insights que o usuário deixou habilitados.
  Future<Set<String>> fetchEnabledInsightTypes() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // TODO: buscar preferência real do usuário
    return {'training_performance', 'sleep_insight'};
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
    ];
  }
}
