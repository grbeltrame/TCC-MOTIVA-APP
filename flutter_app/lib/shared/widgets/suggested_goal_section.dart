// lib/shared/widgets/suggested_goals_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/shared/widgets/goal_card_widget.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seção que exibe título, subtítulo e até 3 metas sugeridas com botão “+”.
/// Se não houver sugestões habilitadas, nada (nem o título) aparece.
class SuggestedGoalsSection extends StatelessWidget {
  const SuggestedGoalsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    const horizontalPad = 6.0;

    return FutureBuilder<List<Goal>>(
      future: GoalService.fetchSuggestedGoals(),
      builder: (ctx, snapGoals) {
        if (snapGoals.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final all = snapGoals.data!;

        return FutureBuilder<Set<String>>(
          future: GoalService.fetchEnabledSuggestedGoalIds(),
          builder: (ctx2, snapEnabled) {
            if (snapEnabled.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            final enabledIds = snapEnabled.data!;
            final filtered =
                all.where((g) => enabledIds.contains(g.id)).take(3).toList();
            if (filtered.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // == Título e subtítulo da seção ==
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad * scale,
                  ),
                  child: Text(
                    'Sugestões de Objetivos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPad * scale,
                  ),
                  child: Text(
                    'Clique em + para adicionar objetivo à lista',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.medium,
                      fontSize: 12 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),

                SizedBox(height: 16 * scale),

                // == Cards de metas ==
                for (var i = 0; i < filtered.length; i++) ...[
                  GoalCardWidget(
                    badgeAsset: filtered[i].badgeAsset,
                    title: filtered[i].title,
                    deadlineWeeks: filtered[i].deadlineWeeks,
                    startDate: filtered[i].startDate,
                    unitsPerWeek: filtered[i].unitsPerWeek,
                    completedUnits: filtered[i].completedUnits,
                    showAddButton: true,
                    onAdd: () {
                      // TODO: integrar adição da meta ao usuário
                    },
                  ),
                  if (i < filtered.length - 1) SizedBox(height: 12 * scale),
                ],

                // == Espaçamento para próxima seção ==
                SizedBox(height: 32 * scale),
              ],
            );
          },
        );
      },
    );
  }
}
