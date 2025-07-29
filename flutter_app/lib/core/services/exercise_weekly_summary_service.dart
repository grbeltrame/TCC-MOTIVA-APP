import 'dart:async';

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

/// Serviço para buscar o resumo semanal de exercícios.
/// Por enquanto retorna dados mockados; no futuro se conecta ao backend.
class ExerciseWeeklySummaryService {
  /// Retorna um [SimpleExerciseSummary] com dados estáticos.
  static Future<SimpleExerciseSummary> fetchSimpleSummary() async {
    // Simula atraso de rede
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: chamar API REST ou SharedPreferences para valores reais
    return SimpleExerciseSummary(
      userName: 'Fulano',
      goalName: 'Treinar 3 vezes por semana',
      targetValue: 3,
      completedValue: 2,
    );
  }

  /// TODO: implementar fetchComplexSummary() para a variante completa.
}
