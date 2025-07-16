// lib/core/services/weekly_summary_service.dart
import 'package:intl/intl.dart';
import 'package:flutter_app/core/services/alerts_service.dart';
import 'package:flutter_app/core/services/highlights_service.dart';
import 'package:flutter_app/core/services/recomendations_service.dart';

/// Agrupa todos os pedaços de dados que compõem o Resumo Semanal.

/// Modelo genérico de um insight (alerta, destaque ou recomendação).
class InsightModel {
  final String type;
  final String message;
  InsightModel({required this.type, required this.message});
}

/// Representa o intervalo da semana atual (domingo → sábado).
class WeekRange {
  final DateTime start; // domingo
  final DateTime end; // sábado
  WeekRange(this.start, this.end);
}

/// Quantidade de dias treinados nesta semana.
class StimulusCount {
  final String name;
  final int count;
  StimulusCount(this.name, this.count);
}

/// Dados de carga total levantada e comparação vs. semana anterior.
class TotalLoad {
  /// kg levantados na semana atual
  final double totalKg;

  /// kg levantados na semana anterior
  final double previousWeekKg;

  TotalLoad({required this.totalKg, required this.previousWeekKg});

  /// diferença em kg (pode ser negativa)
  double get differenceKg => totalKg - previousWeekKg;

  /// variação percentual (pode ser negativa)
  double get percentChange =>
      previousWeekKg > 0 ? (differenceKg / previousWeekKg) * 100 : 0;

  /// valor absoluto da variação percentual
  double get absolutePercentChange => percentChange.abs();

  /// comentário “X% maior…” ou “X% menor…”
  String get changeComment {
    final p = absolutePercentChange.toStringAsFixed(1);
    if (percentChange > 0) {
      return '$p% maior que a semana anterior';
    } else if (percentChange < 0) {
      return '$p% menor que a semana anterior';
    } else {
      return 'Mesmo total da semana anterior';
    }
  }
}

/// Modelo para PRs batidos.
class PRModel {
  final String label; // ex: "Back Squat – 100 kg"
  PRModel(this.label);
}

/// Esforço médio e comentário associado.
class EffortModel {
  final double score; // ex: 6.4
  final String comment; // ex: "Foi uma semana intensa"
  EffortModel(this.score, this.comment);
}

/// Serviço que “fala” com o backend (ou mocks) para alimentar o Resumo Semanal.
class WeeklySummaryService {
  final _alertsSvc = AlertsService();
  final _highlightsSvc = HighlightsService();
  final _recsSvc = RecomendationsService();

  /// Semana atual (domingo→sábado)
  WeekRange fetchCurrentWeekRange() {
    final now = DateTime.now();
    // weekday: 1=segunda,...,7=domingo; queremos domingo=0..sábado=6
    final weekdayIndex = now.weekday % 7;
    final sunday = now.subtract(Duration(days: weekdayIndex));
    final saturday = sunday.add(const Duration(days: 6));
    return WeekRange(sunday, saturday);
  }

  /// Dias treinados nesta semana (datas exatas)
  Future<Set<DateTime>> fetchDaysTrained() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: trocar pelos dados reais do backend
    final range = fetchCurrentWeekRange();
    return {
      range.start, // domingo
      range.start.add(const Duration(days: 2)), // terça
      range.start.add(const Duration(days: 4)), // quinta
    };
  }

  /// Contagem de estímulos para o gráfico de pizza.
  Future<List<StimulusCount>> fetchStimuliCounts() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: trazer do backend
    return [
      StimulusCount('Força', 3),
      StimulusCount('Cardio', 2),
      StimulusCount('Mobilidade', 1),
    ];
  }

  /// Simula busca da carga total e da carga da semana anterior.
  Future<TotalLoad> fetchTotalLoad() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: substituir pelos valores vindos do backend:
    final current = 18.4;
    final previous = 16.0;
    return TotalLoad(totalKg: current, previousWeekKg: previous);
  }

  ///  PRs batidos nesta semana.
  Future<List<PRModel>> fetchPRs() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: buscar no backend
    return [PRModel('Back Squat – 100 kg'), PRModel('Fran – 5:23')];
  }

  ///  Esforço médio e comentário.
  Future<EffortModel> fetchEffort() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO: buscar e gerar comentário no backend
    return EffortModel(6.4, 'Foi uma semana intensa');
  }

  /// Retorna todos os insights habilitados (até 3 de cada tipo).
  Future<List<InsightModel>> fetchInsights() async {
    // 1) buscar todos os alertas e os tipos habilitados
    final alerts = await _alertsSvc.fetchAlerts();
    final enabledAlerts = await _alertsSvc.fetchEnabledTypes();

    // 2) buscar todos os destaques e os tipos habilitados
    final highlights = await _highlightsSvc.fetchHighlights();
    final enabledHighlights =
        await _highlightsSvc.fetchEnabledHighlightsTypes();

    // 3) buscar todas as recomendações e os tipos habilitados
    final recs = await _recsSvc.fetchRecomendations();
    final enabledRecs = await _recsSvc.fetchEnabledRecomendationsTypes();

    // 4) montar lista de insights, respeitando ordem e limite de 3 por fonte
    final insights = <InsightModel>[];

    insights.addAll(
      alerts
          .where((a) => enabledAlerts.contains(a.type))
          .take(3)
          .map((a) => InsightModel(type: a.type, message: a.message)),
    );

    insights.addAll(
      highlights
          .where((h) => enabledHighlights.contains(h.type))
          .take(3)
          .map((h) => InsightModel(type: h.type, message: h.message)),
    );

    insights.addAll(
      recs
          .where((r) => enabledRecs.contains(r.type))
          .take(3)
          .map((r) => InsightModel(type: r.type, message: r.message)),
    );

    return insights;
  }
}
