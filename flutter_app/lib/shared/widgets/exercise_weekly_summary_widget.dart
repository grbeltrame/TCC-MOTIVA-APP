// lib/shared/widgets/exercise_weekly_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/users/user_preferences_service.dart';
import 'cards/exercise_weekly_summary_simple_card.dart';
import 'cards/exercise_weekly_summary_complex_card.dart';

/// Mostra **ou** o Simple **ou** o Complex, conforme preferência do usuário.
/// [from]/[to] são repassados ao ComplexCard para filtrar estímulos por período.
class ExerciseWeeklySummaryWidget extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  const ExerciseWeeklySummaryWidget({Key? key, this.from, this.to})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SummaryType>(
      future: UserPreferencesService.fetchSummaryType(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return const SizedBox.shrink();
        }

        switch (snap.data!) {
          case SummaryType.simple:
            return const ExerciseWeeklySummarySimpleCard();
          case SummaryType.complex:
            return ExerciseWeeklySummaryComplexCard(from: from, to: to);
        }
      },
    );
  }
}
