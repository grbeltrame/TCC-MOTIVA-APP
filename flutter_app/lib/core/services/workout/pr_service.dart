import 'dart:async';
import 'dart:math';

import 'package:flutter_app/core/services/workout/movement_service.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';
import 'package:flutter_app/shared/models/inisght_model.dart';

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

/// Ponto genérico de série temporal (y = value)
class TimePoint {
  final DateTime date;
  final num value;
  const TimePoint(this.date, this.value);
}

/// Ponto de barras categóricas (para volume por movimento adaptado)
class MovementVolumePoint {
  final String movement;
  final num volume; // reps ou “unidades”
  const MovementVolumePoint(this.movement, this.volume);
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

  /// Encontra benchmark pelo nome “bonito” (ex.: "Fran")
  static Future<PrBenchmark?> findBenchmarkByName(String name) async {
    final list = await fetchBenchmarks();
    try {
      return list.firstWhere(
        (b) => b.name.toLowerCase().trim() == name.toLowerCase().trim(),
      );
    } catch (_) {
      return null;
    }
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
            id: '',
            name: 'Thruster',
            expectsQuantity: true,
            expectsLoadKg: true,
            expectsTimeSec: false,
            presetQuantity: 21,
            presetLoadKg: 40,
          ),
          MovementPreset(
            id: '',
            name: 'Pull-up',
            expectsQuantity: true,
            expectsLoadKg: false,
            expectsTimeSec: false,
            presetQuantity: 21,
          ),
        ];
      case 'grace':
        return [
          MovementPreset(
            id: '',
            name: 'Clean & Jerk',
            expectsQuantity: true,
            expectsLoadKg: true,
            expectsTimeSec: false,
            presetQuantity: 30,
            presetLoadKg: 60,
          ),
        ];
      default: // amrap12 (exemplo)
        return [
          MovementPreset(
            id: '',
            name: 'Chest-to-bar',
            expectsQuantity: true,
            expectsLoadKg: false,
            expectsTimeSec: false,
            presetQuantity: 8,
          ),
          MovementPreset(
            id: '',
            name: 'Thruster',
            expectsQuantity: true,
            expectsLoadKg: true,
            expectsTimeSec: false,
            presetQuantity: 10,
            presetLoadKg: 40,
          ),
        ];
    }
  }

  /// Descrição curtinha de um movimento (mock).
  /// TODO: substituir por backend (ex.: GET /movements/:name/description)
  static Future<String> fetchMovementDescription(String movementName) async {
    await Future.delayed(const Duration(milliseconds: 150));
    switch (movementName.toLowerCase()) {
      case 'snatch':
        return 'Levantar a barra do chão ao overhead num único movimento.';
      case 'clean & jerk':
        return 'Do chão aos ombros (clean) e depois ao overhead (jerk).';
      case 'pull-up':
        return 'Elevação até o queixo ultrapassar a barra.';
      case 'remo':
      case 'row':
        return 'Estímulo de cardio; mantenha o pace constante.';
      default:
        return 'Descrição breve do movimento e dicas técnicas.';
    }
  }

  /// “Descrição” do WOD: usamos linhas que compõem o treino (mock).
  /// TODO: backend por benchmark (ex.: GET /benchmarks/:code)
  static Future<List<String>> fetchWodLinesByName(String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final b = await findBenchmarkByName(name);
    if (b == null) return ['WOD “$name”'];
    switch (b.code) {
      case 'fran':
        return [
          '21 Thrusters 43kg',
          '21 Pull-ups',
          '15 Thrusters 43kg',
          '15 Pull-ups',
          '9 Thrusters 43kg',
          '9 Pull-ups',
        ];
      case 'grace':
        return ['30 Clean & Jerk 60kg (for time)'];
      default:
        return ['12 minutos AMRAP:', '8 Chest-to-bar', '10 Thrusters 40kg'];
    }
  }

  // ====== Séries de dados (apenas estética / mock) ======

  /// Série para movimentos (valor absoluto — kg ou reps dependendo do movimento).
  /// TODO: GET /prs/movement/:name/series?days=30
  static Future<List<TimePoint>> fetchMovementSeries(
    String movementName, {
    int days = 30,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();
    final rnd = Random(movementName.hashCode ^ days);
    final base = movementName.toLowerCase().contains('squat') ? 100 : 50;

    return List.generate(days, (i) {
      final date = now.subtract(Duration(days: days - 1 - i));
      final noise = rnd.nextDouble() * 6 - 3; // -3..+3
      final val = (base + i * 0.4 + noise);
      return TimePoint(date, val.clamp(0, 999));
    });
  }

  /// Série de tempos (em segundos) para WODs For Time.
  /// TODO: GET /prs/wod/:name/series/time
  static Future<List<TimePoint>> fetchWodTimeSeries(String wodName) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();
    final rnd = Random(wodName.hashCode);
    final start = 6 * 60; // 6:00
    return List.generate(16, (i) {
      final d = now.subtract(Duration(days: (16 - i) * 3));
      final noise = rnd.nextInt(40) - 20; // ±20s
      return TimePoint(d, (start + i * 5 + noise).clamp(180, 1200));
    });
  }

  /// Série de reps totais para WODs AMRAP.
  /// TODO: GET /prs/wod/:name/series/reps
  static Future<List<TimePoint>> fetchWodRepsSeries(String wodName) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();
    final rnd = Random(wodName.hashCode ^ 123);
    return List.generate(14, (i) {
      final d = now.subtract(Duration(days: (14 - i) * 4));
      final val = 100 + i * 3 + rnd.nextInt(8) - 4;
      return TimePoint(d, val.clamp(40, 300));
    });
  }

  /// Série de carga usada (kg) no WOD (pico ou média por sessão).
  /// TODO: GET /prs/wod/:name/series/loadKg
  static Future<List<TimePoint>> fetchWodLoadSeries(String wodName) async {
    await Future.delayed(const Duration(milliseconds: 220));
    final now = DateTime.now();
    final rnd = Random(wodName.hashCode ^ 321);
    return List.generate(12, (i) {
      final d = now.subtract(Duration(days: (12 - i) * 5));
      final val = 40 + i * 2 + rnd.nextInt(6) - 3;
      return TimePoint(d, val.clamp(20, 200));
    });
  }

  /// Volume por movimento adaptado (apenas barras categóricas do último treino).
  /// TODO: GET /prs/wod/:name/last/adapted-volume
  static Future<List<MovementVolumePoint>> fetchWodAdaptedVolume(
    String wodName,
  ) async {
    await Future.delayed(const Duration(milliseconds: 180));
    // mock: nem sempre há adaptações
    if (wodName.toLowerCase().contains('grace')) return [];
    return const [
      MovementVolumePoint('Chest-to-bar', 48),
      MovementVolumePoint('Thruster', 60),
      MovementVolumePoint('Burpees', 30),
    ];
  }

  /// Insights sobre um PR específico (mock).
  /// TODO: GET /prs/insights?category=...&label=...
  static Future<List<InsightsModel>> fetchPrInsights({
    required PrCategory category,
    required String label,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return [
      InsightsModel(
        type: 'athlete_performance',
        message:
            'Sua média recente em $label melhorou nas últimas 3 sessões. '
            'Considere aumentar 2.5 kg na próxima tentativa.',
      ),
      InsightsModel(
        type: 'athlete_performance',
        message:
            'Nos dias em que treina mais cedo, seus resultados de $label '
            'ficam ~5% melhores.',
      ),
    ];
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
    // TODO: POST real
  }
}
