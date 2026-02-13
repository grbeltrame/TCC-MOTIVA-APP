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
    String? trainingId, // <--- Esse cara é a chave de tudo
  }) async {
    try {
      Map<String, dynamic>? data;
      String? currentDocId = trainingId;

      // CENÁRIO A: Busca EXATA pelo ID (Prioridade Total)
      if (trainingId != null && trainingId.isNotEmpty) {
        // Removemos qualquer sufixo composto se houver (ex: "id__WOD" vira "id")
        if (trainingId.contains('__')) {
          currentDocId = trainingId.split('__')[0];
        }

        print("🔍 Buscando documento específico ID: $currentDocId");

        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('exercises')
                .doc(currentDocId)
                .get();

        if (docSnapshot.exists) {
          data = docSnapshot.data();
        } else {
          print("⚠️ Documento $currentDocId não encontrado!");
          return [];
        }
      }

      // CENÁRIO B: Busca pela data (SOMENTE se não tiver ID)
      if (data == null && (trainingId == null || trainingId.isEmpty)) {
        print("🔍 Buscando primeiro treino disponível na data: $date");
        final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);
        final snapshot =
            await FirebaseFirestore.instance
                .collection('exercises')
                .where('dataTreinoIso', isEqualTo: dataFormatada)
                .limit(1)
                .get();

        if (snapshot.docs.isNotEmpty) {
          data = snapshot.docs.first.data();
          currentDocId = snapshot.docs.first.id;
        }
      }

      if (data == null) return [];

      // --- Daqui para baixo é a conversão dos dados (Mantemos igual) ---
      final workoutData = DailyWorkoutModel.fromJson(data);
      List<TrainingBlock> blocks = [];
      final order = ['WARM UP', 'SKILL', 'WOD', 'EXTRA TRAINING'];

      workoutData.parts.forEach((key, part) {
        String title = key;
        if (part.wodName != null && part.wodName!.isNotEmpty) {
          title += " - ${part.wodName}";
        }

        // ... (resto da lógica de montagem dos textos mantém igual) ...
        String subtitle = part.type;
        if (part.durationMinutes != null && part.durationMinutes! > 0) {
          subtitle += " (${part.durationMinutes} min)";
        }

        List<String> items = List.from(part.exercises);
        if (items.isEmpty && part.observations != null)
          items.add(part.observations!);

        blocks.add(
          TrainingBlock(
            // AQUI É IMPORTANTE: O ID do bloco DEVE conter o ID do Documento
            // Mantemos o formato composto para a UI saber qual aba abrir,
            // mas o ID do doc é o principal.
            id: "$currentDocId",
            // Nota: Se você precisar diferenciar partes na UI, pode usar "$currentDocId__$key"
            // Mas para "Editar o Treino", precisamos saber o DocID.
            title: title,
            subtitle: subtitle,
            items: items,
          ),
        );
      });

      // ... (ordenação mantém igual) ...
      blocks.sort((a, b) {
        // ... (sua lógica de sort) ...
        return 0; // simplificado aqui
      });

      return blocks;
    } catch (e) {
      print("❌ ERRO FETCH FIREBASE BLOCKS: $e");
      return [];
    }
  }

  static List<String>? _parseCompositeId(String compositeId) {
    if (compositeId.contains('__')) {
      final parts = compositeId.split('__');
      if (parts.length >= 2) {
        return [parts[0], parts[1]]; // [docId, mapKey]
      }
    }
    return null;
  }

  static String _mapUiTypeToDbKey(String uiType) {
    final t = uiType.trim().toUpperCase();
    if (t.contains('WARM')) return 'WARM UP';
    if (t.contains('SKILL')) return 'SKILL';
    if (t.contains('EXTRA')) return 'EXTRA TRAINING';
    return 'WOD'; // Padrão
  }

  static Future<void> deleteTraining({
    required String boxId,
    required DateTime date,
    required String category,
    required String
    blockId, // Esperamos que aqui chegue o ID do Documento (ex: igTZ...)
  }) async {
    try {
      final collection = FirebaseFirestore.instance.collection('exercises');

      String docId = blockId;
      if (blockId.contains('__')) {
        docId = blockId.split('__')[0];
      }

      print("🗑️ [DELETE] Apagando documento inteiro ID: $docId");

      // 2. A "Bomba Atômica": Apaga o documento direto pelo ID.
      await collection.doc(docId).delete();

      print("✅ Documento $docId removido com sucesso.");
    } catch (e) {
      print("❌ ERRO AO DELETAR TREINO: $e");
      rethrow;
    }
  }

  static Future<void> updateTrainingFromEditable({
    required String boxId,
    required DateTime date,
    required String category,
    required EditableTraining edited,
    String? docId, // <--- Agora aceitamos o ID explícito
  }) async {
    try {
      final collection = FirebaseFirestore.instance.collection('exercises');
      DocumentReference docRef;
      bool exists = false;

      // 1. Identifica o documento (Prioridade para o docId explícito)
      if (docId != null && docId.isNotEmpty) {
        docRef = collection.doc(docId);
        final snap = await docRef.get();
        exists = snap.exists;
        print("💾 Salvando no DocID específico: $docId");
      } else {
        // Fallback para Data
        final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);
        final snapshot =
            await collection
                .where('dataTreinoIso', isEqualTo: dataFormatada)
                .limit(1)
                .get();

        if (snapshot.docs.isNotEmpty) {
          docRef = snapshot.docs.first.reference;
          exists = true;
          print(
            "💾 Salvando via busca por Data (Doc encontrado: ${docRef.id})",
          );
        } else {
          docRef = collection.doc();
          exists = false;
          print("💾 Criando novo documento.");
        }
      }

      // 2. Constrói o mapa 'partes'
      Map<String, dynamic> partesMap = {};

      for (var section in edited.sections) {
        // Pega a chave correta: "WARM UP", "SKILL", "WOD"
        String dbKeyBase = _mapUiTypeToDbKey(section.type);
        String finalKey = dbKeyBase;

        // Trata chaves duplicadas (ex: WOD_2)
        int count = 2;
        while (partesMap.containsKey(finalKey)) {
          finalKey = "${dbKeyBase}_$count";
          count++;
        }

        // --- LIMPEZA DE NOME (Mantida sua lógica original) ---
        String? cleanName = section.name;
        if (cleanName != null && cleanName.trim().isNotEmpty) {
          String pattern =
              '(${RegExp.escape(dbKeyBase)}|${RegExp.escape(section.type)})[\\s\\-:]*';
          final regExp = RegExp('^($pattern)+', caseSensitive: false);

          cleanName = cleanName.replaceAll(regExp, '').trim();

          if (cleanName.startsWith('-')) {
            cleanName = cleanName.substring(1).trim();
          }
        }
        // ----------------------------------------------------

        // Reconstrói a lista de exercícios
        List<String> exercisesList = [];
        for (var mov in section.movements) {
          String line = "";
          if (mov.reps.isNotEmpty) line = mov.reps;

          if (mov.name.isNotEmpty) {
            line = line.isEmpty ? mov.name : "$line ${mov.name}";
          }

          if (mov.load != null && mov.load!.trim().isNotEmpty) {
            line = "$line (${mov.load})";
          }

          if (line.trim().isNotEmpty) {
            exercisesList.add(line);
          }
        }

        partesMap[finalKey] = {
          // Se for WarmUp, salva tipo AMRAP (padrão antigo) ou o próprio tipo
          'tipo':
              section.type.toUpperCase() == 'WARMUP'
                  ? 'AMRAP'
                  : section.type.toUpperCase(),
          'nomeWod': cleanName,
          'duracaoMinutos': section.timeMinutes,
          'exercicios': exercisesList,
          'observacoes': null,
        };
      }

      // 3. Salva no Firestore
      if (exists) {
        // Atualiza o mapa de partes no documento existente
        await docRef.update({'partes': partesMap, 'statusAnalise': 'pendente'});
        print("✅ Treino atualizado com sucesso.");
      } else {
        // Cria novo documento
        final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);
        await docRef.set({
          'boxId': boxId,
          'dataTreinoIso': dataFormatada,
          'dataDoTreinoTexto':
              "${date.day} ${DateFormat('MMMM', 'pt_BR').format(date).toUpperCase()}",
          'diaDaSemana': DateFormat(
            'EEEE',
            'pt_BR',
          ).format(date).toUpperCase().replaceAll('-FEIRA', ' FEIRA'),
          'criadoEm': FieldValue.serverTimestamp(),
          'partes': partesMap,
          'statusAnalise': 'pendente',
          'uploadedBy': 'COACH_APP',
          'status': 'processado',
        });
        print("✅ Novo treino criado com sucesso.");
      }
    } catch (e) {
      print("❌ ERRO AO SALVAR TREINO: $e");
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

  static Future<Map<String, TrainingBlock?>> getAllTrainingBlocksRaw({
    required String boxId,
    required DateTime date,
  }) async {
    try {
      final collection = FirebaseFirestore.instance.collection('exercises');
      final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);

      print("🔍 [SERVICE] Listando todos os documentos do dia: $dataFormatada");

      final snapshot =
          await collection
              .where('dataTreinoIso', isEqualTo: dataFormatada)
              .get();

      if (snapshot.docs.isEmpty) return {};

      Map<String, TrainingBlock?> result = {};

      // Para cada DOCUMENTO encontrado (ex: Documento A, Documento B)
      for (var doc in snapshot.docs) {
        final docData = doc.data();
        final docId = doc.id; // ESSE É O ID QUE IMPORTA (ex: igTZ...)

        // Vamos tentar encontrar a parte principal (WOD) para ser o título do Card
        // Se não tiver WOD, pegamos a primeira parte que tiver.
        if (docData['partes'] != null && docData['partes'] is Map) {
          final Map<String, dynamic> partes = Map<String, dynamic>.from(
            docData['partes'],
          );

          // Tenta achar o WOD ou usa a primeira chave
          String mainKey = partes.keys.firstWhere(
            (k) => k.contains('WOD'),
            orElse: () => partes.keys.first,
          );

          final mainPart = Map<String, dynamic>.from(partes[mainKey]);

          String title =
              mainPart['nomeWod'] ?? mainKey; // Ex: "INFINITY" ou "WOD"
          String subtitle = mainPart['tipo'] ?? mainKey; // Ex: "WOD"

          List<String> items = [];
          if (mainPart['exercicios'] != null) {
            items = List<String>.from(mainPart['exercicios']);
          }

          // CRIAMOS O BLOCO REPRESENTANDO O DOCUMENTO INTEIRO
          result[docId] = TrainingBlock(
            id: docId, // <--- ID PURO DO DOCUMENTO
            title: title,
            subtitle: subtitle,
            items: items,
          );
        }
      }

      print("✅ [SERVICE] Cards gerados: ${result.length}");
      return result;
    } catch (e) {
      print("❌ [SERVICE ERROR]: $e");
      return {};
    }
  }

  // Helper ajustado para receber o docId original
  static TrainingBlock _mapPartToTrainingBlock(
    String keyId, // Ex: "WOD"
    Map<String, dynamic> data,
    String originalDocId, // Novo parâmetro: ID do documento pai
  ) {
    List<String> items = [];
    if (data['exercicios'] != null) {
      items = List<String>.from(data['exercicios']);
    }

    String tipoRaw =
        data['tipo']?.toString().toUpperCase() ?? keyId.toUpperCase();

    String subtitle = tipoRaw;
    if (data['duracaoMinutos'] != null) {
      subtitle += " • ${data['duracaoMinutos']} min";
    }

    String title = keyId;
    if (data['nomeWod'] != null &&
        data['nomeWod'].toString().trim().isNotEmpty) {
      title = data['nomeWod'];
    }

    return TrainingBlock(
      // DICA: Aqui no ID do bloco, guardamos o ID do Doc + a chave interna
      // Isso vai facilitar muito quando você clicar em "Editar" ou "Apagar" depois.
      id: "${originalDocId}__${keyId}",
      title: title,
      subtitle: subtitle,
      items: items,
    );
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
