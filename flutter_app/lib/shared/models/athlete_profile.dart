// lib/shared/models/athlete_profile.dart

/// Detalhes demográficos e de saúde do atleta.
class AthleteProfileReference {
  final String gender; // ex: “Mulheres”
  final String ageRange; // ex: “Entre 20 e 30 anos”
  final String weightRange; // ex: “Entre 50 e 60 kg”
  final String practiceYears; // ex: “Entre 3 e 5 anos de prática”
  final String heightRange; // ex: “Mais de 170 cm”

  AthleteProfileReference({
    required this.gender,
    required this.ageRange,
    required this.weightRange,
    required this.practiceYears,
    required this.heightRange,
  });
}

/// Perfil completo do usuário.
class AthleteProfile {
  final String name;
  final String? photoUrl; // URL da foto, se houver
  final String? category; // Iniciante, Scale, Intermediário, RX
  final AthleteProfileReference? reference; // dados demográficos
  final List<String> boxes; // nomes dos boxes cadastrados

  AthleteProfile({
    required this.name,
    this.photoUrl,
    this.category,
    this.reference,
    this.boxes = const [],
  });
}
