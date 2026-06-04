import 'dart:async';

class MovementPreset {
  final String id;
  final String name;
  final bool expectsQuantity;
  final bool expectsLoadKg;
  final bool expectsTimeSec;
  final int? presetQuantity;
  final double? presetLoadKg;
  final int? presetTimeSec;

  MovementPreset({
    required this.id,
    required this.name,
    required this.expectsQuantity,
    required this.expectsLoadKg,
    required this.expectsTimeSec,
    this.presetQuantity,
    this.presetLoadKg,
    this.presetTimeSec,
  });
}

class MovementService {
  /// TODO(back): conectar ao endpoint real de movimentos do treino da turma
  static Future<List<MovementPreset>> fetchMovementsForClass(
    String classId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 180));
    return [
      MovementPreset(
        id: 'm1',
        name: 'Thruster',
        expectsQuantity: true,
        expectsLoadKg: true,
        expectsTimeSec: false,
        presetQuantity: 21,
        presetLoadKg: 40.0,
      ),
      MovementPreset(
        id: 'm2',
        name: 'Pull-up',
        expectsQuantity: true,
        expectsLoadKg: false,
        expectsTimeSec: false,
        presetQuantity: 21,
      ),
      MovementPreset(
        id: 'm3',
        name: 'Plank',
        expectsQuantity: false,
        expectsLoadKg: false,
        expectsTimeSec: true,
        presetTimeSec: 60,
      ),
    ];
  }

  /// TODO(back): buscar catálogo de movimentos com filtro [query]
  static Future<List<String>> searchMovementSuggestions(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [];
  }
}
