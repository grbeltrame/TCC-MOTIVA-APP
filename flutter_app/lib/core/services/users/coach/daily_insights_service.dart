import 'dart:async';

import 'package:flutter_app/shared/models/coach_cycle_topic_insights.dart';

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

  /// Insights de OVERVIEW dos treinos (todas as categorias) para o período
  /// semanal da data selecionada.
  ///
  /// ⚠️ MOCK: tudo aqui é hardcoded. Quando tiver backend:
  /// - esse método deve chamar o endpoint real
  /// - titles, keys e mensagens virão do payload da API.
  Future<CoachDayOverviewInsights> fetchDayOverviewInsights({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // calcula semana: segunda (1) até domingo (7) contendo [date]
    final startOfWeek = date.subtract(
      Duration(days: date.weekday - DateTime.monday),
    );
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return CoachDayOverviewInsights(
      periodStart: startOfWeek,
      periodEnd: endOfWeek,
      buckets: [
        CoachDayOverviewInsightsBucket(
          key: 'analysis',
          title: 'Análise:',
          messages: [
            'Os treinos desta semana priorizaram estímulos combinando força '
                'e condicionamento, com foco especial em WODs de intensidade '
                'moderada e volume controlado.',
            'Os atletas apresentaram boa aderência nas sessões principais, '
                'com presença estável nas turmas das 18h e 19h.',
          ],
        ),
        CoachDayOverviewInsightsBucket(
          key: 'alerts',
          title: 'Alertas:',
          messages: [
            'Queda de presença nas turmas da manhã nos últimos 3 dias. '
                'Considere revisar a comunicação com esse público.',
            'A percepção de esforço relatada em alguns treinos longos está alta. '
                'Talvez seja interessante ajustar o briefing e reforçar pacing.',
          ],
        ),
        CoachDayOverviewInsightsBucket(
          key: 'highlights',
          title: 'Acertos:',
          messages: [
            'Boa resposta dos alunos aos blocos de técnica antes do WOD, '
                'principalmente nos dias com foco em movimentos olímpicos.',
            'Os treinos com combinações simples de movimentos tiveram mais '
                'participação e melhor execução geral.',
          ],
        ),
        CoachDayOverviewInsightsBucket(
          key: 'suggestions',
          title: 'Sugestões:',
          messages: [
            'Inserir ao menos um dia com foco maior em skill/gymnastic para '
                'equilibrar a semana e dar sensação de progresso técnico.',
            'Testar um WOD com estímulo mais curto em um dos dias de menor '
                'presença para incentivar alunos com menos tempo disponível.',
          ],
        ),
      ],
    );
  }

  /// (B) Detalhe: retorna TODOS os insights de um topic para um ciclo.
  /// TODO(back): substituir por chamada real.
  Future<List<CoachCycleInsightItem>> fetchCycleTopicInsights({
    required String boxId,
    required DateTime month, // normalizado: DateTime(year, month)
    required String categoryKey,
    required String topicKey,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    // MOCK: gera insights em dias espalhados no mês (bem “elegante” visualmente)
    final y = month.year;
    final m = month.month;

    // alguns dias fixos pra ficar estável
    final days = <int>[2, 5, 8, 12, 16, 20, 24, 27];

    // mensagens por categoria só pra diferenciar “sabor”
    List<String> baseMessages() {
      switch (categoryKey) {
        case 'technical_alerts':
          return [
            'Seu volume total subiu rápido — risco de fadiga acumulada.',
            'A consistência está boa, mas o esforço médio ficou alto demais em sequência.',
            'A recuperação não acompanhou o ritmo (sono/hidratação).',
          ];
        case 'positive_points':
          return [
            'Ótimo equilíbrio entre estímulos — excelente consistência.',
            'Sua técnica evoluiu em movimentos-chave ao longo do ciclo.',
            'Você manteve presença em dias “difíceis” — isso aumenta performance.',
          ];
        case 'smart_recommendations':
          return [
            'Separe 1 dia na semana para técnica leve + mobilidade.',
            'Teste um pacing mais conservador nos primeiros 30% do WOD.',
            'Priorize sono nas noites pré-treino intenso.',
          ];
        case 'cycle_comparison':
          return [
            'Comparado ao ciclo anterior, seu volume aumentou com melhor consistência.',
            'Seu desempenho manteve estabilidade mesmo com treinos mais longos.',
            'Você variou mais estímulos neste ciclo — bom para evolução geral.',
          ];
        default:
          return [
            'Insight do ciclo: mantenha a consistência e ajuste detalhes.',
            'Pequenos ajustes agora evitam grandes travas depois.',
          ];
      }
    }

    final msgs = baseMessages();

    // mistura topicKey só pra variar um pouco
    String topicFlavor(String s) {
      if (topicKey.isEmpty) return s;
      return '(${topicKey.toUpperCase()}) $s';
    }

    final out = <CoachCycleInsightItem>[];
    for (var i = 0; i < days.length; i++) {
      final d = DateTime(y, m, days[i]);

      // 1 a 2 mensagens por dia
      out.add(
        CoachCycleInsightItem(
          date: d,
          message: topicFlavor(msgs[i % msgs.length]),
        ),
      );

      if (i % 3 == 0) {
        out.add(
          CoachCycleInsightItem(
            date: d,
            message: topicFlavor(msgs[(i + 1) % msgs.length]),
          ),
        );
      }
    }

    // ordena desc (mais recentes primeiro)
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }
}

/// Bucket de insights de overview do dia/semana.
/// Ex.: key = 'analysis', title = 'Análise:', messages = [ ... ].
class CoachDayOverviewInsightsBucket {
  final String key; // identificador técnico (analysis/alerts/…)
  final String title; // texto mostrado no chip colorido (ex.: 'Análise:')
  final List<String> messages; // textos longos (carrossel)

  CoachDayOverviewInsightsBucket({
    required this.key,
    required this.title,
    required this.messages,
  });
}

/// Payload completo do overview de insights do dia/semana.
class CoachDayOverviewInsights {
  final DateTime periodStart; // início da semana (seg)
  final DateTime periodEnd; // fim da semana (dom)
  final List<CoachDayOverviewInsightsBucket> buckets;

  CoachDayOverviewInsights({
    required this.periodStart,
    required this.periodEnd,
    required this.buckets,
  });
}
