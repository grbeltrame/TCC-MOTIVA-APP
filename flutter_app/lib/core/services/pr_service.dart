// lib/core/services/pr_service.dart

class PRService {
  /// Retorna o texto do último PR do usuário já formatado
  /// (ex.: "74 kg Power Clean").
  ///
  /// TODO: Substituir por chamada real ao backend.
  /// Sugerido backend:
  ///   GET /prs/last  -> { "movement":"Power Clean", "value":74, "unit":"kg", "date":"2025-08-01" }
  ///   O app pode formatar: "$value $unit $movement"
  static Future<String?> fetchLastPRText() async {
    await Future.delayed(const Duration(milliseconds: 300)); // simula latência
    // Retorne null se não houver PRs para esse usuário
    return '74 kg Power Clean';
  }
}
