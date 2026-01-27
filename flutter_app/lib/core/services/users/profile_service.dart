//troca de perfil aluno/coach, listagem de boxes do coach.

// lib/features/auth/services/profile_service.dart
import 'dart:async';

import 'package:flutter_app/shared/models/coach_profile.dart';

/// TODO: retirar este mock e implementar chamada real ao backend via AuthService
class ProfileService {
  // MOCK: dados estáticos até termos API
  final List<String> _roles = ['student', 'coach'];
  String get currentRoleLabel => 'Coach'; // ou 'Coach'
  List<String> get coachBoxNames => []; // boxes cadastrados
  String? get currentBoxName => null;
  int get unreadCount => 5;

  bool hasRole(String role) => _roles.contains(role);

  // FUTURO: aqui implementar
  // Future<UserProfile> fetchUserProfile() async { ... }
}
// lib/features/user/coach/edit_profile/services/coach_profile_service.dart

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
      certifications: <String>['Bacharel em Educação Física', 'CrossFit L1'],
      specialties: <String>[
        'Planejamento Estratégico',
        'Periodização de Ciclos',
        'Analise de Dados para Performance',
        'Adaptação para diferentes níveis',
        'Gestão de Planilhas e Metas',
        'Levantamento de Peso Olimpico',
        'Ginasticos',
        'Corrida e Pacing',
        'Respiração',
        'Mobilidade articular',
        'Alongamento e Aquecimento',
        'Cuidados pós lesão',
        'Fortalecimento',
        'Psicologia do esporte',
        'Gestão de Grupo',
        'Motivação de alunos',
        'Feedback individual',
        'Treinamento para terceira idade',
        'Reabilitação',
      ],
      availableCertifications: <String>[
        'Bacharel em Educação Física',
        'CrossFit L1',
      ],
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
