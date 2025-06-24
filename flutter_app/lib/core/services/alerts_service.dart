import 'package:flutter_app/shared/widgets/alerts_carousel.dart';

/// Serviço responsável por buscar os alertas e tipos habilitados.
/// TODO: substituir mocks por chamadas reais ao backend.
class AlertsService {
  /// Retorna a lista completa de alertas.
  Future<List<AlertModel>> fetchAlerts() async {
    await Future.delayed(const Duration(milliseconds: 200)); // simula latência
    return [
      AlertModel(
        type: 'training_streak',
        message:
            'Você treinou 6 dias seguidos com esforço acima de 8.5 — considere um descanso.',
      ),
      AlertModel(
        type: 'sleep_debt',
        message:
            'Você está com déficit de sono. Tente dormir 30 min a mais esta noite.',
      ),
      AlertModel(
        type: 'hydration',
        message:
            'Seu consumo de água está abaixo do ideal. Beba pelo menos 500ml agora.',
      ),
    ];
  }

  /// Retorna o conjunto de tipos de alerta que o usuário deixou habilitados.
  Future<Set<String>> fetchEnabledTypes() async {
    await Future.delayed(const Duration(milliseconds: 100)); // simula latência
    return {'training_streak', 'hydration'};
  }
}
