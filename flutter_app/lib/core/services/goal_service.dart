// lib/core/services/goal_service.dart

import 'package:flutter_app/shared/widgets/goal_card_widget.dart'; // para Goal

/// Situação de cada meta: sugerida, em andamento ou concluída.
enum GoalStatus { suggested, inProgress, completed }

/// Modelo de uma meta (Goal) com todos os atributos necessários,
/// incluindo badgeAsset e status para diferenciar sugestões vs cadastradas.
class Goal {
  /// Identificador único da meta.
  final String id;

  /// Título legível da meta.
  final String title;

  /// Prazo em semanas para conclusão da meta.
  final int deadlineWeeks;

  /// Data em que a meta foi iniciada (usada para calcular elapsedWeeks).
  final DateTime startDate;

  /// Quantas unidades (ex.: treinos) por semana o usuário deve cumprir.
  final int unitsPerWeek;

  /// Quantas unidades já foram completadas até agora.
  final int completedUnits;

  /// Caminho para o badge (hexágono + ícone) ligado a esta meta.
  final String badgeAsset;

  /// Se é sugestão ou meta do usuário (e se concluída ou não).
  final GoalStatus status;

  Goal({
    required this.id,
    required this.title,
    required this.deadlineWeeks,
    required this.startDate,
    required this.unitsPerWeek,
    required this.completedUnits,
    required this.badgeAsset,
    required this.status,
  });

  /// Calcula quantas semanas já se passaram desde [startDate].
  int get elapsedWeeks => DateTime.now().difference(startDate).inDays ~/ 7;

  /// Total de unidades necessárias para cumprir a meta.
  int get totalUnits => deadlineWeeks * unitsPerWeek;

  /// Percentual de conclusão (0.0 a 1.0).
  double get progress => totalUnits == 0 ? 0.0 : completedUnits / totalUnits;

  /// Se já atingiu ou ultrapassou a meta
  bool get isCompleted => completedUnits >= totalUnits;
}

/// Serviço responsável por fornecer sugestões e metas do usuário.
/// TODO: Substituir mocks por chamadas reais ao backend.
class GoalService {
  /// Mapeia cada `goalId` para o caminho do asset do badge.
  static String _badgeFor(String goalId) {
    switch (goalId) {
      case 'goal1':
        return 'assets/icons/goal1.png';
      case 'goal2':
        return 'assets/icons/goal2.png';
      default:
        return 'assets/icons/goal1.png';
    }
  }

  /// Retorna a lista de metas **sugeridas** para o usuário.
  /// status = suggested.
  static Future<List<Goal>> fetchSuggestedGoals() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    return [
      Goal(
        id: 'goal1',
        title: 'Registrar 2 treinos por semana',
        deadlineWeeks: 3,
        startDate: now,
        unitsPerWeek: 2,
        completedUnits: 0,
        badgeAsset: _badgeFor('goal1'),
        status: GoalStatus.suggested,
      ),
      Goal(
        id: 'goal2',
        title: 'Treinar 3 vezes por semana',
        deadlineWeeks: 6,
        startDate: now,
        unitsPerWeek: 3,
        completedUnits: 0,
        badgeAsset: _badgeFor('goal2'),
        status: GoalStatus.suggested,
      ),
    ];
  }

  /// Retorna TODAS as metas **cadastradas** do usuário (em andamento ou concluídas).
  static Future<List<Goal>> fetchUserGoals() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

    final raw = [
      Goal(
        id: 'goal1',
        title: 'Registrar 2 treinos por semana',
        deadlineWeeks: 3,
        startDate: weekAgo,
        unitsPerWeek: 2,
        completedUnits: 1, // 1/6 concluído
        badgeAsset: _badgeFor('goal1'),
        status: GoalStatus.inProgress, // será ajustado abaixo
      ),
      Goal(
        id: 'goal2',
        title: 'Treinar 3 vezes por semana',
        deadlineWeeks: 6,
        startDate: twoWeeksAgo,
        unitsPerWeek: 3,
        completedUnits: 17,
        badgeAsset: _badgeFor('goal2'),
        status: GoalStatus.inProgress, // será ajustado abaixo
      ),
    ];

    // Ajusta status: inProgress vs completed
    return raw.map((g) {
      final isDone = g.completedUnits >= g.totalUnits;
      return Goal(
        id: g.id,
        title: g.title,
        deadlineWeeks: g.deadlineWeeks,
        startDate: g.startDate,
        unitsPerWeek: g.unitsPerWeek,
        completedUnits: g.completedUnits,
        badgeAsset: g.badgeAsset,
        status: isDone ? GoalStatus.completed : GoalStatus.inProgress,
      );
    }).toList();
  }

  /// Retorna apenas as metas **em andamento** (status = inProgress).
  static Future<List<Goal>> fetchActiveUserGoals() async {
    final all = await fetchUserGoals();
    return all.where((g) => g.status == GoalStatus.inProgress).toList();
  }

  /// Retorna apenas as metas **já concluídas** (status = completed).
  static Future<List<Goal>> fetchCompletedUserGoals() async {
    final all = await fetchUserGoals();
    return all.where((g) => g.status == GoalStatus.completed).toList();
  }
}
