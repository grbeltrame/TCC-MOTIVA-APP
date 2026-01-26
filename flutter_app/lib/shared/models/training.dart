/// Representa um treino individual.
class Training {
  final String id;
  final String title;
  final String? description; // Alterado para aceitar nulo (opcional)
  final DateTime date;

  // NOVO CAMPO: Guarda a estrutura do JSON (WOD, Skill, LPO, etc)
  final Map<String, dynamic> partes;

  Training({
    required this.id,
    required this.title,
    this.description, // Agora é opcional
    required this.date,
    this.partes =
        const {}, // Valor padrão vazio para não quebrar códigos antigos
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
