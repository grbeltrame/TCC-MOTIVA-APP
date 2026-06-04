/// Modelo simples (opcional) caso você queira pré-preencher o sheet no futuro.
class CoachRating {
  final String id;
  final int rating; // 0..5
  final String? comment;
  final DateTime createdAt;

  CoachRating({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
  });
}
