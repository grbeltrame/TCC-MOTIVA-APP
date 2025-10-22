import 'dart:async';

/// Modelo simples para os insights do coach.
/// Mantém `type` (ex.: 'WOD', 'LPO', 'Ginastica', 'Endurance') e `message` (texto do insight).
class CoachInsightModel {
  final String type; // categoria do treino
  final String message; // insight exibido no card
  CoachInsightModel({required this.type, required this.message});
}

class CoachDailyInsightsService {
  /// Retorna os tipos/categorias que o coach habilitou para ver como insights.
  /// TODO: integrar com backend (preferências do coach)
  Future<Set<String>> fetchEnabledCoachInsightTypes(String boxId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'WOD', 'LPO', 'Ginastica', 'Endurance'};
  }

  /// Retorna as CATEGORIAS que têm treino no dia (para filtrar os insights).
  /// TODO: integrar com backend (ou reutilizar TrainingService do app)
  Future<Set<String>> fetchExistingCategoriesForDay({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // MOCK: imagine que hoje só tem WOD e Ginastica
    return {'WOD', 'Ginastica'};
  }

  /// Retorna os insights do COACH para o dia (somente do treino/turmas).
  /// Esses insights são diferentes daqueles do aluno.
  /// TODO: integrar com endpoint real de analytics do dia por categoria.
  Future<List<CoachInsightModel>> fetchCoachInsightsForDay({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // MOCK: vários insights, um por categoria (ou mais).
    final all = <CoachInsightModel>[
      CoachInsightModel(
        type: 'WOD',
        message:
            'Turmas 18h e 19h lotadas. Considere abrir uma turma extra às 20h.',
      ),
      CoachInsightModel(
        type: 'WOD',
        message:
            'Tempo médio de conclusão +10% vs. ontem. Ajuste briefing para reforçar pacing.',
      ),
      CoachInsightModel(
        type: 'LPO',
        message:
            'Baixa adesão em LPO hoje. Só 2 registros previstos — talvez reagendar.',
      ),
      CoachInsightModel(
        type: 'Ginastica',
        message:
            'Média de esforço 7.8/10 em Ginástica. Progresso sólido nas barras.',
      ),
      CoachInsightModel(
        type: 'Endurance',
        message:
            'Endurance: pico de presença às 07h. Manter aquecimento mais curto para caber no horário.',
      ),
    ];

    return all;
  }
}
