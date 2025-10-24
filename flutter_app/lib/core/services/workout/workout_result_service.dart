import 'dart:async';
import 'package:flutter_app/core/services/workout/movement_service.dart';
import 'package:flutter_app/shared/models/athlete_result.dart';

/// Model da turma (classe) do dia.
class ClassSlot {
  final String id;
  final DateTime startAt; // apenas para formatar a hora
  final String type; // WOD, LPO, Ginástica, Endurance

  ClassSlot({required this.id, required this.startAt, required this.type});

  String label24() {
    final h = startAt.hour.toString().padLeft(2, '0');
    final m = startAt.minute.toString().padLeft(2, '0');
    return '$h:$m - $type';
  }
}

/// Service responsável por suprir dados do formulário de resultado.
/// TODO(back): ligar com endpoints reais e preferências do usuário.
class WorkoutResultService {
  /// Categorias possíveis do aluno (iniciante → RX).
  static Future<List<String>> fetchUserCategories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    // TODO(back): vir do backend (ou do perfil do usuário)
    return ['Iniciante', 'Scale', 'Intermediário', 'RX'];
  }

  /// Categoria padrão do usuário (cadastrada no perfil).
  static Future<String> fetchDefaultUserCategory() async {
    await Future.delayed(const Duration(milliseconds: 120));
    // TODO(back): retornar do perfil do usuário logado
    return 'Intermediário';
  }

  /// Turmas do dia (horário + tipo).
  static Future<List<ClassSlot>> fetchClassesForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO(back): retornar apenas turmas do box do usuário e da data
    final day = DateTime(date.year, date.month, date.day);
    return [
      ClassSlot(
        id: 'c1',
        startAt: day.add(const Duration(hours: 6)),
        type: 'WOD',
      ),
      ClassSlot(
        id: 'c2',
        startAt: day.add(const Duration(hours: 8)),
        type: 'LPO',
      ),
      ClassSlot(
        id: 'c3',
        startAt: day.add(const Duration(hours: 18)),
        type: 'Ginástica',
      ),
      ClassSlot(
        id: 'c4',
        startAt: day.add(const Duration(hours: 19)),
        type: 'Endurance',
      ),
    ];
  }

  /// Retorna a turma (ClassSlot) do [date] com o [classId]; null se não encontrar.
  static Future<ClassSlot?> fetchClassByIdOnDate(
    String classId,
    DateTime date,
  ) async {
    final classes = await fetchClassesForDate(date);
    try {
      return classes.firstWhere((c) => c.id == classId);
    } catch (_) {
      return null;
    }
  }

  /// Tipos de workout (estrutura da sessão).
  static Future<List<String>> fetchWorkoutTypes() async {
    await Future.delayed(const Duration(milliseconds: 120));
    // TODO(back): caso venha do treino do dia, usar o do treino. Aqui é catálogo.
    return ['EMOM', 'AMRAP', 'For time'];
  }

  // ===== Delegadores p/ MovementService =====
  static Future<List<MovementPreset>> fetchMovementsForClass(String classId) {
    return MovementService.fetchMovementsForClass(classId);
  }

  static Future<List<String>> searchMovementSuggestions(String query) {
    return MovementService.searchMovementSuggestions(query);
  }

  /// ===== NOVO: busca o resultado preenchido pelo coach para a turma/data
  static Future<CoachFilledResult> fetchCoachFilledResult({
    required String classId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 180));
    // TODO(back): GET /class/{classId}/result?date=...
    // Mock: AMRAP 5 rounds + 12 reps
    return CoachFilledResult(
      category: 'RX',
      adapted: false,
      completed: true,
      classId: classId,
      wodType: 'AMRAP',
      amrapRounds: 5,
      amrapReps: 12,
    );
  }

  /// ===== NOVO: envia as adaptações do aluno para a turma/data
  static Future<void> submitAdaptationsForTraining({
    required String classId,
    required DateTime date,
    required List<MovementPreset> movements, // ou um DTO próprio, se preferir
  }) async {
    await Future.delayed(const Duration(milliseconds: 240));
    // TODO(back): POST /results/adaptations { classId, date, movements[] }
    // movements pode ser serializado com qty/load/time/name
  }

  /// Quais tipos de treino existiram no dia (deduzidos pelas turmas do dia).
  static Future<List<String>> fetchCategoriesForDate(DateTime date) async {
    final classes = await fetchClassesForDate(date);
    final set = classes.map((c) => c.type).toSet().toList();
    set.sort(); // opcional
    return set;
  }

  /// Resultados dos alunos. Se [classId] vier nulo → todos os horários daquele dia.
  /// Se [category] vier nulo → todas as categorias válidas para o filtro aplicado.
  static Future<List<AthleteResult>> fetchAthleteResults({
    required DateTime date,
    String? classId,
    String? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 220));
    // TODO(back): GET /results?date=...&classId=...&category=...

    // ----- MOCK DINÂMICO -----
    // Se não tem aula do tipo no dia → retorna vazio mesmo.
    final classes = await fetchClassesForDate(date);
    final validCategories = classes.map((e) => e.type).toSet();

    if (category != null && !validCategories.contains(category)) {
      return <AthleteResult>[];
    }

    // Se classId foi informado, restringe ao tipo da turma.
    String? categoryFromClass;
    if (classId != null) {
      final slot = classes.where((c) => c.id == classId).toList();
      if (slot.isEmpty) return <AthleteResult>[];
      categoryFromClass = slot.first.type;
      if (category != null && category != categoryFromClass) {
        // tipo pedido não bate com a turma selecionada
        return <AthleteResult>[];
      }
    }

    final chosenCategory = categoryFromClass ?? category;
    // Se nada foi escolhido, apenas retornamos alguns mocks variados, por categoria.
    final pool = <AthleteResult>[
      AthleteResult(
        athleteId: 'u1',
        athleteName: 'Ana Souza',
        category: 'Intermediário',
        completed: true,
        adapted: false,
        wodType: 'For time',
        forTimeSec: 9 * 60 + 42,
        effort: 8,
      ),
      AthleteResult(
        athleteId: 'u2',
        athleteName: 'Bruno Lima',
        category: 'RX',
        completed: true,
        adapted: false,
        wodType: 'AMRAP',
        amrapRounds: 7,
        amrapReps: 15,
        effort: 9,
      ),
      AthleteResult(
        athleteId: 'u3',
        athleteName: 'Camila Dias',
        category: 'Scale',
        completed: true,
        adapted: true,
        wodType: 'For time',
        forTimeSec: 12 * 60 + 5,
        effort: 7,
      ),
      AthleteResult(
        athleteId: 'u4',
        athleteName: 'Diego Nunes',
        category: 'Iniciante',
        completed: false,
        adapted: true,
        wodType: 'AMRAP',
        amrapRounds: 3,
        amrapReps: 20,
        effort: 6,
      ),
    ];

    // Pequena regra: se filtrar por WOD/LPO/Ginástica/Endurance, faz subset
    // (aqui é mock, então só reduz a lista para parecer real).
    List<AthleteResult> filtered = pool;
    if (chosenCategory != null) {
      if (chosenCategory == 'WOD') {
        filtered =
            pool.where((r) => r.wodType.toLowerCase() != 'emom').toList();
      } else if (chosenCategory == 'LPO') {
        filtered = pool.where((r) => r.adapted == true).toList();
      } else if (chosenCategory == 'Ginástica') {
        filtered = pool.where((r) => r.completed == true).toList();
      } else if (chosenCategory == 'Endurance') {
        filtered = pool.where((r) => r.effort >= 7).toList();
      }
    }

    // Ordenação por nome A→Z
    filtered.sort((a, b) => a.athleteName.compareTo(b.athleteName));
    return filtered;
  }
}

class CoachFilledResult {
  final String category;
  final bool adapted; // 'Sim'|'Não' -> true/false
  final bool completed; // 'Sim'|'Não' -> true/false
  final String classId; // turma
  final String wodType; // 'EMOM' | 'AMRAP' | 'For time'
  final int? amrapRounds; // se AMRAP
  final int? amrapReps; // se AMRAP
  final int? forTimeSec; // se For time

  CoachFilledResult({
    required this.category,
    required this.adapted,
    required this.completed,
    required this.classId,
    required this.wodType,
    this.amrapRounds,
    this.amrapReps,
    this.forTimeSec,
  });
}
