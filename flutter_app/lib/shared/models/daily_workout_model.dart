// lib/shared/models/daily_workout_model.dart

class DailyWorkoutModel {
  final String boxId;
  final String dateText; // "01 DEZEMBRO"
  final String weekDay;  // "SEGUNDA FEIRA"
  final Map<String, WorkoutPart> parts; // Onde ficam WOD, SKILL, etc.

  DailyWorkoutModel({
    required this.boxId,
    required this.dateText,
    required this.weekDay,
    required this.parts,
  });

  factory DailyWorkoutModel.fromJson(Map<String, dynamic> json) {
    // Converte a seção "partes" do JSON em um Mapa de objetos Dart
    final partsMap = <String, WorkoutPart>{};
    
    if (json['partes'] != null) {
      (json['partes'] as Map<String, dynamic>).forEach((key, value) {
        partsMap[key] = WorkoutPart.fromJson(value);
      });
    }

    return DailyWorkoutModel(
      boxId: json['boxId'] ?? '',
      dateText: json['dataDoTreinoTexto'] ?? '',
      weekDay: json['diaDaSemana'] ?? '',
      parts: partsMap,
    );
  }
}

class WorkoutPart {
  final String type; // "WOD", "SKILL", "AMRAP"
  final String? wodName; // "KILLING THE GODS"
  final int? durationMinutes;
  final List<String> exercises;
  final String? observations;

  WorkoutPart({
    required this.type,
    this.wodName,
    this.durationMinutes,
    required this.exercises,
    this.observations,
  });

  factory WorkoutPart.fromJson(Map<String, dynamic> json) {
    return WorkoutPart(
      type: json['tipo'] ?? '',
      wodName: json['nomeWod'],
      durationMinutes: json['duracaoMinutos'],
      // Garante que é uma lista de Strings, mesmo se vier null
      exercises: (json['exercicios'] as List?)?.map((e) => e.toString()).toList() ?? [],
      observations: json['observacoes'],
    );
  }
}