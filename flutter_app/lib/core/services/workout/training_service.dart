import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Imports do projeto
import 'package:flutter_app/shared/models/box.dart';
import 'package:flutter_app/shared/models/class.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/models/daily_workout_model.dart';

// Import da tela de edição
import 'package:flutter_app/features/user/coach/coach_training_edit_screen.dart';

// Outros services
import 'package:flutter_app/core/services/workout/workout_result_service.dart';
import 'package:flutter_app/core/services/users/coach/coach_service.dart';

class TrainingService {
  // ===========================================================================
  // 1. LEITURA DE DADOS (FETCH)
  // ===========================================================================

  /// Helper crucial para pegar o ID do documento da data
  static Future<String?> fetchDocumentIdForDate(DateTime date) async {
    final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);
    final snap =
        await FirebaseFirestore.instance
            .collection('exercises')
            .where('dataTreinoIso', isEqualTo: dataFormatada)
            .limit(1)
            .get();
    if (snap.docs.isNotEmpty) return snap.docs.first.id;
    return null;
  }

  /// Busca TODOS os documentos de treino do dia.
  static Future<List<Training>> fetchTrainingsListForDate({
    required String boxId,
    required DateTime date,
  }) async {
    try {
      final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);

      final snapshot =
          await FirebaseFirestore.instance
              .collection('exercises')
              .where('dataTreinoIso', isEqualTo: dataFormatada)
              .get();

      if (snapshot.docs.isEmpty) return [];

      return snapshot.docs.map((doc) {
        final data = doc.data();
        Map<String, dynamic> partesMap = {};
        if (data['partes'] != null && data['partes'] is Map) {
          partesMap = Map<String, dynamic>.from(data['partes']);
        }

        return Training(
          id: doc.id,
          title: "Treino do Dia",
          date: date,
          description: null,
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

  /// Busca e converte o treino em Blocos (TrainingBlock) para a UI.
  static Future<List<TrainingBlock>> fetchFullTrainingBlocks({
    required String boxId,
    required DateTime date,
    required String category,
    String? trainingId,
  }) async {
    try {
      Map<String, dynamic>? data;

      // CENÁRIO A: Busca direta pelo ID
      if (trainingId != null && trainingId.isNotEmpty) {
        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('exercises')
                .doc(trainingId)
                .get();

        if (docSnapshot.exists) {
          data = docSnapshot.data();
        }
      }

      // CENÁRIO B: Busca pela data (fallback)
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

      if (data == null) return [];

      final workoutData = DailyWorkoutModel.fromJson(data);
      List<TrainingBlock> blocks = [];
      final order = ['WARM UP', 'SKILL', 'WOD', 'EXTRA TRAINING'];

      workoutData.parts.forEach((key, part) {
        String title = key;
        if (part.wodName != null && part.wodName!.isNotEmpty) {
          title += " - ${part.wodName}";
        }

        String subtitle = part.type;
        if (part.durationMinutes != null && part.durationMinutes! > 0) {
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

      // Ordenação visual robusta (trata WOD_2 como WOD para fins de ordem de categoria)
      blocks.sort((a, b) {
        // Pega o prefixo antes do _ (Ex: WOD_2 -> WOD)
        String typeA = a.id.split('_')[0];
        String typeB = b.id.split('_')[0];

        int idxA = order.indexWhere((o) => typeA.startsWith(o));
        int idxB = order.indexWhere((o) => typeB.startsWith(o));

        if (idxA == -1) idxA = 99;
        if (idxB == -1) idxB = 99;

        int comp = idxA.compareTo(idxB);
        if (comp != 0) return comp;

        // Desempate alfabético (WOD vem antes de WOD_2)
        return a.id.compareTo(b.id);
      });

      return blocks;
    } catch (e) {
      print("ERRO FETCH FIREBASE BLOCKS: $e");
      return [];
    }
  }

  // ===========================================================================
  // 2. AÇÕES DE BANCO DE DADOS (DELETE / UPDATE)
  // ===========================================================================

  static Future<void> deleteTraining({
    required String boxId,
    required DateTime date,
    required String category,
    required String blockId,
  }) async {
    try {
      final collection = FirebaseFirestore.instance.collection('exercises');

      // Se for ID hash (longo), deleta direto o documento
      if (blockId.length > 10 && !blockId.contains(' ')) {
        await collection.doc(blockId).delete();
        print("Treino deletado por ID direto: $blockId");
        return;
      }

      // Fallback: Busca documento pela data e deleta
      final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);
      final snapshot =
          await collection
              .where('dataTreinoIso', isEqualTo: dataFormatada)
              .limit(1)
              .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        print("Treino deletado via Data: ${doc.id}");
      }
    } catch (e) {
      print("ERRO AO DELETAR TREINO: $e");
      rethrow;
    }
  }

  /// CORREÇÃO CRÍTICA AQUI:
  /// Usamos docRef.update() quando existe, para SUBSTITUIR o mapa 'partes'
  /// e evitar a duplicação de WODs antigos.
  static Future<void> updateTrainingFromEditable({
    required String boxId,
    required DateTime date,
    required String category,
    required EditableTraining edited,
    String?
    docId, // Opcional: ID do documento para garantir update no lugar certo
  }) async {
    try {
      final collection = FirebaseFirestore.instance.collection('exercises');
      DocumentReference docRef;
      bool exists = false;

      // 1. Identifica o Documento
      if (docId != null && docId.isNotEmpty) {
        docRef = collection.doc(docId);
        final docSnap = await docRef.get();
        exists = docSnap.exists;
      } else {
        final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);
        final snapshot =
            await collection
                .where('dataTreinoIso', isEqualTo: dataFormatada)
                .limit(1)
                .get();

        if (snapshot.docs.isNotEmpty) {
          docRef = snapshot.docs.first.reference;
          exists = true;
        } else {
          docRef = collection.doc();
          exists = false;
        }
      }

      // 2. Converte EditableTraining (UI) -> Map (Firebase)
      Map<String, dynamic> partesMap = {};

      for (var section in edited.sections) {
        String baseKey = section.type.toUpperCase(); // WOD, SKILL
        String key = baseKey;

        // Garante chaves únicas: WOD, WOD_2, WOD_3
        int count = 2;
        while (partesMap.containsKey(key)) {
          key = "${baseKey}_$count";
          count++;
        }

        List<String> exercisesList = [];
        for (var mov in section.movements) {
          String line = mov.name;
          if (mov.reps.isNotEmpty) {
            line = "${mov.reps} $line";
          }
          if (mov.load != null && mov.load!.trim().isNotEmpty) {
            line = "$line (${mov.load})";
          }
          exercisesList.add(line);
        }

        partesMap[key] = {
          'type': section.type,
          'wodName': section.name ?? '',
          'durationMinutes': section.timeMinutes ?? 0,
          'exercises': exercisesList,
          'observations': '',
        };
      }

      // 3. Payload Final
      final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);
      final Map<String, dynamic> payload = {
        'boxId': boxId,
        'dataTreinoIso': dataFormatada,
        'dataCriacao': FieldValue.serverTimestamp(),

        // Aqui está o segredo: Substituímos 'partes' inteiramente pelo novo mapa
        'partes': partesMap,

        'statusAnalise': 'pendente', // Gatilho Python
        'analise': FieldValue.delete(),
      };

      // 4. Salva CORRETAMENTE
      if (exists) {
        // UPDATE: Substitui os campos informados.
        // Como passamos um novo Map para 'partes', as chaves antigas somem.
        await docRef.update(payload);
        print("Treino atualizado (UPDATE) - Chaves antigas removidas.");
      } else {
        // SET: Cria novo documento
        await docRef.set(payload);
        print("Treino criado (SET).");
      }
    } catch (e) {
      print("ERRO AO SALVAR TREINO EDITADO: $e");
      rethrow;
    }
  }

  // ===========================================================================
  // 3. HELPER: SUMMARY DE CARDS
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
  // 4. MÉTODOS LEGADOS (COMPATIBILIDADE)
  // ===========================================================================

  static Future<List<dynamic>> fetchWorkoutsForDate(DateTime date) async {
    final blocks = await fetchFullTrainingBlocks(
      boxId: '1',
      date: date,
      category: 'ANY',
    );
    return blocks.isNotEmpty ? ['treino_existe'] : [];
  }

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
      // Se houver múltiplos WODs, isso vai pegar o último ou sobrescrever,
      // mas é um método legado que retorna Map, então é o comportamento esperado.
      if (block.id.contains('WOD'))
        resultMap['WOD'] = block;
      else if (block.id.contains('LPO'))
        resultMap['LPO'] = block;
      else
        resultMap[block.title] = block;
    }

    // Se achou blocos mas nenhum caiu nas categorias acima, força o primeiro como WOD
    if (blocks.isNotEmpty && resultMap.isEmpty) resultMap['WOD'] = blocks.first;

    return resultMap;
  }

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
        partes: {},
      );
    }
    return resultMap;
  }

  // ===========================================================================
  // 5. MOCKS E AUXILIARES
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
}

// =============================================================================
// EXTENSIONS (Mantidas inalteradas)
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

extension CycleAll on TrainingService {
  static Future<List<int>> fetchRegisteredCycleMonthsForYear({
    required String boxId,
    required int year,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final mock = <int, List<int>>{
      2025: [1, 2, 3],
      2026: [1],
    };
    final months = mock[year] ?? const <int>[];
    final sorted = [...months]..sort();
    return sorted;
  }

  static Future<DateTime?> fetchCurrentCycleMonth({
    required String boxId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
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
