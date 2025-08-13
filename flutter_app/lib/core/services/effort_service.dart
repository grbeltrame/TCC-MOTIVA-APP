import 'package:flutter_app/core/services/weekly_summary_service.dart';

/// Um ponto por dia, com valor de esforço (0–100%)
class DailyEffort {
  final DateTime date;
  final double percent;
  DailyEffort(this.date, this.percent);
}

/// Serviço para buscar dados de esforço ao longo da semana.
class EffortService {
  /// Retorna 7 pontos (domingo→sábado) com valores hard‑coded por enquanto.
  Future<List<DailyEffort>> fetchWeeklyEffortSeries(WeekRange week) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final start = week.start;
    // TODO: trocar por chamada real ao backend, passando week.start/week.end
    return List.generate(7, (i) {
      final dia = start.add(Duration(days: i));
      final raw = 50 + i * 5;
      final scaled = raw / 10; // 50→5.0, 55→5.5, …, 80→8.0
      return DailyEffort(
        dia,
        scaled.clamp(1.0, 10.0),
      ); // Exemplo: 50%, 55%, 60%...
    });
  }

  /// Valor padrão do esforço (1..10). Pode vir de preferências ou último registro.
  Future<int> fetchDefaultEffort() async {
    await Future.delayed(const Duration(milliseconds: 120));
    // TODO(back): buscar valor default real no perfil/último treino
    return 5; // mock
  }

  /// ====== NOVO ======
  /// Envia o esforço para o backend.
  /// [effort] deve ser 1..10. [classId] e [date] contextualizam o registro.
  Future<void> submitEffort({
    required int effort,
    String? classId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 240));
    // TODO(back): POST /effort { effort(1..10), classId, date }
    // Se necessário, incluir userId/athleteId via Auth/ProfileService.
  }
}
