//lib/shared/services/mini_card_service.dart

class CardInfoType {
  static const String prsMes = 'prs_mes'; // PRs batidos no mês atual
  static const String frequenciaMes = 'frequencia_mes'; // Frequência mensal
  static const String esforcoMes = 'esforco_mes'; // Esforço médio no mês
  static const String prsTotal =
      'prs_total'; // PRs total (fora do widget atual)
  static const String treinosTotal =
      'prs_total'; // PRs total (fora do widget atual)

  // ✅ NOVOS TIPOS (CICLO MENSAL - COACH)
  static const String cycleTrainings = 'cycle_trainings'; // "42 cadastros"
  static const String cycleRegistros = 'cycle_registros'; // "221 registros"
  static const String cycleActiveStudents =
      'cycle_active_students'; // "81% dos alunos"

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

      // ✅ CICLO (MENSAL) — MOCKS + TODO(back)
      case CardInfoType.cycleTrainings:
        // TODO(back): GET /boxes/{boxId}/cycles/{year}-{month}/trainings/count
        // Retornar string já formatada: "{n} cadastros"
        return '42 cadastros';

      case CardInfoType.cycleRegistros:
        // TODO(back): GET /boxes/{boxId}/cycles/{year}-{month}/registrations/count
        // Retornar string já formatada: "{n} registros"
        return '221 registros';

      case CardInfoType.cycleActiveStudents:
        // TODO(back): GET /boxes/{boxId}/cycles/{year}-{month}/students/active_pct
        // Retornar string já formatada: "{pct}% dos alunos"
        return '81% dos alunos';

      default:
        return 'N/A';
    }
  }
}
