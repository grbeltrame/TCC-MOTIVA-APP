// lib/shared/models/training_block.dart

class TrainingBlock {
  final String id;

  /// Título do bloco (ex: "Partner WOD", "Technique", etc).
  final String title;

  /// Subtítulo (ex: "AMRAP (35min)", "For Time", etc).
  final String subtitle;

  /// Lista de linhas de descrição do último bloco.
  final List<String> items;

  TrainingBlock({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  factory TrainingBlock.legacy({
    required String title,
    required String subtitle,
    required List<String> items,
  }) => TrainingBlock(
    id: '', // sem id (evite no novo código)
    title: title,
    subtitle: subtitle,
    items: items,
  );
}
