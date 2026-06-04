import 'dart:async';

enum AdaptationMode { forTime, amrap }

class AdaptationLine {
  final int? quantity; // ex.: 30
  final String movement; // ex.: "Pull-up"
  final double? loadKg; // ex.: 25.0
  const AdaptationLine({this.quantity, required this.movement, this.loadKg});
}

class AdaptationSuggestion {
  final AdaptationMode mode;
  final int? timeSec; // se forTime
  final int? amrapRounds; // se amrap
  final int? amrapReps; // se amrap
  final List<AdaptationLine> lines;

  const AdaptationSuggestion({
    required this.mode,
    this.timeSec,
    this.amrapRounds,
    this.amrapReps,
    required this.lines,
  });
}

/// TODO(back): substituir mocks por chamadas reais (classe/treino/perfil/histórico).
class AdaptationsService {
  Future<AdaptationSuggestion> fetchSuggestions({
    required String category, // "WOD", "LPO", "Ginastica", "Endurance"
    String? wodName,
    DateTime? date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (category == 'WOD') {
      // Mock WOD AMRAP com 3 linhas
      return const AdaptationSuggestion(
        mode: AdaptationMode.amrap,
        amrapRounds: 3,
        amrapReps: 5,
        lines: [
          AdaptationLine(quantity: 15, movement: 'Pull-up'),
          AdaptationLine(quantity: 40, movement: 'Single Unders'),
          AdaptationLine(quantity: 12, movement: 'Snatch', loadKg: 25),
        ],
      );
    }

    if (category == 'LPO') {
      // Mock LPO
      return const AdaptationSuggestion(
        mode: AdaptationMode.forTime,
        timeSec: null,
        lines: [
          AdaptationLine(quantity: 5, movement: 'Snatch', loadKg: 32.5),
          AdaptationLine(quantity: 5, movement: 'Snatch', loadKg: 32.5),
        ],
      );
    }

    // Mock genérico
    return const AdaptationSuggestion(
      mode: AdaptationMode.forTime,
      timeSec: 192, // 3min12s
      lines: [
        AdaptationLine(quantity: 30, movement: 'Thruster', loadKg: 32),
        AdaptationLine(quantity: 21, movement: 'Pull-up'),
      ],
    );
  }
}
