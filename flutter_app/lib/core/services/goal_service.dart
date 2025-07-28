// lib/core/services/goal_service.dart

/// Modelo de uma meta (Goal) com todos os atributos necessários,
/// incluindo o asset do badge que será exibido no GoalCardWidget.
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

  Goal({
    required this.id,
    required this.title,
    required this.deadlineWeeks,
    required this.startDate,
    required this.unitsPerWeek,
    required this.completedUnits,
    required this.badgeAsset, // ← novo parâmetro
  });

  /// Calcula quantas semanas já se passaram desde [startDate].
  int get elapsedWeeks => DateTime.now().difference(startDate).inDays ~/ 7;

  /// Total de unidades necessárias para cumprir a meta.
  int get totalUnits => deadlineWeeks * unitsPerWeek;

  /// Percentual de conclusão (0.0 a 1.0).
  double get progress => totalUnits == 0 ? 0.0 : completedUnits / totalUnits;
}

class GoalService {
  /// Mapeia cada `goalId` para o caminho do asset do badge.
  /// TODO: talvez mover essa lógica para um repositório ou consultar no backend.
  static String _badgeFor(String goalId) {
    switch (goalId) {
      case 'goal1':
        return 'assets/icons/goal1.png';
      case 'goal2':
        return 'assets/icons/goal2.png';
      // TODO: adicionar novos casos conforme surgirem IDs de meta
      default:
        return 'assets/icons/goal1.png';
    }
  }

  /// Retorna o conjunto de IDs de metas que o usuário quer ver.
  /// TODO: trocar o retorno hardcoded por chamada ao backend / prefs.
  static Future<Set<String>> fetchEnabledSuggestedGoalIds() async {
    await Future.delayed(const Duration(milliseconds: 100));
    // por enquanto, usuário habilitou apenas a goal1; troque conforme necessidade
    return {'goal1', 'goal2'};
  }

  /// Retorna a lista de metas **sugeridas** para o usuário.
  /// Cada Goal já traz o `badgeAsset` correto.
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
        completedUnits: 0, // sempre zero para sugestões
        badgeAsset: _badgeFor('goal1'), // atribui o badge correto
      ),
      Goal(
        id: 'goal2',
        title: 'Treinar 3 vezes por semana',
        deadlineWeeks: 6,
        startDate: now,
        unitsPerWeek: 3,
        completedUnits: 0,
        badgeAsset: _badgeFor('goal2'),
      ),
    ];
  }

  /// Retorna a lista de metas **do usuário** (em andamento ou concluídas).
  /// Cada Goal já traz o `badgeAsset` correto.
  static Future<List<Goal>> fetchUserGoals() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

    return [
      Goal(
        id: 'goal1',
        title: 'Registrar 2 treinos por semana',
        deadlineWeeks: 3,
        startDate: weekAgo,
        unitsPerWeek: 2,
        completedUnits: 1, // 1/6 concluído na primeira semana
        badgeAsset: _badgeFor('goal1'),
      ),
      Goal(
        id: 'goal2',
        title: 'Treinar 3 vezes por semana',
        deadlineWeeks: 6,
        startDate: twoWeeksAgo,
        unitsPerWeek: 3,
        completedUnits: 4, // 4/18 unidades concluídas
        badgeAsset: _badgeFor('goal2'),
      ),
    ];
  }
}
