//lib/shared/services/mini_card_service.dart

class CardInfoType {
  static const String prsMes = 'prs_mes'; // PRs batidos no mês atual
  static const String frequenciaMes = 'frequencia_mes'; // Frequência mensal
  static const String esforcoMes = 'esforco_mes'; // Esforço médio no mês
  static const String prsTotal =
      'prs_total'; // PRs total (fora do widget atual)
  static const String treinosTotal =
      'prs_total'; // PRs total (fora do widget atual)

  // Aqui podemos adicionar outros tipos no futuro, conforme a necessidade
}

class MiniCardService {
  /// Retorna a informação do card com base no tipo especificado.
  /// No futuro, esse método será conectado ao backend.
  static Future<String> getCardInfo({required String tipo}) async {
    // Simulando tempo de resposta
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Substituir esses valores por integrações reais com banco de dados
    switch (tipo) {
      case CardInfoType.prsMes:
        return '3 movimentos';
      case CardInfoType.frequenciaMes:
        return '10 treinos';
      case CardInfoType.esforcoMes:
        return '7.1/10';
      case CardInfoType.prsTotal:
        return '12 PRs';
      case CardInfoType.treinosTotal:
        // TODO backend: GET /stats/total/workouts
        return '63 treinos';
      default:
        return 'N/A';
    }
  }
}
