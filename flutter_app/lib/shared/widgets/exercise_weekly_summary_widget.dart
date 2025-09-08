// lib/shared/widgets/exercise_weekly_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/users/user_preferences_service.dart';
import 'cards/exercise_weekly_summary_simple_card.dart';
import 'cards/exercise_weekly_summary_complex_card.dart';

/// Mostra **ou** o Simple **ou** o Complex, conforme preferência do usuário.
class ExerciseWeeklySummaryWidget extends StatelessWidget {
  const ExerciseWeeklySummaryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SummaryType>(
      future: UserPreferencesService.fetchSummaryType(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          // Enquanto carrega preferência, mostra loading alinhado
          return const SizedBox(
            height: 150, // altura aproximada dos cards
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          // Se der erro, nem um nem outro
          return const SizedBox.shrink();
        }

        switch (snap.data!) {
          case SummaryType.simple:
            return const ExerciseWeeklySummarySimpleCard();
          case SummaryType.complex:
            return const ExerciseWeeklySummaryComplexCard();
        }
      },
    );
  }
}
