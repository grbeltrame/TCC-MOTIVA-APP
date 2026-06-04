import 'dart:async';

import 'package:flutter_app/shared/models/coach.dart';
import 'package:flutter_app/shared/models/coach_profile.dart';

/// Service para dados de coach (mock + TODO back)
class CoachService {
  static Future<Coach> fetchCoachForClass(String classId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    // TODO(back): buscar coach da turma no backend
    return Coach(id: 'coach_$classId', name: 'Fulano'); // mock
  }

  static Future<CoachProfile> fetchCoachProfile() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return CoachProfile(
      name: 'Giovanni Saraiva',
      photoUrl: null, // se quiser testar com foto, coloque uma URL válida
      cref: '012345-G/RJ',
      specialties: const ['LPO', 'Planejamento Estratégico', 'Mobilidade'],
      certifications: const ['Bacharel em Educação Física', 'CrossFit L1'],
    );
  }

  /// Resumo completo do professor para a turma.
  /// Usa a turma para resolver o coach e depois busca o perfil.
  /// TODO(back): idealmente 1 endpoint só: GET /classes/{id}/coach/summary
  static Future<CoachProfileSummary> fetchCoachSummaryByClassId(
    String classId,
  ) async {
    final coach = await fetchCoachForClass(classId);
    return fetchCoachSummary(coach.id);
  }

  /// Resumo completo do professor pelo id.
  /// TODO(back): GET /coaches/{coachId}/summary
  static Future<CoachProfileSummary> fetchCoachSummary(String coachId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // MOCK fiel ao layout: ajuste como quiser
    return CoachProfileSummary(
      coachId: coachId,
      name: 'Alex Machado',
      photoUrl:
          null, // sem foto -> usa avatar com inicial; troque por URL para testar
      cref: '123456-G/RJ',
      specialties: const ['LPO', 'Planejamento estratégico', 'Mobilidade'],
      certifications: const ['Bacharel em Educação Física', 'CrossFit L1'],
      appliedTrainingsCount: 340,
      createdTrainingsCount: 127,
    );
  }
}
