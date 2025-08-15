// lib/core/services/pr_service.dart
import 'dart:async';
import 'package:flutter_app/core/services/workout/movement_service.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';

// ===== Enums e modelos =====
enum PrCategory { lpo, gym, endurance, wod }

enum PrWodType { forTime, amrap }

class PrBenchmark {
  final String code; // ex.: 'fran'
  final String name; // ex.: 'Fran'
  final PrWodType type;

  const PrBenchmark({
    required this.code,
    required this.name,
    required this.type,
  });

  @override
  bool operator ==(Object other) => other is PrBenchmark && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'PrBenchmark($code, $name, $type)';
}

class AdaptedMovement {
  final String name;
  final int? quantity; // reps/unidades
  final double? loadKg; // peso
  final int? timeSec; // tempo em segundos

  const AdaptedMovement({
    required this.name,
    this.quantity,
    this.loadKg,
    this.timeSec,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'loadKg': loadKg,
    'timeSec': timeSec,
  };
}

class PRService {
  /// Retorna o texto do último PR já formatado (mock).
  static Future<String?> fetchLastPRText() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return '74 kg Power Clean';
  }

  /// Movimentos para os dropdowns, por categoria (mock).
  static Future<List<String>> fetchMovements(PrCategory category) async {
    await Future.delayed(const Duration(milliseconds: 200));
    switch (category) {
      case PrCategory.lpo:
        return [
          'Snatch',
          'Power Snatch',
          'Clean & Jerk',
          'Power Clean',
          'Back Squat',
          'Front Squat',
          'Deadlift',
          'Jerk',
        ];
      case PrCategory.gym:
        return [
          'Pull-up',
          'Chest-to-bar',
          'Bar muscle-up',
          'Ring muscle-up',
          'Handstand Push-up',
          'Toes-to-bar',
          'Pistol',
          'Double Unders',
        ];
      case PrCategory.endurance:
        return ['Burpees', 'Corrida', 'Remo', 'Bike', 'Ski'];
      case PrCategory.wod:
        return const []; // WOD usa benchmarks
    }
  }

  /// Lista de Benchmarks (mock).
  static Future<List<PrBenchmark>> fetchBenchmarks() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return const [
      PrBenchmark(code: 'fran', name: 'Fran', type: PrWodType.forTime),
      PrBenchmark(code: 'grace', name: 'Grace', type: PrWodType.forTime),
      PrBenchmark(
        code: 'amrap12',
        name: 'AMRAP 12\' C2B + Thruster',
        type: PrWodType.amrap,
      ),
    ];
  }

  /// Movimentos de um benchmark (mock) – usados quando o usuário marca "Adaptações".
  /// Retorna MovementPreset (o mesmo usado no sheet de Registrar Resultado).
  static Future<List<MovementPreset>> fetchBenchmarkMovements(
    PrBenchmark benchmark,
  ) async {
    await Future.delayed(const Duration(milliseconds: 250));
    switch (benchmark.code) {
      case 'fran':
        // 21-15-9 Thrusters (40kg) + Pull-ups
        return [
          MovementPreset(
            name: 'Thruster',
            expectsQuantity: true,
            expectsLoadKg: true,
            expectsTimeSec: false,
            presetQuantity: 21,
            presetLoadKg: 40,
            id: '',
          ),
          MovementPreset(
            name: 'Pull-up',
            expectsQuantity: true,
            expectsLoadKg: false,
            expectsTimeSec: false,
            presetQuantity: 21,
            id: '',
          ),
        ];
      case 'grace':
        return [
          MovementPreset(
            name: 'Clean & Jerk',
            expectsQuantity: true,
            expectsLoadKg: true,
            expectsTimeSec: false,
            presetQuantity: 30,
            presetLoadKg: 60,
            id: '',
          ),
        ];
      default: // amrap12 (exemplo)
        return [
          MovementPreset(
            name: 'Chest-to-bar',
            expectsQuantity: true,
            expectsLoadKg: false,
            expectsTimeSec: false,
            presetQuantity: 8,
            id: '',
          ),
          MovementPreset(
            name: 'Thruster',
            expectsQuantity: true,
            expectsLoadKg: true,
            expectsTimeSec: false,
            presetQuantity: 10,
            presetLoadKg: 40,
            id: '',
          ),
        ];
    }
  }

  /// Submissão do PR (mock).
  static Future<void> submitPr({
    required PrCategory category,
    required DateTime date,
    String? movement,
    double? weightKg,
    int? reps,
    PrBenchmark? benchmark,
    bool adapted = false,
    PrWodType? wodType,
    int? timeSeconds,
    int? amrapRounds,
    int? amrapReps,
    List<AdaptedMovement> adaptations = const [],
    required int effort, // 1..10
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    // Aqui você faria o POST real.
    // print({
    //   'category': category,
    //   'date': date.toIso8601String(),
    //   'movement': movement,
    //   'weightKg': weightKg,
    //   'reps': reps,
    //   'benchmark': benchmark?.code,
    //   'adapted': adapted,
    //   'wodType': wodType,
    //   'timeSeconds': timeSeconds,
    //   'amrapRounds': amrapRounds,
    //   'amrapReps': amrapReps,
    //   'adaptations': adaptations.map((e) => e.toJson()).toList(),
    //   'effort': effort,
    // });
  }
}
