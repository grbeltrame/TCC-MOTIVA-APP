// lib/shared/models/worked_muscle.dart
class WorkedMuscle {
  /// Nome amigável do músculo (ex.: “Dorsal”, “Quadríceps”)
  final String muscle;

  /// Nome do movimento (ex.: “Snatch”, “Pull-up”)
  final String movement;

  /// Imagens (1..N) do movimento com os músculos destacados
  /// (ex.: posição inicial e final). Paths de assets.
  final List<String> imageAssetPaths;

  WorkedMuscle({
    required this.muscle,
    required this.movement,
    required this.imageAssetPaths,
  });
}
