import 'dart:async';

/// Registra no backend atividades do dia (não treinou / outra atividade).
/// TODO(back): trocar mocks por chamadas reais de API (ex.: POST /activity-log)
class ActivityLogService {
  /// Usuário informou que NÃO treinou neste dia.
  static Future<void> logDidNotTrain({required DateTime date}) async {
    // Simula latência de rede
    await Future.delayed(const Duration(milliseconds: 250));
    // TODO(back): POST real – ex.: {"type":"no_training","date":"..."}
  }

  /// Usuário informou que FEZ OUTRA ATIVIDADE FÍSICA.
  static Future<void> logOtherActivity({
    required DateTime date,
    String? description, // opcional: "caminhada", "bike", etc.
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    // TODO(back): POST real – ex.: {"type":"other_activity","date":"...","desc":description}
  }
}
