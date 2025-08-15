// lib/shared/widgets/suggested_goals_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/shared/widgets/cards/goal_card_widget.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart'; // <-- necessário para navegar

/// Seção que exibe título, subtítulo e até 3 metas sugeridas com botão “+”.
/// Se não houver sugestões, nada (nem título) aparece.
class SuggestedGoalsSection extends StatelessWidget {
  const SuggestedGoalsSection({Key? key}) : super(key: key);

  Future<void> _handleAdd(BuildContext context, Goal suggested) async {
    // 1) adiciona a sugestão à lista do usuário (origem: system)
    final newId = await GoalService.addSuggestedGoalToUser(suggested);

    if (!context.mounted) return;

    // 2) feedback + atalho para All Goals (aba Sistema)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Meta adicionada às suas metas do sistema.'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pushNamed(
              AppRoutes.athleteAllGoals,
              arguments: {
                'initialTab': 'system', // abre na aba Sistema
                'highlightGoalId': newId, // destaca a meta criada
              },
            );
          },
        ),
      ),
    );
  }

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
        final all = snapGoals.data ?? [];

        // pega no máximo 3 sugestões
        final filtered = all.take(3).toList();
        if (filtered.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // == Título e subtítulo da seção ==
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad * scale),
              child: Text(
                'Sugestões de Objetivos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad * scale),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad * scale),
              child: Column(
                children: [
                  for (var i = 0; i < filtered.length; i++) ...[
                    GoalCardWidget(
                      badgeAsset: filtered[i].badgeAsset,
                      title: filtered[i].title,
                      deadlineWeeks: filtered[i].deadlineWeeks,
                      startDate: filtered[i].startDate,
                      unitsPerWeek: filtered[i].unitsPerWeek,
                      completedUnits: filtered[i].completedUnits,
                      showAddButton: true,
                      onAdd: () => _handleAdd(context, filtered[i]),
                    ),
                    if (i < filtered.length - 1) SizedBox(height: 12 * scale),
                  ],
                ],
              ),
            ),

            // == Espaçamento para próxima seção ==
            SizedBox(height: 32 * scale),
          ],
        );
      },
    );
  }
}
