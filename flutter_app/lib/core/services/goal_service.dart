// lib/core/services/goal_service.dart
import 'package:flutter_app/shared/widgets/goal_card_widget.dart'; // para Goal

/// Situação de cada meta: sugerida, em andamento ou concluída.
enum GoalStatus { suggested, inProgress, completed }

/// Origem da meta na lista do usuário.
enum GoalOrigin { user, system }

/// Modelo de uma meta (Goal).
class Goal {
  final String id;
  final String title;
  final int deadlineWeeks;
  final DateTime startDate;
  final int unitsPerWeek;
  final int completedUnits;
  final String badgeAsset;
  final GoalStatus status;
  final GoalOrigin origin; // <- NOVO

  Goal({
    required this.id,
    required this.title,
    required this.deadlineWeeks,
    required this.startDate,
    required this.unitsPerWeek,
    required this.completedUnits,
    required this.badgeAsset,
    required this.status,
    this.origin = GoalOrigin.user, // <- default
  });

  int get elapsedWeeks => DateTime.now().difference(startDate).inDays ~/ 7;
  int get totalUnits => deadlineWeeks * unitsPerWeek;
  double get progress => totalUnits == 0 ? 0.0 : completedUnits / totalUnits;
  bool get isCompleted => completedUnits >= totalUnits;

  Goal copyWith({
    String? id,
    String? title,
    int? deadlineWeeks,
    DateTime? startDate,
    int? unitsPerWeek,
    int? completedUnits,
    String? badgeAsset,
    GoalStatus? status,
    GoalOrigin? origin,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      deadlineWeeks: deadlineWeeks ?? this.deadlineWeeks,
      startDate: startDate ?? this.startDate,
      unitsPerWeek: unitsPerWeek ?? this.unitsPerWeek,
      completedUnits: completedUnits ?? this.completedUnits,
      badgeAsset: badgeAsset ?? this.badgeAsset,
      status: status ?? this.status,
      origin: origin ?? this.origin,
    );
  }
}

/// Serviço responsável pelas metas.
/// Mock com cache em memória para permitir criar/deletar.
class GoalService {
  static String _badgeFor(String goalId) {
    switch (goalId) {
      case 'goal1':
        return 'assets/icons/goal1.png';
      case 'goal2':
        return 'assets/icons/goal2.png';
      case 'goal3':
        return 'assets/icons/goal3.png';
      default:
        return 'assets/icons/goal1.png';
    }
  }

  // ====== CACHE ======
  static List<Goal>? _userGoals; // todas as metas do usuário (user + system)

  static void _ensureSeeded() {
    if (_userGoals != null) return;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

    final seed = <Goal>[
      Goal(
        id: 'goal1',
        title: 'Registrar 2 treinos por semana',
        deadlineWeeks: 3,
        startDate: weekAgo,
        unitsPerWeek: 2,
        completedUnits: 5,
        badgeAsset: _badgeFor('goal1'),
        status: GoalStatus.inProgress,
        origin: GoalOrigin.user,
      ),
      Goal(
        id: 'goal2',
        title: 'Treinar 3 vezes por semana',
        deadlineWeeks: 6,
        startDate: twoWeeksAgo,
        unitsPerWeek: 3,
        completedUnits: 18,
        badgeAsset: _badgeFor('goal2'),
        status: GoalStatus.inProgress,
        origin: GoalOrigin.system, // <- simulamos uma vinda do sistema
      ),
      Goal(
        id: 'goal3',
        title: 'Treinar 4 vezes por semana',
        deadlineWeeks: 6,
        startDate: twoWeeksAgo,
        unitsPerWeek: 3,
        completedUnits: 17,
        badgeAsset: _badgeFor('goal3'),
        status: GoalStatus.inProgress,
        origin: GoalOrigin.user,
      ),
    ];

    // ajusta completed status
    _userGoals =
        seed
            .map(
              (g) => g.copyWith(
                status:
                    g.completedUnits >= g.totalUnits
                        ? GoalStatus.completed
                        : GoalStatus.inProgress,
              ),
            )
            .toList();
  }

  // ====== SUGESTÕES (fora da lista do usuário) ======
  static Future<List<Goal>> fetchSuggestedGoals() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final now = DateTime.now();
    return [
      Goal(
        id: 'sugg1',
        title: 'Registrar 2 treinos por semana',
        deadlineWeeks: 3,
        startDate: now,
        unitsPerWeek: 2,
        completedUnits: 0,
        badgeAsset: _badgeFor('goal1'),
        status: GoalStatus.suggested,
      ),
      Goal(
        id: 'sugg2',
        title: 'Treinar 3 vezes por semana',
        deadlineWeeks: 6,
        startDate: now,
        unitsPerWeek: 3,
        completedUnits: 0,
        badgeAsset: _badgeFor('goal2'),
        status: GoalStatus.suggested,
      ),
      Goal(
        id: 'sugg3',
        title: 'Treinar 4 vezes por semana',
        deadlineWeeks: 6,
        startDate: now,
        unitsPerWeek: 4,
        completedUnits: 0,
        badgeAsset: _badgeFor('goal3'),
        status: GoalStatus.suggested,
      ),
    ];
  }

  // ====== LISTAS DO USUÁRIO ======
  static Future<List<Goal>> fetchUserGoals() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ensureSeeded();
    // copia defensiva
    return List<Goal>.from(_userGoals!);
  }

  static Future<List<Goal>> fetchActiveUserGoals() async {
    final all = await fetchUserGoals();
    return all.where((g) => g.status == GoalStatus.inProgress).toList();
  }

  static Future<List<Goal>> fetchCompletedUserGoals() async {
    final all = await fetchUserGoals();
    return all.where((g) => g.status == GoalStatus.completed).toList();
  }

  static Future<List<Goal>> fetchUserSystemGoals() async {
    final all = await fetchUserGoals();
    return all.where((g) => g.origin == GoalOrigin.system).toList();
  }

  static Future<List<String>> fetchCompletedBadges({bool dedupe = true}) async {
    final completed = await fetchCompletedUserGoals();
    final assets = completed.map((g) => g.badgeAsset);
    return dedupe ? assets.toSet().toList() : assets.toList();
  }

  static Future<List<Goal>> fetchNearCompleteGoals({
    double minProgress = 0.8,
  }) async {
    final all = await fetchActiveUserGoals();
    return all.where((g) => g.progress >= minProgress).toList();
  }

  static Future<bool> fetchShowNearCompleteSection() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true;
  }

  // ====== Helpers de título ======
  static String generatePrTitle({
    required String? discipline,
    required String? movement,
    required String? targetValue,
    required String unit, // ignorado para Endurance
  }) {
    final d = (discipline ?? '').trim();
    final m = (movement ?? '').trim();
    final t = (targetValue ?? '').trim();
    if (d.isEmpty || m.isEmpty || t.isEmpty) return 'PR';
    switch (d) {
      case 'LPO':
        return 'Aumentar o PR de $m em ${t}kg';
      case 'Ginástica':
        return 'Aumentar o volume de $m para $t reps unbroken';
      case 'Endurance':
        return 'Atingir $t $m por minuto';
      default:
        return 'PR $d $m $t';
    }
  }

  static Future<List<String>> fetchPrMovements(String discipline) async {
    await Future.delayed(const Duration(milliseconds: 150));
    switch (discipline) {
      case 'LPO':
        return [
          'Snatch',
          'Clean & Jerk',
          'Clean',
          'Jerk',
          'Back Squat',
          'Front Squat',
          'Deadlift',
        ];
      case 'Ginástica':
        return [
          'Pull-up',
          'Chest-to-bar',
          'Bar muscle-up',
          'Ring muscle-up',
          'Handstand Push-up',
          'Toes-to-bar',
          'Pistol',
        ];
      case 'Endurance':
        return ['Burpees', 'Corrida', 'Remo', 'Bike', 'Ski'];
      default:
        return const [];
    }
  }

  static String generateFrequencyTitle({
    required String action,
    required int quantity,
    required String period,
  }) {
    final q = quantity < 1 ? 1 : quantity;
    final per = period == 'mês' ? 'por mês' : 'por semana';
    return '$action $q $per';
  }

  // ====== CRUD mock ======
  static Future<String> createGoal(CreateGoalRequest req) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _ensureSeeded();

    final newId = 'goal_${DateTime.now().millisecondsSinceEpoch}';
    // heurística simples para preencher campos
    final isFreq = (req.metadata['preset'] == 'frequency');
    final qty = (req.metadata['quantity'] as int?) ?? 1;

    final newGoal = Goal(
      id: newId,
      title: req.title,
      deadlineWeeks: req.noDeadline ? 12 : 6,
      startDate: req.startDate,
      unitsPerWeek: isFreq ? qty : 1,
      completedUnits: 0,
      badgeAsset: _badgeFor('goal1'),
      status: GoalStatus.inProgress,
      origin: GoalOrigin.user,
    );

    // Insere no TOPO para aparecer primeiro
    _userGoals!.insert(0, newGoal);
    return newId;
  }

  static Future<void> deleteGoal(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ensureSeeded();
    _userGoals!.removeWhere((g) => g.id == id);
  }

  /// Quando o usuário adiciona uma sugestão (+), criamos uma meta com origem `system`.
  static Future<String> addSuggestedGoalToUser(Goal suggested) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _ensureSeeded();
    final newId =
        'goal_from_${suggested.id}_${DateTime.now().millisecondsSinceEpoch}';
    final newGoal = suggested.copyWith(
      id: newId,
      status: GoalStatus.inProgress,
      origin: GoalOrigin.system,
      startDate: DateTime.now(),
      completedUnits: 0,
    );
    _userGoals!.insert(0, newGoal);
    return newId;
  }
}

class CreateGoalRequest {
  final DateTime startDate;
  final DateTime? endDate;
  final bool noDeadline;
  final String title;
  final Map<String, dynamic> metadata;

  CreateGoalRequest({
    required this.startDate,
    this.endDate,
    required this.noDeadline,
    required this.title,
    required this.metadata,
  });
}
