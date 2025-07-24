// lib/shared/widgets/suggested_goals_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/shared/widgets/goal_card_widget.dart';

/// Seção que exibe até 3 metas sugeridas com botão “+”,
/// buscando automaticamente do GoalService.
class SuggestedGoalsSection extends StatelessWidget {
  const SuggestedGoalsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<List<Goal>>(
      future: GoalService.fetchSuggestedGoals(), // busca direto aqui
      builder: (context, snap) {
        final suggestions = snap.data?.take(3).toList() ?? [];

        if (suggestions.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < suggestions.length; i++) ...[
              GoalCardWidget(
                badgeAsset: suggestions[i].badgeAsset,
                title: suggestions[i].title,
                deadlineWeeks: suggestions[i].deadlineWeeks,
                startDate: suggestions[i].startDate,
                unitsPerWeek: suggestions[i].unitsPerWeek,
                completedUnits: suggestions[i].completedUnits,
                showAddButton: true,
                onAdd: () {
                  // TODO: integrar adição da meta ao usuário
                },
              ),
              if (i < suggestions.length - 1) SizedBox(height: 12 * scale),
            ],
          ],
        );
      },
    );
  }
}
