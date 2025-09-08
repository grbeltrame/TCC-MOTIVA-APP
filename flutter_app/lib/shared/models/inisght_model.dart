// lib/shared/widgets/insight_model.dart

/// Modelo de um insight diário.
class InsightsModel {
  /// Tipo identificador (p.ex. 'performance_trend').
  final String type;

  /// Mensagem principal do insight.
  final String message;

  InsightsModel({required this.type, required this.message});
}
