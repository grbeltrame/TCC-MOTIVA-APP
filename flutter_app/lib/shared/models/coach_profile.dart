// lib/shared/models/coach_profile.dart
import 'dart:async';

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

class CoachProfileEditable {
  final String name;
  final String? photoUrl;
  final String? localPhotoPath;
  final String? cref;
  final DateTime? birthday;

  /// ✅ APENAS selecionadas
  final List<String> certifications;
  final List<String> specialties;

  /// ✅ catálogo (opções)
  final List<String> availableCertifications;
  final Map<String, List<String>> specialtiesByCategory;

  CoachProfileEditable({
    required this.name,
    this.photoUrl,
    this.localPhotoPath,
    this.cref,
    this.birthday,
    required this.certifications,
    required this.specialties,
    required this.availableCertifications,
    required this.specialtiesByCategory,
  });

  CoachProfileEditable copyWith({
    String? name,
    String? photoUrl,
    String? localPhotoPath,
    String? cref,
    DateTime? birthday,
    List<String>? certifications,
    List<String>? specialties,
    List<String>? availableCertifications,
    Map<String, List<String>>? specialtiesByCategory,
  }) {
    return CoachProfileEditable(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      cref: cref ?? this.cref,
      birthday: birthday ?? this.birthday,
      certifications: certifications ?? this.certifications,
      specialties: specialties ?? this.specialties,
      availableCertifications:
          availableCertifications ?? this.availableCertifications,
      specialtiesByCategory:
          specialtiesByCategory ?? this.specialtiesByCategory,
    );
  }
}

class CoachProfileService {
  CoachProfileService._();
  static final CoachProfileService instance = CoachProfileService._();

  CoachProfileEditable? _cache;

  Future<CoachProfileEditable> fetchCoachProfileEditable() async {
    // TODO(DB-LOAD): trocar por request real (ex.: repository)
    await Future.delayed(const Duration(milliseconds: 250));

    _cache ??= CoachProfileEditable(
      name: 'Alex Machado',
      photoUrl: null,
      localPhotoPath: null,
      cref: '123456-G/RJ',
      birthday: DateTime(2000, 8, 29),

      // ✅ SOMENTE AS QUE JÁ FAZIAM PARTE DO PERFIL (marcadas ao abrir)
      certifications: <String>['Bacharel em Educação Física', 'CrossFit L1'],

      // ✅ SOMENTE AS QUE JÁ FAZIAM PARTE DO PERFIL (marcadas ao abrir)
      specialties: <String>[
        'Planejamento Estratégico',
        'Ginasticos',
        'Mobilidade articular',
      ],

      // ✅ LISTA DE OPÇÕES (não é “selecionadas”)
      availableCertifications: <String>[
        'Bacharel em Educação Física',
        'CrossFit L1',
        'CrossFit L2',
        'Weightlifting Level 1',
      ],

      // ✅ CATÁLOGO COMPLETO POR CATEGORIA (opções)
      specialtiesByCategory: <String, List<String>>{
        'Estratégia e Planejamento': <String>[
          'Planejamento Estratégico',
          'Periodização de Ciclos',
          'Analise de Dados para Performance',
          'Adaptação para diferentes níveis',
          'Gestão de Planilhas e Metas',
        ],
        'Técnica e Execução': <String>[
          'Levantamento de Peso Olimpico',
          'Ginasticos',
          'Corrida e Pacing',
          'Respiração',
        ],
        'Mobilidade e Prevenção': <String>[
          'Mobilidade articular',
          'Alongamento e Aquecimento',
          'Cuidados pós lesão',
          'Fortalecimento',
        ],
        'Motivação e Psicologia': <String>[
          'Psicologia do esporte',
          'Gestão de Grupo',
          'Motivação de alunos',
          'Feedback individual',
        ],
        'Saude e Bem estar': <String>[
          'Treinamento para terceira idade',
          'Reabilitação',
        ],
      },
    );

    return _cache!;
  }

  Future<void> updateCoachProfileEditable(CoachProfileEditable updated) async {
    // TODO(DB-SAVE): trocar por request real (ex.: repository)
    await Future.delayed(const Duration(milliseconds: 250));
    _cache = updated;
  }
}
