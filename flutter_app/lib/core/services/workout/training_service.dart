import 'dart:async';
import 'package:flutter_app/shared/models/box.dart';
import 'package:flutter_app/shared/models/class.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/models/daily_workout_model.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';
import 'package:flutter_app/core/services/users/coach/coach_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TrainingService {
  // ===========================================================================
  // 1. [NOVO] LÓGICA CORRIGIDA PARA A TELA DO COACH (CoachDailyTrainingsSection)
  // ===========================================================================

  /// Busca TODOS os documentos de treino do dia, sem limitar a 1.
  /// Retorna uma lista de objetos Training, onde cada objeto representa 1 Documento do Firebase.
  /// Não divide o treino em partes (WOD, Skill, etc); entrega o pacote completo (partes) para a UI decidir.
  static Future<List<Training>> fetchTrainingsListForDate({
    required String boxId,
    required DateTime date,
  }) async {
    try {
      final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);

      // 1. Query: Busca todos os documentos com a data especificada.
      // Removemos o .limit(1) para permitir múltiplos treinos (ex: WOD normal + Aula extra de LPO)
      final snapshot =
          await FirebaseFirestore.instance
              .collection('exercises')
              .where('dataTreinoIso', isEqualTo: dataFormatada)
              // .where('boxId', isEqualTo: boxId) // Descomente quando tiver multi-tenant real
              .get();

      if (snapshot.docs.isEmpty) return [];

      // 2. Mapeamento: 1 Documento Firebase = 1 Objeto Training
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Extrai o mapa de partes (WOD, SKILL, EXTRA) cru do JSON
        Map<String, dynamic> partesMap = {};
        if (data['partes'] != null && data['partes'] is Map) {
          partesMap = Map<String, dynamic>.from(data['partes']);
        }

        return Training(
          id: doc.id,
          // O título exato será gerado na UI (_generateButtonTitle), aqui colocamos um genérico
          title: "Treino do Dia",
          date: date,
          description: null,
          // IMPORTANTE: Certifique-se de ter adicionado 'partes' no construtor do model Training
          partes: partesMap,
          analysis:
              data['analise'] != null
                  ? TrainingAnalysis.fromJson(data['analise'])
                  : null,
        );
      }).toList();
    } catch (e) {
      print("ERRO FETCH LIST (COACH): $e");
      return [];
    }
  }

  // ===========================================================================
  // 2. LÓGICA LEGADA: FIREBASE (Usada para dividir o treino em blocos visuais)
  // ===========================================================================

  static Future<List<TrainingBlock>> fetchFullTrainingBlocks({
    required String boxId,
    required DateTime date,
    required String category,
    String? trainingId, // <--- NOVO PARÂMETRO OPCIONAL
  }) async {
    try {
      Map<String, dynamic>? data;

      // CENÁRIO A: Temos o ID (o usuário clicou num card específico)
      if (trainingId != null && trainingId.isNotEmpty) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('exercises')
                .doc(trainingId) // Busca direto pelo nome do documento (ID)
                .get();

        if (docSnapshot.exists) {
          data = docSnapshot.data();
        }
      }

      // CENÁRIO B: Não temos ID (fallback legado), busca pela data
      if (data == null) {
        final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);
        final snapshot =
            await FirebaseFirestore.instance
                .collection('exercises')
                .where('dataTreinoIso', isEqualTo: dataFormatada)
                .limit(1)
                .get();

        if (snapshot.docs.isNotEmpty) {
          data = snapshot.docs.first.data();
        }
      }

      // Se não achou nada em nenhum dos dois casos
      if (data == null) return [];

      // --- DAQUI PRA BAIXO É A SUA LÓGICA DE PARSE (MANTIDA IGUAL) ---
      final workoutData = DailyWorkoutModel.fromJson(data);

      List<TrainingBlock> blocks = [];
      final order = ['WARM UP', 'SKILL', 'WOD', 'EXTRA TRAINING'];

      workoutData.parts.forEach((key, part) {
        String title = key;
        if (part.wodName != null && part.wodName!.isNotEmpty) {
          title += " - ${part.wodName}";
        }

        String subtitle = part.type;
        if (part.durationMinutes != null) {
          subtitle += " (${part.durationMinutes} min)";
        }

        List<String> items = List.from(part.exercises);
        if (items.isEmpty && part.observations != null) {
          items.add(part.observations!);
        }
        if (items.isEmpty && part.exercises.isEmpty) {
          items.add("Verificar detalhes com o coach");
        }

        blocks.add(
          TrainingBlock(
            id: key,
            title: title,
            subtitle: subtitle,
            items: items,
          ),
        );
      });

      blocks.sort((a, b) {
        String keyA = a.id;
        String keyB = b.id;
        int idxA = order.indexWhere((o) => keyA.startsWith(o));
        int idxB = order.indexWhere((o) => keyB.startsWith(o));
        if (idxA == -1) idxA = 99;
        if (idxB == -1) idxB = 99;
        return idxA.compareTo(idxB);
      });

      return blocks;
    } catch (e) {
      print("ERRO FETCH FIREBASE BLOCKS: $e");
      return [];
    }
  }

  // ===========================================================================
  // 3. AUXILIAR: TRADUTOR DE CARDS (SUMMARY)
  // ===========================================================================

  static DailyWorkoutSummary createSummaryFromBlocks(
    List<TrainingBlock> blocks,
  ) {
    if (blocks.isEmpty) {
      return DailyWorkoutSummary(
        category: "REST DAY",
        stimuli: ["Recuperação"],
        objectiveShort: "Sem treino cadastrado",
        quote: "Aproveite o descanso.",
      );
    }

    final mainBlock = blocks.firstWhere(
      (b) => b.id.contains('WOD') || b.title.contains('WOD'),
      orElse: () => blocks.last,
    );

    String category = "WOD";
    final titleUpper = mainBlock.title.toUpperCase();
    if (titleUpper.contains("LPO")) category = "LPO";
    if (titleUpper.contains("GYM")) category = "GYMNASTICS";
    if (titleUpper.contains("ENDURANCE")) category = "ENDURANCE";

    List<String> stimuli = [];
    final fullText = mainBlock.items.join(' ').toUpperCase();

    if (fullText.contains("KG") || fullText.contains("MAX"))
      stimuli.add("Força");
    if (fullText.contains("AMRAP")) stimuli.add("Resistência");
    if (fullText.contains("RUN")) stimuli.add("Cardio");
    if (stimuli.isEmpty) stimuli.add("Geral");

    String obj = mainBlock.subtitle;
    if (obj.isEmpty) obj = mainBlock.title;

    return DailyWorkoutSummary(
      category: category,
      stimuli: stimuli.take(2).toList(),
      objectiveShort: obj,
      quote: "Killing the Gods",
    );
  }

  // ===========================================================================
  // 4. MÉTODOS DE COMPATIBILIDADE (LEGADO)
  // ===========================================================================

  /// Usado pelo DateSelector (Bolinhas do calendário)
  static Future<List<dynamic>> fetchWorkoutsForDate(DateTime date) async {
    final blocks = await fetchFullTrainingBlocks(
      boxId: '1',
      date: date,
      category: 'ANY',
    );
    return blocks.isNotEmpty ? ['treino_existe'] : [];
  }

  /// Usado por telas antigas que esperam TrainingBlock
  static Future<Map<String, TrainingBlock?>>
  fetchTrainingBlocksByCategoryForDate({
    required String boxId,
    required DateTime date,
  }) async {
    final blocks = await fetchFullTrainingBlocks(
      boxId: boxId,
      date: date,
      category: 'ANY',
    );
    final Map<String, TrainingBlock?> resultMap = {};

    for (var block in blocks) {
      if (block.id.contains('WOD'))
        resultMap['WOD'] = block;
      else if (block.id.contains('LPO'))
        resultMap['LPO'] = block;
      else
        resultMap[block.title] = block;
    }
    // Garante que algo apareça se tiver dados
    if (blocks.isNotEmpty && resultMap.isEmpty) resultMap['WOD'] = blocks.first;

    return resultMap;
  }

  /// [LEGADO] - Mantido apenas para não quebrar outras telas que ainda o chamam.
  /// A nova tela CoachDailyTrainingsSection NÃO usa mais este método.
  static Future<Map<String, Training?>> fetchTrainingsByCategoryForDate({
    required String boxId,
    required DateTime date,
  }) async {
    final blocks = await fetchFullTrainingBlocks(
      boxId: boxId,
      date: date,
      category: 'ANY',
    );
    final Map<String, Training?> resultMap = {};

    for (var block in blocks) {
      String catKey = 'WOD';
      if (block.id.contains('LPO'))
        catKey = 'LPO';
      else if (block.id.contains('SKILL'))
        catKey = 'Ginastica';

      resultMap[catKey] = Training(
        id: block.id,
        title: block.title,
        description: block.items.join('\n'),
        date: date,
        // Em telas antigas, talvez 'partes' não seja necessário, então mandamos vazio
        partes: {},
      );
    }

    if (blocks.isNotEmpty && resultMap.isEmpty) {
      final b = blocks.first;
      resultMap['WOD'] = Training(
        id: b.id,
        title: b.title,
        description: b.items.join('\n'),
        date: date,
        partes: {},
      );
    }

    return resultMap;
  }

  // ===========================================================================
  // 5. MOCKS E OUTROS MÉTODOS
  // ===========================================================================

  static Future<List<Box>> fetchUserBoxes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      Box(id: '1', name: 'Olympus Crossfit'),
      Box(id: '2', name: 'Spartan Gym'),
    ];
  }

  static Future<Box> registerBox(String boxName) async {
    return Box(id: 'novo', name: boxName);
  }

  static Future<List<Training>> fetchTrainingsForBox({
    required String boxId,
    required DateTime date,
  }) async {
    return [];
  }

  static Future<void> deleteTraining({
    required String boxId,
    required DateTime date,
    required String category,
    required String blockId,
  }) async {}

  static Future<void> saveFullTrainingBlocks({
    required String boxId,
    required DateTime date,
    required String category,
    required List<TrainingBlock> blocks,
  }) async {}
}

// =============================================================================
// EXTENSIONS
// =============================================================================

extension DailySummaries on TrainingService {
  static Future<List<DailyWorkoutSummary>> fetchDailyWorkoutSummariesForBox({
    required String boxId,
    required DateTime date,
  }) async {
    final blocks = await TrainingService.fetchFullTrainingBlocks(
      boxId: boxId,
      date: date,
      category: 'ANY',
    );
    if (blocks.isEmpty) return [];
    return [TrainingService.createSummaryFromBlocks(blocks)];
  }
}

extension DayClasses on TrainingService {
  static Future<List<DayClass>> fetchDayClassesWithCoach(DateTime date) async {
    final slots = await WorkoutResultService.fetchClassesForDate(date);
    final List<DayClass> out = [];
    for (var s in slots) {
      final coach = await CoachService.fetchCoachForClass(s.id);
      out.add(
        DayClass(
          id: s.id,
          timeLabel: s.label24(),
          category: 'WOD',
          coachName: coach.name,
        ),
      );
    }
    out.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
    return out;
  }

  static Future<void> registerInterestInClass({
    required String classId,
    required DateTime date,
    required String category,
    required String coachName,
    required String timeLabel,
  }) async {
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
  static Future<int> fetchResultsCountForDate(DateTime date) async {
    return 15;
  }

  static Future<double> fetchDailyAttendanceRate(DateTime date) async {
    return 83.0;
  }
}

class ClassInterestService {
  static final Map<String, Map<String, InterestedClass>> _store = {};
  static String _key(DateTime d) => '${d.year}${d.month}${d.day}';

  static Future<List<InterestedClass>> fetchInterestsForDate(
    DateTime date,
  ) async {
    final map = _store[_key(date)];
    if (map == null) return [];
    return map.values.toList()
      ..sort((a, b) => a.timeLabel.compareTo(b.timeLabel));
  }

  static Future<void> upsertInterest({
    required String classId,
    required DateTime date,
    required String category,
    required String coachName,
    required String timeLabel,
  }) async {
    final k = _key(date);
    _store.putIfAbsent(k, () => {});
    _store[k]![category] = InterestedClass(
      classId: classId,
      date: date,
      category: category,
      coachName: coachName,
      timeLabel: timeLabel,
    );
  }

  static Future<void> removeInterestForCategory({
    required DateTime date,
    required String category,
  }) async {
    _store[_key(date)]?.remove(category);
  }

  static Future<void> clearInterestsForDate(DateTime date) async {
    _store.remove(_key(date));
  }
}

extension CycleMonths on TrainingService {
  static Future<List<DateTime>> fetchRecentCycleMonths({
    required String boxId,
    int limit = 3,
  }) async {
    final now = DateTime.now();
    return [
      DateTime(now.year, now.month),
      DateTime(now.year, now.month - 1),
      DateTime(now.year, now.month - 2),
    ];
  }

  static String formatCycleMonthLabel(DateTime month) {
    final m = DateFormat('MMM', 'pt_BR').format(month);
    return '${m[0].toUpperCase()}${m.substring(1)}/${month.year}';
  }
}

// ===========================================================================
// [ADICIONADO DO CÓDIGO DO COLEGA] Extension CycleAll
// ===========================================================================
extension CycleAll on TrainingService {
  /// Retorna os meses (1-12) que possuem ciclo cadastrado no [year].
  /// TODO(back): substituir por consulta real (Firebase) filtrando por boxId + ano.
  static Future<List<int>> fetchRegisteredCycleMonthsForYear({
    required String boxId,
    required int year,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // MOCK: dataset fixo (exemplo da sua referência)
    // 2025: Jan, Fev, Mar
    // 2026: Jan
    final mock = <int, List<int>>{
      2025: [1, 2, 3],
      2026: [1],
    };

    final months = mock[year] ?? const <int>[];
    final sorted = [...months]..sort();
    return sorted;
  }

  /// Retorna o ciclo vigente = último ciclo registrado (mais recente).
  /// TODO(back): substituir por query que retorna o último ciclo (orderBy date desc limit 1).
  static Future<DateTime?> fetchCurrentCycleMonth({
    required String boxId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // MOCK consistente com fetchRegisteredCycleMonthsForYear
    final all = <DateTime>[
      DateTime(2025, 1),
      DateTime(2025, 2),
      DateTime(2025, 3),
      DateTime(2026, 1),
    ];

    if (all.isEmpty) return null;
    all.sort((a, b) => a.compareTo(b));
    return all.last;
  }

  /// Apenas helper: checa se existe ciclo no (year, month).
  /// TODO(back): substituir por leitura direta.
  static Future<bool> isCycleRegistered({
    required String boxId,
    required int year,
    required int month,
  }) async {
    final months = await fetchRegisteredCycleMonthsForYear(
      boxId: boxId,
      year: year,
    );
    return months.contains(month);
  }
}

extension TodayWorkoutHelpers on TrainingService {
  static Future<List<String>> fetchAvailableCategoriesForDate({
    required String boxId,
    required DateTime date,
  }) async {
    final summaries = await DailySummaries.fetchDailyWorkoutSummariesForBox(
      boxId: boxId,
      date: date,
    );
    return summaries.map((s) => s.category).toList();
  }

  static Future<DailyWorkoutSummary?> fetchDailyWorkoutSummaryByCategory({
    required String boxId,
    required DateTime date,
    required String category,
  }) async {
    final summaries = await DailySummaries.fetchDailyWorkoutSummariesForBox(
      boxId: boxId,
      date: date,
    );
    if (summaries.isEmpty) return null;
    return summaries.first;
  }
}
