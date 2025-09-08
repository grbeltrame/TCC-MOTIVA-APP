/// Modelo enxuto para a lista de turmas do dia.
class DayClass {
  final String id;
  final String timeLabel; // ex.: "07:00"
  final String category; // 'WOD' | 'LPO' | 'Ginastica' | 'Endurance' (mock)
  final String coachName;

  DayClass({
    required this.id,
    required this.timeLabel,
    required this.category,
    required this.coachName,
  });
}

/// Modelo do interesse do aluno em uma turma de um dia.
class InterestedClass {
  final String classId;
  final DateTime date; // considerar apenas ano-mês-dia
  final String category; // WOD | LPO | Ginastica | Endurance
  final String coachName;
  final String timeLabel; // "HH:mm"
  final DateTime createdAt; // p/ política de “até 2 por dia”

  InterestedClass({
    required this.classId,
    required this.date,
    required this.category,
    required this.coachName,
    required this.timeLabel,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
