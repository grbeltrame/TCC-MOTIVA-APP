import 'package:flutter_app/shared/widgets/carousels/alerts_carousel.dart';

class CycleOverview {
  final DateTime updatedAt;
  final int trainingsCount; // "Treinos 42 cadastros"
  final int registrosCount; // "Registros 221 registros"
  final int activeStudentsPct; // "Alunos Ativos 81% dos alunos"

  const CycleOverview({
    required this.updatedAt,
    required this.trainingsCount,
    required this.registrosCount,
    required this.activeStudentsPct,
  });
}

class CycleTrainingTypeCount {
  final String typeLabel; // ex: "WODs"
  final String typeKey; // ex: "wod"
  final int count;

  const CycleTrainingTypeCount({
    required this.typeLabel,
    required this.typeKey,
    required this.count,
  });
}

class CycleStimulusSlice {
  final String stimulus;
  final int count;

  const CycleStimulusSlice({required this.stimulus, required this.count});
}

class CycleDetailBundle {
  final CycleOverview overview;
  final List<CycleTrainingTypeCount> trainingTypes;
  final List<AlertModel> alerts;
  final List<CycleStimulusSlice> stimulus;
  final String biggestStimulusLabel; // texto pronto pra UI

  const CycleDetailBundle({
    required this.overview,
    required this.trainingTypes,
    required this.alerts,
    required this.stimulus,
    required this.biggestStimulusLabel,
  });
}
