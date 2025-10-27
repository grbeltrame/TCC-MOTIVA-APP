import 'dart:async';

/// Modelo simples para os insights do coach.
/// Mantém `type` (ex.: 'WOD', 'LPO', 'Ginastica', 'Endurance') e `message` (texto do insight).
class CoachInsightModel {
  final String type; // categoria do treino
  final String message; // insight exibido no card
  CoachInsightModel({required this.type, required this.message});
}

class CoachDailyInsightsService {
  /// Tipos/categorias que o coach habilitou para ver como insights (por Box).
  /// TODO(back): integrar com backend (preferências do coach)
  Future<Set<String>> fetchEnabledCoachInsightTypes(String boxId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return {'WOD', 'LPO', 'Ginastica', 'Endurance'};
  }

  /// CATEGORIAS que têm treino no dia (para filtrar os insights do dia).
  /// TODO(back): integrar com backend (ou reutilizar TrainingService)
  Future<Set<String>> fetchExistingCategoriesForDay({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // MOCK: exemplo — hoje teria WOD e Ginastica
    return {'WOD', 'Ginastica'};
  }

  /// Insights do COACH agregados do DIA (independente do treino específico).
  /// Mantido por compatibilidade com sections antigas.
  /// TODO(back): integrar com endpoint real de analytics do dia por categoria.
  Future<List<CoachInsightModel>> fetchCoachInsightsForDay({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // MOCK: vários insights, um por categoria (ou mais).
    return <CoachInsightModel>[
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
  }

  // ============================================================
  // NOVO: insights ESPECÍFICOS DE UM TREINO
  // ============================================================

  /// Insights ESPECÍFICOS de um treino, filtrados por:
  /// - [boxId] (para escopo do box)
  /// - [trainingId] (o treino/bloco selecionado)
  /// - [date] (data do treino)
  /// - [category] ('WOD' | 'LPO' | 'Ginastica' | 'Endurance')
  ///
  /// Use este método quando precisar mostrar insights apenas do treino
  /// atualmente selecionado (ex.: ao trocar TypePicker e Data).
  ///
  /// TODO(back): GET /coach/{boxId}/trainings/{trainingId}/insights?date=YYYY-MM-DD&category=...
  Future<List<CoachInsightModel>> fetchCoachInsightsForTraining({
    required String boxId,
    required String trainingId,
    required DateTime date,
    required String category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 220));

    // ---------- MOCK determinístico por treino ----------
    // A ideia é que, enquanto não há backend, a mesma combinação
    // (boxId + trainingId + date + category) retorne mensagens consistentes.
    final key =
        '$boxId|$trainingId|${date.toIso8601String().substring(0, 10)}|$category';
    final h = key.hashCode.abs();

    // Pools de mensagens por categoria
    const poolWod = [
      'Gerencie as quebras cedo para evitar colapso no final.',
      'Padrão de respiração 3–3 pode ajudar a manter o pacing.',
      'Capriche no set-up técnico a cada repetição — consistência > velocidade.',
      'Defina um alvo de divisão por round e revise após o 1º bloco.',
    ];
    const poolLpo = [
      'Foque no timing do segundo pull e extensão completa.',
      'Use cargas moderadas para refinar trajetória da barra.',
      'Recepção ativa: cotovelos rápidos e base estável.',
      'Controle a velocidade na descida para manter padrão técnico.',
    ];
    const poolGin = [
      'Priorize controle excêntrico; evite “bater” na amplitude final.',
      'Qualidade antes de volume: séries curtas e perfeitas.',
      'Ative escápulas e mantenha linha neutra do corpo.',
      'Quebre em microblocos para preservar forma.',
    ];
    const poolEnd = [
      'Cadência constante > sprints esporádicos.',
      'Respiração nasal no início para estabilizar a FC.',
      'Divida por blocos mentais de tempo para manter o foco.',
      'Ajuste o pace para terminar forte, não quebrado.',
    ];

    List<String> pool;
    switch (category) {
      case 'WOD':
        pool = poolWod;
        break;
      case 'LPO':
        pool = poolLpo;
        break;
      case 'Ginastica':
        pool = poolGin;
        break;
      case 'Endurance':
        pool = poolEnd;
        break;
      default:
        pool = const [
          'Mantenha a técnica apurada e o pacing inteligente.',
          'Alinhe expectativa do esforço antes de iniciar.',
        ];
    }

    // Gera 2 ou 3 insights, baseado no hash
    final count = 2 + (h % 2); // 2 ou 3
    final out = <CoachInsightModel>[];
    for (var i = 0; i < count; i++) {
      final msg = pool[(h + i) % pool.length];
      out.add(CoachInsightModel(type: category, message: msg));
    }

    return out;
  }
}
