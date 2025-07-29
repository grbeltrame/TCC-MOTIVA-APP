import 'dart:async';

import 'package:flutter_app/core/services/weekly_summary_service.dart';

/// Modelo que representa o resumo simples semanal de exercícios.
class SimpleExerciseSummary {
  /// Nome do usuário (hardcoded por enquanto; futuro: do backend).
  final String userName;

  /// Descrição do objetivo semanal, ex.: “Treinar 3 vezes por semana”.
  final String goalName;

  /// Quantidade total de itens a cumprir na semana (ex.: 3 treinos).
  final double targetValue;

  /// Quantidade já concluída até agora (ex.: 2 treinos).
  final double completedValue;

  SimpleExerciseSummary({
    required this.userName,
    required this.goalName,
    required this.targetValue,
    required this.completedValue,
  });
}

/// Resumo complexo para o gráfico de estímulos.
class ComplexExerciseSummary {
  final String userName;
  final List<StimulusCount> distribution;
  final String predominantStimulus;
  final String shortInsight;

  ComplexExerciseSummary({
    required this.userName,
    required this.distribution,
    required this.predominantStimulus,
    required this.shortInsight,
  });
}

/// Serviço para buscar o resumo semanal de exercícios.
/// Por enquanto retorna dados mockados; no futuro se conecta ao backend.
class ExerciseWeeklySummaryService {
  /// Retorna um [SimpleExerciseSummary] com dados estáticos.
  static Future<SimpleExerciseSummary> fetchSimpleSummary() async {
    // Simula atraso de rede
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: chamar API REST ou SharedPreferences para valores reais
    return SimpleExerciseSummary(
      userName: 'Giovana',
      goalName: 'Treinar 3 vezes por semana',
      targetValue: 3,
      completedValue: 2,
    );
  }

  ///  Retorna dados para o card complexo.
  static Future<ComplexExerciseSummary> fetchComplexSummary() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // === MOCK HARD‑CODED ===
    final userName = 'Giovana'; // TODO: buscar nome real do usuário

    // Reutiliza o WeeklySummaryService para obter distribuição
    final dist = await WeeklySummaryService().fetchStimuliCounts();

    // Determina o estímulo predominante (maior count)
    final sorted = List<StimulusCount>.from(dist)
      ..sort((a, b) => b.count.compareTo(a.count));
    final predominant = sorted.isNotEmpty ? sorted.first.name : '';

    final insight = 'mas existe equilíbrio'; // TODO: lógica real de insight

    return ComplexExerciseSummary(
      userName: userName,
      distribution: dist,
      predominantStimulus: predominant,
      shortInsight: insight,
    );
  }
}
