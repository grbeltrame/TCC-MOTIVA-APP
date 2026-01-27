import 'package:flutter_app/shared/widgets/carousels/alerts_carousel.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/shared/models/cycle_models.dart';

/// Service do Ciclo (Mensal)
/// TODO(back): substituir mocks por chamadas reais ao Firebase.
/// A ideia é manter as assinaturas e retornar os mesmos modelos para plugar rápido.
class CycleService {
  /// Bundle completo do detalhe do ciclo (tela mãe)
  static Future<CycleDetailBundle> fetchCycleDetail({
    required String boxId,
    required int year,
    required int month, // 1-12
  }) async {
    // Mock delay
    await Future.delayed(const Duration(milliseconds: 250));

    // === MOCK baseado na referência ===
    final updatedAt = DateTime(2025, 5, 9, 8, 42);
    final overview = CycleOverview(
      updatedAt: updatedAt,
      trainingsCount: 42,
      registrosCount: 221,
      activeStudentsPct: 81,
    );

    final trainingTypes = const <CycleTrainingTypeCount>[
      CycleTrainingTypeCount(typeLabel: 'WODs', typeKey: 'wod', count: 30),
      CycleTrainingTypeCount(
        typeLabel: 'Especificos de LPO',
        typeKey: 'lpo',
        count: 4,
      ),
      CycleTrainingTypeCount(
        typeLabel: 'Especificos de Endurance',
        typeKey: 'endurance',
        count: 4,
      ),
      // Usuária pediu no mock: Fitness Run também.
      // Na imagem não aparece, mas você pediu -> deixei como adicional no bundle.
      // Se quiser ocultar na UI por enquanto, é só não renderizar.
      CycleTrainingTypeCount(
        typeLabel: 'Fitness Run',
        typeKey: 'fitness_run',
        count: 0,
      ),
    ];

    final alerts = <AlertModel>[
      AlertModel(
        type: 'cycle',
        message:
            'Você treinou 6 dias seguidos com esforço acima de 8.5 — considere um descanso.',
      ),
      AlertModel(
        type: 'cycle',
        message:
            'Você está com déficit de sono. Tente dormir 30 min a mais esta noite.',
      ),
      AlertModel(
        type: 'cycle',
        message:
            'Seu consumo de água está abaixo do ideal. Beba pelo menos 500ml agora.',
      ),
    ];

    final stimulus = const <CycleStimulusSlice>[
      CycleStimulusSlice(stimulus: 'Cardio', count: 15),
      CycleStimulusSlice(stimulus: 'Força', count: 1),
      CycleStimulusSlice(stimulus: 'Endurance', count: 8),
      CycleStimulusSlice(stimulus: 'Resistencia', count: 9),
    ];

    final biggest = _biggestSlice(stimulus);
    final biggestLabel =
        '${biggest.stimulus} foi o maior estimulo - ${biggest.count}\n'
        'dos ${overview.trainingsCount} treinos';

    return CycleDetailBundle(
      overview: overview,
      trainingTypes: trainingTypes,
      alerts: alerts,
      stimulus: stimulus,
      biggestStimulusLabel: biggestLabel,
    );
  }

  static CycleStimulusSlice _biggestSlice(List<CycleStimulusSlice> s) {
    if (s.isEmpty) return const CycleStimulusSlice(stimulus: '—', count: 0);
    CycleStimulusSlice best = s.first;
    for (final item in s) {
      if (item.count > best.count) best = item;
    }
    return best;
  }

  static String monthTitlePtBR(int month) {
    // month 1-12
    final d = DateTime(2026, month, 1); // year dummy só pra formatar
    final m = DateFormat('MMMM', 'pt_BR').format(d);
    return m[0].toUpperCase() + m.substring(1);
  }
}
