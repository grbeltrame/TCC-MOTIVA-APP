// lib/core/services/user_preferences_service.dart

/// Quais tipos de resumo o usuário pode escolher.
enum SummaryType { simple, complex }

/// Mock de preferências do usuário.
/// Quando o backend estiver pronto, basta trocar o mock abaixo.
class UserPreferencesService {
  /// TODO: buscar do SharedPreferences ou do backend.
  static Future<SummaryType> fetchSummaryType() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return SummaryType.complex; // ou SummaryType.complex
  }
}
