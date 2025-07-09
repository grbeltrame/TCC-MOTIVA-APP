import 'package:flutter_app/shared/widgets/recomendations_carousel.dart';

/// Serviço responsável por buscar os destaques e tipos habilitados.
/// TODO: substituir mocks por chamadas reais ao backend.
class RecomendationsService {
  /// Retorna a lista completa de destaqyes.
  Future<List<RecomendationModel>> fetchRecomendations() async {
    await Future.delayed(const Duration(milliseconds: 200)); // simula latência
    return [
      RecomendationModel(
        type: 'training_streak',
        message:
            'Você treinou 6 dias seguidos com esforço acima de 8.5 — considere um descanso.',
      ),
      RecomendationModel(
        type: 'sleep_debt',
        message:
            'Você está com déficit de sono. Tente dormir 30 min a mais esta noite.',
      ),
      RecomendationModel(
        type: 'hydration',
        message:
            'Seu consumo de água está abaixo do ideal. Beba pelo menos 500ml agora.',
      ),
    ];
  }

  /// Retorna o conjunto de tipos de destaques que o usuário deixou habilitados.
  Future<Set<String>> fetchEnabledRecomendationsTypes() async {
    await Future.delayed(const Duration(milliseconds: 100)); // simula latência
    return {'training_streak', 'hydration'};
  }
}
