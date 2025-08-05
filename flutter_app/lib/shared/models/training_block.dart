// lib/shared/models/training_block.dart

class TrainingBlock {
  /// Título do bloco (ex: "Partner WOD", "Technique", etc).
  final String title;

  /// Subtítulo (ex: "AMRAP (35min)", "For Time", etc).
  final String subtitle;

  /// Lista de linhas de descrição do último bloco.
  final List<String> items;

  TrainingBlock({
    required this.title,
    required this.subtitle,
    required this.items,
  });
}
