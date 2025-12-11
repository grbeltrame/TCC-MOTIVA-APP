import 'dart:async';
import 'dart:math';
import 'package:flutter_app/shared/models/box.dart';
import 'package:flutter_app/shared/models/class.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';
import 'package:flutter_app/core/services/users/coach/coach_service.dart';
import 'package:intl/intl.dart';

class TrainingService {
  /// Retorna a lista de boxes em que o usuário está cadastrado.
  static Future<List<Box>> fetchUserBoxes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: substituir por chamada real ao backend
    return [
      Box(id: '1', name: 'Olympus Crossfit'),
      Box(id: '2', name: 'Spartan Gym'),
    ];
  }

  /// Retorna um mapa categoria → último bloco de treino do dia
  /// TODO: substituir por chamada real ao backend.
  static Future<Map<String, TrainingBlock?>>
  fetchTrainingBlocksByCategoryForDate({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simula latência
    final dayKey = '${date.year}-${date.month}-${date.day}';

    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final Map<String, TrainingBlock?> result = {};

    // WOD
    result['WOD'] = TrainingBlock(
      id: 'tb-$dayKey-wod-fran', // << estável
      title: 'WOD “Fran”',
      subtitle: '$formattedDate – 21-15-9 Thrusters e Pull-ups',
      items: [
        '21 Thrusters 43kg',
        '21 Pull-ups',
        '15 Thrusters 43kg',
        '15 Pull-ups',
        '9 Thrusters 43kg',
        '9 Pull-ups',
      ],
    );

    // LPO
    result['LPO'] = TrainingBlock(
      id: 'tb-$dayKey-lpo-snatch-tech',
      title: 'Olympic Lifts',
      subtitle: '$formattedDate – Técnica e força',
      items: [
        '5×2 Snatch @ técnica',
        '5×3 Clean & Jerk @ 70%',
        '3×1 Snatch Balance',
      ],
    );

    // Ginástica
    result['Ginastica'] = TrainingBlock(
      id: 'tb-$dayKey-gym-pullups',
      title: 'Ginástica',
      subtitle: '$formattedDate – Habilidades corporais',
      items: [
        '5×5 Pull-ups estritos',
        '4×4 Handstand Push-ups',
        '3×10 Toes-to-Bar',
      ],
    );

    // Endurance
    result['Endurance'] = TrainingBlock(
      id: 'tb-$dayKey-endu-cardio', // << adicionado
      title: 'Endurance',
      subtitle: '$formattedDate – Cardio intenso',
      items: [
        '10 min AMRAP de Double-Unders',
        '5 min Remo',
        '800m Corrida leve',
      ],
    );

    return result;
  }

  /// Busca TODOS os blocos do treino do dia/box/categoria.
  /// Ex.: Warm Up, Extra Training, Skill, RX Work, WOD …
  /// TODO(back): substituir por chamada real ao backend.
  static Future<List<TrainingBlock>> fetchFullTrainingBlocks({
    required String boxId,
    required DateTime date,
    required String category, // 'WOD' | 'LPO' | 'Ginastica' | 'Endurance'
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simula latência
    final dayKey = '${date.year}-${date.month}-${date.day}';
    final catKey = category.toLowerCase();

    if (catKey == 'wod') {
      return [
        TrainingBlock(
          id: 'tb-$dayKey-wod-warmup',
          title: 'Warm Up - 5 min',
          subtitle: '',
          items: const [
            '5 Muscle Snatch',
            '20 Jumping Jacks',
            '10 Air Squat',
            '10 Push Up',
          ],
        ),
        TrainingBlock(
          id: 'tb-$dayKey-wod-extra',
          title: 'Extra Training - 8 min',
          subtitle: '',
          items: const [
            '20 Situp',
            '30 Montain Climb',
            '40 Flutter Kicks',
            '50 The Hundred',
            '40s Plank',
            '30 Heel Touch',
            '20 Russian Twist',
          ],
        ),
        TrainingBlock(
          id: 'tb-$dayKey-wod-skill',
          title: 'Skill Work - 10 min',
          subtitle: '',
          items: const ['Snatch'],
        ),
        TrainingBlock(
          id: 'tb-$dayKey-wod-rx',
          title: 'RX Work - 10 min',
          subtitle: '',
          items: const ['Load to Wod'],
        ),
        // << PRINCIPAL: mesmo ID e mesmo treino do card
        TrainingBlock(
          id: 'tb-$dayKey-wod-fran',
          title: 'WOD - Fran',
          subtitle: 'For Time:',
          items: const ['21-15-9 Thrusters (43/30kg) + Pull-ups'],
        ),
      ];
    }

    // Outros tipos — mocks simples com IDs estáveis
    return [
      TrainingBlock(
        id: 'tb-$dayKey-$catKey-tech',
        title: '$category – Técnica',
        subtitle: '10 min',
        items: const ['Bloco técnico 1', 'Bloco técnico 2'],
      ),
      TrainingBlock(
        id: 'tb-$dayKey-$catKey-strength',
        title: '$category – Força',
        subtitle: '10 min',
        items: const ['Série principal', 'Série complementar'],
      ),
    ];
  }

  /// Registra um novo box para o usuário.
  static Future<Box> registerBox(String boxName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: chamar API de cadastro e retornar o Box criado
    return Box(id: 'novo', name: boxName);
  }

  /// Busca os treinos do dia [date] para o box [boxId].
  static Future<List<Training>> fetchTrainingsForBox({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: buscar treinos reais do backend
    return [
      // Exemplo de mock:
      Training(
        id: 't1',
        title: 'WOD “Fran”',
        description: '21-15-9 Thrusters 43kg e Pull-ups',
        date: date,
      ),
      Training(
        id: 't2',
        title: 'Strength',
        description: 'Back Squat 5x5 @ 75%',
        date: date,
      ),
    ];
  }

  /// TODO: chamar sua API para buscar treino(s) do dia [date]
  static Future<List<dynamic>> fetchWorkoutsForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return []; // substitua por lista de treinos
  }

  /// Retorna um mapa categoria → último treino do dia (ou null se não houver).
  /// Mock: cada dia metade das categorias terá treino, as outras ficarão nulas.
  /// TODO: substituir por chamada real ao backend.
  static Future<Map<String, Training?>> fetchTrainingsByCategoryForDate({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simula latência

    final categories = ['WOD', 'LPO', 'Ginastica', 'Endurance'];
    final rnd = Random(date.day + date.month);
    final Map<String, Training?> result = {};

    for (var cat in categories) {
      if (rnd.nextBool()) {
        result[cat] = Training(
          id: '${cat.toLowerCase()}_${date.toIso8601String()}',
          title: cat,
          description:
              'Último bloco de treino de $cat em ${DateFormat('dd/MM/yyyy').format(date)}',
          date: date,
        );
      } else {
        result[cat] = null;
      }
    }

    return result;
  }

  /// Apaga permanentemente um treino (bloco) do dia/categoria/box.
  /// TODO(back): implementar chamada real ao backend para remoção definitiva.
  static Future<void> deleteTraining({
    required String boxId,
    required DateTime date,
    required String category,
    required String blockId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO(back): DELETE /boxes/{boxId}/trainings?date=...&category=...&blockId=...
    // Remover do banco e invalidar caches. Aqui é apenas mock.
  }
}

extension DailySummaries on TrainingService {
  /// Retorna os resumos de treino do dia por box.
  /// Usa os dados já existentes, mas preenche "stimuli/objective/quote" com mocks.
  /// TODO (backend): substituir por payload real com fields equivalentes.
  static Future<List<DailyWorkoutSummary>> fetchDailyWorkoutSummariesForBox({
    required String boxId,
    required DateTime date,
  }) async {
    // Podemos decidir com base em quais categorias têm bloco hoje:
    final blocks = await TrainingService.fetchTrainingBlocksByCategoryForDate(
      boxId: boxId,
      date: date,
    );

    final List<DailyWorkoutSummary> list = [];

    for (final entry in blocks.entries) {
      final cat = entry.key;
      final hasBlock = entry.value != null;
      if (!hasBlock) continue;

      // MOCKS por categoria — troque por dados reais quando houver
      switch (cat) {
        case 'WOD':
          list.add(
            DailyWorkoutSummary(
              category: 'WOD',
              stimuli: ['Força', 'Cardio'],
              objectiveShort: 'Clean e resistência em rounds longos',
              quote: 'Consistência vence intensidade. Hoje é mais um passo.',
            ),
          );
          break;
        case 'LPO':
          list.add(
            DailyWorkoutSummary(
              category: 'LPO',
              stimuli: ['Técnica', 'Força'],
              objectiveShort: 'Arranco leve + base de força',
              quote: 'Qualidade > quantidade — refine cada repetição.',
            ),
          );
          break;
        case 'Ginastica':
          list.add(
            DailyWorkoutSummary(
              category: 'Ginástica',
              stimuli: ['Técnica', 'Controle'],
              objectiveShort: 'Pull-up estrito e estabilidade em HS',
              quote: 'Controle do corpo, mente tranquila.',
            ),
          );
          break;
        case 'Endurance':
          list.add(
            DailyWorkoutSummary(
              category: 'Endurance',
              stimuli: ['Cardio'],
              objectiveShort: 'Pacing constante no metcon longo',
              quote: 'Respire, mantenha o ritmo e termine forte.',
            ),
          );
          break;
        default:
          // fallback
          list.add(
            DailyWorkoutSummary(
              category: cat,
              stimuli: ['Geral'],
              objectiveShort: 'Trabalho técnico do dia',
              quote: 'Um pouco por dia leva longe.',
            ),
          );
      }
    }

    // Se nenhuma categoria tiver bloco hoje, retorna lista vazia:
    return list;
  }
}
// ===================== CLASSES DO DIA =====================

extension DayClasses on TrainingService {
  /// Retorna as turmas do dia com professor.
  /// Reaproveita WorkoutResultService.fetchClassesForDate (mock).
  static Future<List<DayClass>> fetchDayClassesWithCoach(DateTime date) async {
    final slots = await WorkoutResultService.fetchClassesForDate(date);

    // ordem cíclica de categorias para MOCK
    const catOrder = ['WOD', 'LPO', 'Ginastica', 'Endurance'];

    final List<DayClass> out = [];
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];

      final timeLabel = s.label24(); // já existe no ClassSlot do seu mock
      final category = catOrder[i % catOrder.length]; // <- round-robin
      final coach = await CoachService.fetchCoachForClass(s.id);

      out.add(
        DayClass(
          id: s.id,
          timeLabel: timeLabel,
          category: category,
          coachName: coach.name,
        ),
      );
    }

    out.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
    return out;
  }

  /// Marca interesse do aluno em uma turma específica.
  static Future<void> registerInterestInClass({
    required String classId,
    required DateTime date,
    required String category,
    required String coachName,
    required String timeLabel,
  }) async {
    // TODO(back): delegar p/ API real
    await ClassInterestService.upsertInterest(
      classId: classId,
      date: date,
      category: category,
      coachName: coachName,
      timeLabel: timeLabel,
    );
  }
}

extension DailyStats on TrainingService {
  /// Quantidade total de resultados registrados no dia.
  static Future<int> fetchResultsCountForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO(back): consultar endpoint real de resultados diários.
    return 15; // mock da imagem
  }

  /// Frequência geral de alunos no dia (0–100%).
  static Future<double> fetchDailyAttendanceRate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO(back): consultar backend (média ponderada por aula).
    return 83.0; // mock da imagem
  }
}

/// Service mock: persiste em memória por data+categoria.
/// Regra: no máximo 2 interesses por dia, obrigatoriamente de categorias diferentes.
/// Se registrar uma categoria já existente no dia, faz upsert (substitui).
/// Se tentar registrar uma 3ª categoria diferente, substitui a mais antiga.
class ClassInterestService {
  static final Map<String, Map<String, InterestedClass>> _store = {};
  // key: yyyymmdd -> { category -> interest }

  static String _key(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
  }

  /// Lista interesses do dia.
  static Future<List<InterestedClass>> fetchInterestsForDate(
    DateTime date,
  ) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final map = _store[_key(date)];
    if (map == null) return [];
    final list =
        map.values.toList()..sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
    return list;
  }

  /// Upsert do interesse por categoria (máx. 2 categorias por dia).
  /// TODO(back): POST /classes/interest
  static Future<void> upsertInterest({
    required String classId,
    required DateTime date,
    required String category,
    required String coachName,
    required String timeLabel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 160));

    final k = _key(date);
    _store.putIfAbsent(k, () => {});
    final dayMap = _store[k]!;

    // Se já existe da mesma categoria, substitui:
    if (dayMap.containsKey(category)) {
      dayMap[category] = InterestedClass(
        classId: classId,
        date: date,
        category: category,
        coachName: coachName,
        timeLabel: timeLabel,
      );
      return;
    }

    // Não existe: respeitar limite de 2 categorias
    if (dayMap.length < 2) {
      dayMap[category] = InterestedClass(
        classId: classId,
        date: date,
        category: category,
        coachName: coachName,
        timeLabel: timeLabel,
      );
      return;
    }

    // Já tem 2 categorias diferentes: substituir a mais antiga
    final oldestEntry = dayMap.values.reduce(
      (a, b) => a.createdAt.isBefore(b.createdAt) ? a : b,
    );
    dayMap.remove(oldestEntry.category);
    dayMap[category] = InterestedClass(
      classId: classId,
      date: date,
      category: category,
      coachName: coachName,
      timeLabel: timeLabel,
    );
  }

  /// Remove interesse de uma categoria no dia.
  /// TODO(back): DELETE /classes/interest?date=...&category=...
  static Future<void> removeInterestForCategory({
    required DateTime date,
    required String category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final k = _key(date);
    final dayMap = _store[k];
    dayMap?.remove(category);
  }

  /// Limpa todos interesses de um dia (se precisar).
  /// TODO(back): DELETE /classes/interest?date=...
  static Future<void> clearInterestsForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _store.remove(_key(date));
  }
}
// ===================== CYCLES (MENSAL) =====================

extension CycleMonths on TrainingService {
  /// Retorna os últimos [limit] meses (normalizados para dia 1),
  /// sempre trazendo os MAIS RECENTES primeiro.
  /// TODO(back): substituir por chamada real ao backend que devolva os ciclos do box.
  static Future<List<DateTime>> fetchRecentCycleMonths({
    required String boxId,
    int limit = 3,
    bool useRangeLabel = false, // <- opção B (desligada por padrão)
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // MOCK: mês atual e dois anteriores
    final now = DateTime.now();
    final current = DateTime(now.year, now.month);
    final prev1 = DateTime(now.year, now.month - 1);
    final prev2 = DateTime(now.year, now.month - 2);

    // Se quiser variar quantidade depois, só ajustar a lista.
    final base = <DateTime>[current, prev1, prev2];

    // Mantém somente os [limit] primeiros (mais recentes)
    return base.take(limit).toList();
  }

  /// Formata o rótulo do mês para mostrar no card.
  /// Padrão: "Mar/2025".
  /// Se a opção B for adotada no futuro, este método pode
  /// formatar "01/03 – 31/03".
  static String formatCycleMonthLabel(
    DateTime month, {
    bool useRangeLabel = false,
  }) {
    if (useRangeLabel) {
      // Opção B (DESLIGADA por padrão): exibir faixa de datas do mês
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0);
      String fmt(DateTime d) =>
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
      return '${fmt(start)} – ${fmt(end)}';
    }

    // Opção A (padrão): "Mar/2025"
    final m = DateFormat('MMM', 'pt_BR').format(month);
    final monthLabel = m[0].toUpperCase() + m.substring(1); // capitaliza
    return '$monthLabel/${month.year}';
  }
}
// ===================== TODAY WORKOUT CARD HELPERS =====================

extension TodayWorkoutHelpers on TrainingService {
  /// Lista as CATEGORIAS disponíveis para o dia (ex.: ['WOD','LPO',...]).
  /// Usa o mesmo mock dos blocos do dia.
  /// TODO(back): GET /boxes/{boxId}/workouts?date=YYYY-MM-DD (retornar categorias do dia)
  static Future<List<String>> fetchAvailableCategoriesForDate({
    required String boxId,
    required DateTime date,
  }) async {
    final byCat = await TrainingService.fetchTrainingBlocksByCategoryForDate(
      boxId: boxId,
      date: date,
    );

    // Mantém somente as que têm bloco não-nulo
    final list = <String>[];
    for (final e in byCat.entries) {
      if (e.value != null) list.add(e.key);
    }
    // Sem ordenação obrigatória (virá do back). Apenas retorna.
    return list;
  }

  /// Retorna o resumo do treino (valências/objetivo) para uma CATEGORIA do dia.
  /// Reaproveita o mock de "DailyWorkoutSummary".
  /// TODO(back): GET /boxes/{boxId}/workouts/summary?date=...&category=...
  static Future<DailyWorkoutSummary?> fetchDailyWorkoutSummaryByCategory({
    required String boxId,
    required DateTime date,
    required String category,
  }) async {
    final all = await DailySummaries.fetchDailyWorkoutSummariesForBox(
      boxId: boxId,
      date: date,
    );

    // Normaliza para comparar 'Ginastica' vs 'Ginástica'
    String norm(String s) =>
        s.toLowerCase().replaceAll('á', 'a').replaceAll('ã', 'a');

    final wanted = norm(category);
    try {
      return all.firstWhere((s) => norm(s.category) == wanted);
    } catch (_) {
      return null;
    }
  }
}
