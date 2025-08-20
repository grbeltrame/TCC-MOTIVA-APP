/// Representa um treino individual.
class Training {
  final String id;
  final String title;
  final String description;
  final DateTime date;

  Training({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });
}

/// Resumo de um treino para o card “resumo do dia”.
class DailyWorkoutSummary {
  final String category; // ex.: WOD, LPO, Ginastica, Endurance
  final List<String> stimuli; // ex.: ['Força', 'Cardio']
  final String objectiveShort; // texto curtíssimo
  final String quote; // frase motivacional

  DailyWorkoutSummary({
    required this.category,
    required this.stimuli,
    required this.objectiveShort,
    required this.quote,
  });
}
