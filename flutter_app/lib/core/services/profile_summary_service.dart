import 'dart:async';

/// Modelo bem simples para contadores da seção.
class ProfileSummaryCounts {
  final int totalPrs;
  final int totalWorkouts;

  ProfileSummaryCounts({required this.totalPrs, required this.totalWorkouts});
}

class ProfileSummaryService {
  /// Retorna os contadores usados nos mini-cards.
  /// TODO backend: retornar totais **desde a criação da conta**.
  static Future<ProfileSummaryCounts> fetchCounts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO backend: substituir mocks por valores reais
    return ProfileSummaryCounts(totalPrs: 12, totalWorkouts: 63);
  }

  /// Retorna o título do último PR registrado pelo usuário
  /// (ex.: "74 kg Power Clean").
  /// TODO backend: buscar o PR mais recente do usuário (ordenado por data desc)
  static Future<String?> fetchLastPrTitle() async {
    await Future.delayed(const Duration(milliseconds: 250));
    // Retorne null se o usuário ainda não tiver PRs:
    return '74 kg Power Clean';
  }
}
