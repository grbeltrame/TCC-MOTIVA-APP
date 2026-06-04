
/// Resultado registrado por um aluno em uma turma específica (dia/horário).
class AthleteResult {
  final String athleteId;
  final String athleteName;
  final String category; // Iniciante | Scale | Intermediário | RX
  final bool completed; // Concluiu?
  final bool adapted; // Adaptou?
  final String wodType; // 'AMRAP' | 'For time' | 'EMOM' | ...
  final int? amrapRounds;
  final int? amrapReps;
  final int? forTimeSec;
  final int effort; // 1..10

  AthleteResult({
    required this.athleteId,
    required this.athleteName,
    required this.category,
    required this.completed,
    required this.adapted,
    required this.wodType,
    this.amrapRounds,
    this.amrapReps,
    this.forTimeSec,
    required this.effort,
  });
}
