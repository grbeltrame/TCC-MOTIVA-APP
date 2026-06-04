// lib/core/models/championship.dart

class Championship {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final int? userRanking;
  final int? totalParticipants;

  Championship({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.userRanking,
    this.totalParticipants,
  });
}
