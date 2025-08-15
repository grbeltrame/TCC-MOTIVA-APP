import 'dart:async';

class Coach {
  final String id;
  final String name;

  Coach({required this.id, required this.name});
}

/// Service para dados de coach (mock + TODO back)
class CoachService {
  static Future<Coach> fetchCoachForClass(String classId) async {
    await Future.delayed(const Duration(milliseconds: 120));
    // TODO(back): buscar coach da turma no backend
    return Coach(id: 'coach_$classId', name: 'Fulano'); // mock
  }
}
