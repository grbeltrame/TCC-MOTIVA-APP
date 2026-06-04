import 'package:flutter_app/shared/widgets/carousels/highlights_carousel.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart';
import 'package:flutter_app/shared/widgets/carousels/recomendations_carousel.dart';

/// Serviço responsável por buscar os destaques e tipos habilitados.
/// TODO: substituir mocks por chamadas reais ao backend.
class HighlightsService {
  /// Retorna a lista completa de destaqyes.
  Future<List<HighlightModel>> fetchHighlights() async {
    await Future.delayed(const Duration(milliseconds: 200)); // simula latência
    return [
      HighlightModel(
        type: 'training_streak',
        message:
            'Você treinou 6 dias seguidos com esforço acima de 8.5 — considere um descanso.',
      ),
      HighlightModel(
        type: 'sleep_debt',
        message:
            'Você está com déficit de sono. Tente dormir 30 min a mais esta noite.',
      ),
      HighlightModel(
        type: 'hydration',
        message:
            'Seu consumo de água está abaixo do ideal. Beba pelo menos 500ml agora.',
      ),
    ];
  }

  /// Retorna o conjunto de tipos de destaques que o usuário deixou habilitados.
  Future<Set<String>> fetchEnabledHighlightsTypes() async {
    await Future.delayed(const Duration(milliseconds: 100)); // simula latência
    return {'training_streak', 'hydration'};
  }

  /// NOVO: filtra apenas os destaques habilitados **e** da semana dada
  Future<List<HighlightModel>> fetchWeeklyHighlights(WeekRange week) async {
    final all = await fetchHighlights();
    final enabled = await fetchEnabledHighlightsTypes();
    // Aqui você poderia também filtrar por data usando week.start/end,
    // mas no mock atual só filtramos por tipo:
    return all.where((h) => enabled.contains(h.type)).toList();
  }

  /// NOVO: destaques estatísticos semanais no formato recomendation
  /// TODO: conectar ao backend real quando disponível.
  Future<List<RecomendationModel>> fetchWeeklyStatsRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      RecomendationModel(
        type: 'carga_variacao',
        message: '+15 % de carga em relação à semana passada',
      ),
      RecomendationModel(
        type: 'frequencia_variacao',
        message: '+10 % de treinos em relação à semana passada',
      ),
      RecomendationModel(
        type: 'esforco_variacao',
        message: 'Esforço médio subiu 0.3 ponto',
      ),
      // adicione quantos quiser
    ];
  }

  /// Tipos de destaques semanais habilitados pelo usuário.
  /// TODO: integrar com backend de preferências reais.
  Future<Set<String>> fetchEnabledWeeklyStatsTypes() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // hard‑coded: suponha que o usuário queira só carga e esforço
    return {'carga_variacao', 'esforco_variacao'};
  }
}
