// lib/shared/models/coach_profile.dart
class CoachProfile {
  final String name;
  final String? photoUrl;
  final String? cref; // ex.: "012345-G/RJ"
  final List<String>
  specialties; // ex.: ["LPO", "Planejamento Estratégico", "Mobilidade"]
  final List<String>
  certifications; // ex.: ["Bacharel em Educação Física", "CrossFit L1"]

  CoachProfile({
    required this.name,
    this.photoUrl,
    this.cref,
    required this.specialties,
    required this.certifications,
  });
}
