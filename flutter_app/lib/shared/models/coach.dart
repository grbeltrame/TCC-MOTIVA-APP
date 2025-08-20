class Coach {
  final String id;
  final String name;

  Coach({required this.id, required this.name});
}

class CoachProfileSummary {
  final String coachId;
  final String name;
  final String? photoUrl; // pode ser null → avatar com inicial
  final String cref; // ex.: 123456-G/RJ
  final List<String> specialties;
  final List<String> certifications;
  final int appliedTrainingsCount; // “Treinos aplicados”
  final int createdTrainingsCount; // “Treinos cadastrados”

  CoachProfileSummary({
    required this.coachId,
    required this.name,
    required this.photoUrl,
    required this.cref,
    required this.specialties,
    required this.certifications,
    required this.appliedTrainingsCount,
    required this.createdTrainingsCount,
  });
}
