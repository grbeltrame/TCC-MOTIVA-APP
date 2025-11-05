import 'dart:async';
import 'dart:math';
import 'package:flutter_app/core/services/users/coach/daily_insights_service.dart';
import 'package:flutter_app/shared/models/coach_cycle_insights.dart';
import 'package:flutter_app/shared/models/hourly_metric_pont.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_cycle_insights_section.dart';

/// Métricas do RESUMO DO DIA por categoria (WOD/LPO/Ginastica/Endurance)
/// TODO(back): substituir mocks por chamadas reais ao backend.
class DailyTrainingAnalyticsService {
  /// Frequência por horário (qtd de alunos presentes) daquele tipo no dia.
  static Future<List<HourlyMetricPoint>> fetchHourlyFrequency({
    required String boxId,
    required DateTime date,
    required String category, // "WOD" | "LPO" | "Ginastica" | "Endurance"
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final rnd = Random(date.day + category.hashCode);
    final hours = const ['06h', '07h', '08h', '12h', '18h', '19h', '20h'];
    return [for (final h in hours) HourlyMetricPoint(h, 5 + rnd.nextInt(20))];
  }

  /// Registros por horário (ex.: resultados lançados no app) no dia.
  static Future<List<HourlyMetricPoint>> fetchHourlyRegistrations({
    required String boxId,
    required DateTime date,
    required String category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final rnd = Random(date.month + category.hashCode);
    final hours = const ['06h', '07h', '08h', '12h', '18h', '19h', '20h'];
    return [for (final h in hours) HourlyMetricPoint(h, rnd.nextInt(15))];
  }

  /// Esforço médio do dia para a categoria (0..10) somando todas as turmas.
  static Future<double> fetchAverageEffortScore({
    required String boxId,
    required DateTime date,
    required String category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 180));
    final seed = date.day + date.month + category.hashCode;
    final rnd = Random(seed);
    return 4 + rnd.nextDouble() * 6; // 4.0 .. 10.0
  }
}
// ================== INSIGHTS DE CICLO (MENSAL) ==================

extension CycleInsights on CoachDailyInsightsService {
  /// Busca insights de um ciclo mensal de treinos (todos os tipos).
  /// TODO(back): substituir mocks por chamada real ao backend.
  Future<CoachCycleOverviewInsights> fetchCycleOverviewInsights({
    required String boxId,
    required DateTime month,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // Normaliza para o primeiro dia do mês
    final normalized = DateTime(month.year, month.month);

    // --------- MOCKS inspirados na imagem ---------
    final categories = <CoachCycleCategoryInsights>[
      CoachCycleCategoryInsights(
        key: 'technical_alerts',
        title: 'Alertas Técnicos:',
        topics: [
          CoachCycleTopicInsights(
            key: 'stimulus_repeated',
            title: 'ESTÍMULO REPETIDO:',
            messages: [
              'Nos últimos treinos, o mesmo estímulo de alta intensidade foi repetido em dias consecutivos, '
                  'o que pode aumentar risco de fadiga acumulada e reduzir a qualidade das sessões seguintes.',
              'Considere alternar estímulos neuromusculares com sessões de volume moderado para manter a aderência e segurança.',
            ],
          ),
          CoachCycleTopicInsights(
            key: 'uneven_distribution',
            title: 'DISTRIBUIÇÃO DESIGUAL:',
            messages: [
              'O volume de membros superiores está significativamente abaixo do de membros inferiores neste ciclo.',
              'Atletas que buscam equilíbrio estético ou performance em ginástica podem sentir falta de estímulos específicos.',
            ],
          ),
        ],
      ),
      CoachCycleCategoryInsights(
        key: 'positive_points',
        title: 'Pontos Positivos:',
        topics: [
          CoachCycleTopicInsights(
            key: 'balance',
            title: 'EQUILÍBRIO:',
            messages: [
              'Boa alternância entre dias de força, condicionamento e habilidades. '
                  'A carga semanal está bem distribuída para a maioria dos atletas.',
            ],
          ),
          CoachCycleTopicInsights(
            key: 'progression',
            title: 'PROGRESSÃO:',
            messages: [
              'A progressão de carga e complexidade ao longo das semanas está consistente, '
                  'o que favorece evolução gradual e reduz o risco de lesões.',
            ],
          ),
        ],
      ),
      CoachCycleCategoryInsights(
        key: 'smart_recommendations',
        title: 'Recomendações Inteligentes:',
        topics: [
          CoachCycleTopicInsights(
            key: 'neglected_stimulus',
            title: 'ESTÍMULO NEGLIGENCIADO:',
            messages: [
              'Poucos estímulos de corrida e monoestruturais longos neste ciclo. '
                  'Incluir blocos de 15–20 minutos de cardio contínuo pode elevar condicionamento geral.',
            ],
          ),
          CoachCycleTopicInsights(
            key: 'volume_tuning',
            title: 'AJUSTE DE VOLUME E ESFORÇO:',
            messages: [
              'Alguns dias somam volume alto de força + metcon intenso. '
                  'Rever estas combinações pode melhorar a recuperação dos atletas recreativos.',
              'Teste semanas com “deload” parcial a cada 4–5 semanas para reduzir fadiga acumulada.',
            ],
          ),
          CoachCycleTopicInsights(
            key: 'substitutions',
            title: 'SUBSTITUIÇÕES:',
            messages: [
              'Sugira variações acessíveis (ex.: ring row no lugar de pull-up) já no briefing do ciclo. '
                  'Isso aumenta a sensação de pertencimento de alunos iniciantes.',
            ],
          ),
          CoachCycleTopicInsights(
            key: 'pr_progress',
            title: 'PR E PROGRESSOS:',
            messages: [
              'O volume de tentativas de PR está adequado, mas faltam orientações claras de quando testar cargas máximas.',
            ],
          ),
          CoachCycleTopicInsights(
            key: 'estimated_adherence',
            title: 'ADERÊNCIA ESTIMADA:',
            messages: [
              'Pelos padrões de presença, a aderência tende a cair nas semanas com mais WODs muito longos. '
                  'Considere alternar com sessões mais objetivas (10–15 minutos).',
            ],
          ),
        ],
      ),
      CoachCycleCategoryInsights(
        key: 'cycle_comparison',
        title: 'Comparação com outros ciclos:',
        topics: [
          CoachCycleTopicInsights(
            key: 'progression_compare',
            title: 'PROGRESSÃO:',
            messages: [
              'Em relação ao ciclo anterior, houve aumento leve de volume total, '
                  'mas com melhor distribuição de estímulos de força.',
            ],
          ),
          CoachCycleTopicInsights(
            key: 'distribution_compare',
            title: 'DISTRIBUIÇÃO:',
            messages: [
              'A variabilidade de movimentos melhorou, porém ainda há predominância de padrões de empurrar em detrimento de puxar.',
            ],
          ),
          CoachCycleTopicInsights(
            key: 'variation_compare',
            title: 'VARIAÇÃO:',
            messages: [
              'Mais variação de estímulos monoestruturais em relação ao ciclo passado, '
                  'o que melhora o condicionamento geral da turma.',
            ],
          ),
          CoachCycleTopicInsights(
            key: 'volume_effort_compare',
            title: 'VOLUME E ESFORÇO:',
            messages: [
              'O esforço percebido médio permaneceu estável, mesmo com leve aumento de volume — bom sinal de adaptação dos atletas.',
            ],
          ),
        ],
      ),
    ];

    return CoachCycleOverviewInsights(
      month: normalized,
      categories: categories,
    );
  }
}
