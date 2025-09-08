import 'dart:async';

/// Serviço responsável por fornecer os registros de bem‑estar
/// do usuário para a semana corrente (Domingo→Sábado).
/// No futuro, substitua os valores hardcoded pelo backend real.
class WellBeingService {
  /// Retorna, para cada dia da semana (chave = DateTime do dia),
  /// um inteiro 1–10 indicando o nível de bem‑estar,
  /// ou null se o usuário não registrou naquele dia.
  static Future<Map<DateTime, int?>> fetchWeeklyRatings() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    // Em Dart, weekday: 1=Segunda … 7=Domingo. Logo:
    final daysFromSunday = now.weekday % 7;
    final sunday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysFromSunday));

    // *Exemplo* de valores hardcoded para cada dia:
    final sampleRatings = <int?>[8, 2, null, 5, 10, 3, null];

    final Map<DateTime, int?> ratings = {};
    for (var i = 0; i < 7; i++) {
      final day = sunday.add(Duration(days: i));
      ratings[DateTime(day.year, day.month, day.day)] = sampleRatings[i];
    }
    return ratings;
  }
}
