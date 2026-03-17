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

  /// Helper para pegar o ID do documento pela data.
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

  /// Busca TODOS os documentos de treino do dia como lista de Training.
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
          title: 'Treino do Dia',
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
      print('ERRO FETCH LIST (COACH): $e');
      return [];
    }
  }

  /// Busca e converte o treino em Blocos (TrainingBlock) para a UI.
  /// Suporta schema antigo e novo sem crash.
  static Future<List<TrainingBlock>> fetchFullTrainingBlocks({
    required String boxId,
    required DateTime date,
    required String category,
    String? trainingId,
  }) async {
    try {
      Map<String, dynamic>? data;
      String? currentDocId = trainingId;

      // CENÁRIO A: Busca EXATA pelo ID (prioridade total)
      if (trainingId != null && trainingId.isNotEmpty) {
        if (trainingId.contains('__')) {
          currentDocId = trainingId.split('__')[0];
        }

        print('🔍 Buscando documento específico ID: $currentDocId');

        final docSnapshot =
            await FirebaseFirestore.instance
                .collection('exercises')
                .doc(currentDocId)
                .get();

        if (docSnapshot.exists) {
          data = docSnapshot.data();
        } else {
          print('⚠️ Documento $currentDocId não encontrado!');
          return [];
        }
      }

      // CENÁRIO B: Busca pela data (somente se não tiver ID)
      if (data == null && (trainingId == null || trainingId.isEmpty)) {
        print('🔍 Buscando treino na data: $date');
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

      // Converte via DailyWorkoutModel (suporta schema antigo e novo)
      final workoutData = DailyWorkoutModel.fromJson(data);
      final List<TrainingBlock> blocks = [];

      // Ordem correta do CrossFit: Warm Up → Extra Training → Skill → WOD
      const sectionOrder = ['WARM UP', 'EXTRA TRAINING', 'SKILL', 'WOD'];

      workoutData.parts.forEach((key, part) {
        // Monta título: "WOD - SKY IS THE LIMIT"
        String title = key;
        if (part.wodName != null && part.wodName!.isNotEmpty) {
          title += ' - ${part.wodName}';
        }

        // Monta subtitle usando part.type, que já resolve:
        //   schema novo → modalidade (ex: "3 ROUNDS FOR TIME")
        //   schema antigo → tipo (ex: "AMRAP")
        String subtitle = part.type.isNotEmpty ? part.type : key;
        if (part.durationMinutes != null && part.durationMinutes! > 0) {
          subtitle += ' (${part.durationMinutes} min)';
        }

        List<String> items = List.from(part.exercises);
        if (items.isEmpty && part.observations != null) {
          items.add(part.observations!);
        }

        blocks.add(
          TrainingBlock(
            id: '$currentDocId',
            title: title,
            subtitle: subtitle,
            items: items,
          ),
        );
      });

      // Ordena pelos índices de sectionOrder.
      // Seções desconhecidas (ex: LPO) vão para o final.
      blocks.sort((a, b) {
        final keyA = a.title.split(' - ').first.trim();
        final keyB = b.title.split(' - ').first.trim();
        final idxA = sectionOrder.indexOf(keyA);
        final idxB = sectionOrder.indexOf(keyB);
        final orderA = idxA == -1 ? sectionOrder.length : idxA;
        final orderB = idxB == -1 ? sectionOrder.length : idxB;
        return orderA.compareTo(orderB);
      });

      return blocks;
    } catch (e) {
      print('❌ ERRO FETCH FIREBASE BLOCKS: $e');
      return [];
    }
  }

  // ===========================================================================
  // 2. ESCRITA DE DADOS (UPDATE / DELETE)
  // ===========================================================================

  static Future<void> deleteTraining({
    required String boxId,
    required DateTime date,
    required String category,
    required String blockId,
  }) async {
    try {
      final collection = FirebaseFirestore.instance.collection('exercises');

      String docId = blockId;
      if (blockId.contains('__')) {
        docId = blockId.split('__')[0];
      }

      print('🗑️ [DELETE] Apagando documento ID: $docId');
      await collection.doc(docId).delete();
      print('✅ Documento $docId removido com sucesso.');
    } catch (e) {
      print('❌ ERRO AO DELETAR TREINO: $e');
      rethrow;
    }
  }

  static Future<void> updateTrainingFromEditable({
    required String boxId,
    required DateTime date,
    required String category,
    required EditableTraining edited,
    String? docId,
  }) async {
    try {
      final collection = FirebaseFirestore.instance.collection('exercises');
      DocumentReference docRef;
      bool exists = false;

      // 1. Identifica o documento (prioridade para docId explícito)
      if (docId != null && docId.isNotEmpty) {
        docRef = collection.doc(docId);
        final snap = await docRef.get();
        exists = snap.exists;
        print('💾 Salvando no DocID específico: $docId');
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
          print('💾 Salvando via busca por data (Doc: ${docRef.id})');
        } else {
          docRef = collection.doc();
          exists = false;
          print('💾 Criando novo documento.');
        }
      }

      // 2. Constrói o mapa 'partes' no NOVO schema
      Map<String, dynamic> partesMap = {};

      for (var section in edited.sections) {
        final String dbKeyBase = _mapUiTypeToDbKey(section.type);
        String finalKey = dbKeyBase;
        int count = 2;
        while (partesMap.containsKey(finalKey)) {
          finalKey = '${dbKeyBase}_$count';
          count++;
        }

        // Limpeza do nome: remove o prefixo da seção se vier junto
        // Ex: "WOD - SKY IS THE LIMIT" → "SKY IS THE LIMIT"
        String? cleanName = section.name;
        if (cleanName != null && cleanName.trim().isNotEmpty) {
          final pattern =
              '(${RegExp.escape(dbKeyBase)}|${RegExp.escape(section.type)})[\\s\\-:]*';
          final regExp = RegExp('^($pattern)+', caseSensitive: false);
          cleanName = cleanName.replaceAll(regExp, '').trim();
          if (cleanName.startsWith('-')) {
            cleanName = cleanName.substring(1).trim();
          }
        }
        if (cleanName != null && cleanName.isEmpty) cleanName = null;

        // 3. Reconstrói exercícios no NOVO schema (lista de Maps estruturados)
        final List<Map<String, dynamic>> exerciciosNovos = [];

        for (var mov in section.movements) {
          final String reps = mov.reps.trim();
          final String name = mov.name.trim();
          final String? load =
              (mov.load?.trim().isEmpty ?? true) ? null : mov.load!.trim();

          // Monta a string 'raw' para compatibilidade com a UI
          String raw = reps.isNotEmpty ? reps : '';
          if (name.isNotEmpty) raw = raw.isEmpty ? name : '$raw $name';
          if (load != null) raw = '$raw ($load)';
          raw = raw.trim();

          if (raw.isEmpty) continue;

          // Detecta distância: "500m Run"
          int? quantidade;
          String unidade = 'reps';
          final distMatch = RegExp(
            r'^(\d+)m\s',
            caseSensitive: false,
          ).firstMatch(raw);
          if (distMatch != null) {
            quantidade = int.tryParse(distMatch.group(1)!);
            unidade = 'metros';
          } else {
            final numMatch = RegExp(r'^(\d+)').firstMatch(reps);
            if (numMatch != null) quantidade = int.tryParse(numMatch.group(1)!);
          }

          // Separa carga RX e Scaled: "24Kg|18Kg"
          String? cargaRx;
          String? cargaScaled;
          if (load != null) {
            if (load.contains('|')) {
              final loadParts = load.split('|').map((p) => p.trim()).toList();
              cargaRx = loadParts[0];
              cargaScaled = loadParts.length > 1 ? loadParts[1] : null;
            } else {
              cargaRx = load;
            }
          }

          exerciciosNovos.add({
            'raw': raw,
            'quantidade': quantidade,
            'nome': name.isNotEmpty ? name : raw,
            'unidade': unidade,
            'cargaRx': cargaRx,
            'cargaScaled': cargaScaled,
          });
        }

        partesMap[finalKey] = {
          'secao': dbKeyBase,
          'modalidade': section.modalidade, // ex: "AMRAP", "3 ROUNDS FOR TIME"
          'rounds': section.rounds, // ex: 3 (ou null)
          'nomeWod': cleanName,
          'duracaoMinutos': section.timeMinutes,
          'exercicios': exerciciosNovos, // lista de Maps (schema novo)
          'observacoes': null,
        };
      }

      // 4. Salva no Firestore
      if (exists) {
        await docRef.update({'partes': partesMap, 'statusAnalise': 'pendente'});
        print('✅ Treino atualizado com sucesso.');
      } else {
        final String dataFormatada = DateFormat('yyyy-MM-dd').format(date);
        await docRef.set({
          'boxId': boxId,
          'dataTreinoIso': dataFormatada,
          'dataDoTreinoTexto':
              '${date.day} ${DateFormat('MMMM', 'pt_BR').format(date).toUpperCase()}',
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
        print('✅ Novo treino criado com sucesso.');
      }
    } catch (e) {
      print('❌ ERRO AO SALVAR TREINO: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // 3. HELPERS INTERNOS
  // ===========================================================================

  static List<String>? _parseCompositeId(String compositeId) {
    if (compositeId.contains('__')) {
      final parts = compositeId.split('__');
      if (parts.length >= 2) return [parts[0], parts[1]];
    }
    return null;
  }

  static String _mapUiTypeToDbKey(String uiType) {
    final t = uiType.trim().toUpperCase();
    if (t.contains('WARM')) return 'WARM UP';
    if (t.contains('SKILL')) return 'SKILL';
    if (t.contains('EXTRA')) return 'EXTRA TRAINING';
    return 'WOD';
  }

  // ===========================================================================
  // 4. SUMMARY DE CARDS
  // ===========================================================================

  static DailyWorkoutSummary createSummaryFromBlocks(
    List<TrainingBlock> blocks,
  ) {
    if (blocks.isEmpty) {
      return DailyWorkoutSummary(
        category: 'REST DAY',
        stimuli: ['Recuperação'],
        objectiveShort: 'Sem treino cadastrado',
        quote: 'Aproveite o descanso.',
      );
    }

    final mainBlock = blocks.firstWhere(
      (b) => b.title.toUpperCase().contains('WOD'),
      orElse: () => blocks.last,
    );

    String category = 'WOD';
    final titleUpper = mainBlock.title.toUpperCase();
    if (titleUpper.contains('LPO')) category = 'LPO';
    if (titleUpper.contains('GYM')) category = 'GYMNASTICS';
    if (titleUpper.contains('ENDURANCE')) category = 'ENDURANCE';

    final List<String> stimuli = [];
    final String fullText = mainBlock.items.join(' ').toUpperCase();
    final String subtitleUpper = mainBlock.subtitle.toUpperCase();

    // Detecta força por Kg nos items ou na modalidade do subtitle
    if (fullText.contains('KG') ||
        subtitleUpper.contains('KG') ||
        fullText.contains('MAX')) {
      stimuli.add('Força');
    }
    // Detecta resistência por AMRAP (subtitle ou items)
    if (subtitleUpper.contains('AMRAP') || fullText.contains('AMRAP')) {
      stimuli.add('Resistência');
    }
    // Detecta cardio por corrida/remo/bike
    if (fullText.contains('RUN') ||
        fullText.contains('ROW') ||
        fullText.contains('BIKE')) {
      stimuli.add('Cardio');
    }
    if (stimuli.isEmpty) stimuli.add('Geral');

    final String obj =
        mainBlock.subtitle.isNotEmpty ? mainBlock.subtitle : mainBlock.title;

    return DailyWorkoutSummary(
      category: category,
      stimuli: stimuli.take(2).toList(),
      objectiveShort: obj,
      quote: 'Killing the Gods',
    );
  }

  // ===========================================================================
  // 5. MÉTODOS LEGADOS (COMPATIBILIDADE)
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

      print('🔍 [SERVICE] Listando documentos do dia: $dataFormatada');

      final snapshot =
          await collection
              .where('dataTreinoIso', isEqualTo: dataFormatada)
              .get();

      if (snapshot.docs.isEmpty) return {};

      final Map<String, TrainingBlock?> result = {};

      for (var doc in snapshot.docs) {
        final docData = doc.data();
        final docId = doc.id;

        if (docData['partes'] != null && docData['partes'] is Map) {
          final Map<String, dynamic> partes = Map<String, dynamic>.from(
            docData['partes'],
          );

          final String mainKey = partes.keys.firstWhere(
            (k) => k.contains('WOD'),
            orElse: () => partes.keys.first,
          );

          final mainPart = Map<String, dynamic>.from(partes[mainKey]);

          // Suporta schema antigo ('nomeWod') e novo ('nomeWod') — mesma chave
          final String title = mainPart['nomeWod']?.toString() ?? mainKey;

          // Subtitle precisa conter a SEÇÃO (ex: "WOD") para o filtro da
          // CoachRegisteredTrainingsSection funcionar — ela usa
          // block.subtitle.contains("WOD") para categorizar os cards.
          //
          // Schema novo: 'secao' = "WOD", 'modalidade' = "3 ROUNDS FOR TIME"
          //   → subtitle = "WOD • 3 ROUNDS FOR TIME"
          // Schema antigo: 'tipo' = "WOD" (já continha a seção)
          //   → subtitle = "WOD"
          final String secao = mainPart['secao']?.toString() ?? mainKey;
          final String? modalidade =
              mainPart['modalidade']?.toString() ??
              mainPart['tipo']?.toString();
          final String subtitle =
              (modalidade != null && modalidade.isNotEmpty)
                  ? '$secao • $modalidade'
                  : secao;

          // Exercícios: extrai 'raw' se for Map, usa direto se for String
          final List<String> items = [];
          if (mainPart['exercicios'] != null) {
            for (final e in mainPart['exercicios']) {
              if (e is String) {
                items.add(e);
              } else if (e is Map) {
                final raw = e['raw']?.toString() ?? e['nome']?.toString() ?? '';
                if (raw.isNotEmpty) items.add(raw);
              }
            }
          }

          result[docId] = TrainingBlock(
            id: docId,
            title: title,
            subtitle: subtitle,
            items: items,
          );
        }
      }

      print('✅ [SERVICE] Cards gerados: ${result.length}');
      return result;
    } catch (e) {
      print('❌ [SERVICE ERROR]: $e');
      return {};
    }
  }

  static TrainingBlock _mapPartToTrainingBlock(
    String keyId,
    Map<String, dynamic> data,
    String originalDocId,
  ) {
    // Exercícios: suporta schema antigo (String) e novo (Map)
    final List<String> items = [];
    if (data['exercicios'] != null) {
      for (final e in data['exercicios']) {
        if (e is String) {
          items.add(e);
        } else if (e is Map) {
          final raw = e['raw']?.toString() ?? e['nome']?.toString() ?? '';
          if (raw.isNotEmpty) items.add(raw);
        }
      }
    }

    // Subtitle: schema novo usa 'modalidade', antigo usa 'tipo'
    final String tipoRaw =
        data['modalidade']?.toString().toUpperCase() ??
        data['tipo']?.toString().toUpperCase() ??
        keyId.toUpperCase();

    String subtitle = tipoRaw;
    if (data['duracaoMinutos'] != null) {
      subtitle += ' • ${data['duracaoMinutos']} min';
    }

    final String title =
        (data['nomeWod'] != null &&
                data['nomeWod'].toString().trim().isNotEmpty)
            ? data['nomeWod'].toString()
            : keyId;

    return TrainingBlock(
      id: '${originalDocId}__${keyId}',
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
      if (block.id.contains('WOD'))
        resultMap['WOD'] = block;
      else if (block.id.contains('LPO'))
        resultMap['LPO'] = block;
      else
        resultMap[block.title] = block;
    }

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
  // 6. MOCKS E AUXILIARES
  // ===========================================================================

  static Future<List<Box>> fetchUserBoxes() async {
    // App testado com um único box por enquanto.
    // Quando o vínculo atleta↔box for implementado no Firestore,
    // este método lerá users/{uid}/boxId ou equivalente.
    return [Box(id: 'BOX_PRINCIPAL', name: 'CrossFit Box')];
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
// EXTENSIONS (mantidas inalteradas)
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
  static Future<int> fetchResultsCountForDate(DateTime date) async => 15;

  static Future<double> fetchDailyAttendanceRate(DateTime date) async => 83.0;
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
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('cycles').get();

      final String targetYear = year.toString();
      final List<int> months = [];

      for (var doc in querySnapshot.docs) {
        final docId = doc.id;
        if (docId.endsWith(targetYear)) {
          final parts = docId.split('-');
          if (parts.isNotEmpty) {
            final monthInt = int.tryParse(parts[0]);
            if (monthInt != null) months.add(monthInt);
          }
        }
      }

      months.sort();
      return months.toSet().toList();
    } catch (e) {
      print('Erro ao buscar meses do ciclo: $e');
      return [];
    }
  }

  static Future<DateTime?> fetchCurrentCycleMonth({
    required String boxId,
  }) async {
    try {
      final now = DateTime.now();
      final currentDocId =
          '${now.month.toString().padLeft(2, '0')}-${now.year}';

      final doc =
          await FirebaseFirestore.instance
              .collection('cycles')
              .doc(currentDocId)
              .get();
      if (doc.exists) return DateTime(now.year, now.month);

      final querySnapshot =
          await FirebaseFirestore.instance.collection('cycles').get();
      if (querySnapshot.docs.isEmpty) return null;

      final List<DateTime> dates = [];
      for (var doc in querySnapshot.docs) {
        final parts = doc.id.split('-');
        if (parts.length == 2) {
          final m = int.tryParse(parts[0]);
          final y = int.tryParse(parts[1]);
          if (m != null && y != null) dates.add(DateTime(y, m));
        }
      }

      if (dates.isEmpty) return null;
      dates.sort((a, b) => a.compareTo(b));
      return dates.last;
    } catch (e) {
      print('Erro ao buscar ciclo atual: $e');
      return null;
    }
  }

  static Future<bool> isCycleRegistered({
    required String boxId,
    required int year,
    required int month,
  }) async {
    try {
      final docId = '${month.toString().padLeft(2, '0')}-$year';
      final doc =
          await FirebaseFirestore.instance
              .collection('cycles')
              .doc(docId)
              .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
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
