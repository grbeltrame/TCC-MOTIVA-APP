//troca de perfil aluno/coach, listagem de boxes do coach.

// lib/features/auth/services/profile_service.dart

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
