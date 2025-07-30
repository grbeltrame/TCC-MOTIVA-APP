// lib/shared/widgets/user_goals_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/shared/widgets/goal_card_widget.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seção de "Objetivos" que exibe até 3 metas em andamento do usuário.
///
/// • Se não houver metas ativas, não renderiza nada.
/// • Título + botão "Adicionar objetivo" alinhados na mesma linha.
/// • Cada card NÃO tem o botão '+' interno.
/// • Espaça 12*scale entre os cards e 32*scale após a seção.
class UserGoalsSection extends StatelessWidget {
  const UserGoalsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    const horizontalPad = 6.0;

    return FutureBuilder<List<Goal>>(
      future: GoalService.fetchActiveUserGoals(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          // Enquanto carrega, não ocupa espaço
          return const SizedBox.shrink();
        }

        final all = snap.data ?? [];
        // Só mostra até 3 metas
        final active = all.take(3).toList();

        if (active.isEmpty) {
          // Se não tiver nenhuma meta ativa, some tudo
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título + botão "Adicionar objetivo"
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Objetivos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // TODO: navegar para o fluxo de criação de nova meta
                    },
                    icon: Icon(
                      Icons.add,
                      size: 20 * scale,
                      color: AppColors.baseBlue,
                    ),
                    label: Text(
                      'Adicionar objetivo',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.medium,
                        fontSize: 12 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 4 * scale,
                        horizontal: 8 * scale,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16 * scale),

            // Lista de cards de metas
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPad * scale),
              child: Column(
                children: [
                  for (var i = 0; i < active.length; i++) ...[
                    GoalCardWidget(
                      badgeAsset: active[i].badgeAsset,
                      title: active[i].title,
                      deadlineWeeks: active[i].deadlineWeeks,
                      startDate: active[i].startDate,
                      unitsPerWeek: active[i].unitsPerWeek,
                      completedUnits: active[i].completedUnits,
                      showAddButton: false, // sem o '+' interno
                      onAdd: null,
                    ),
                    if (i < active.length - 1) SizedBox(height: 12 * scale),
                  ],
                ],
              ),
            ),

            // Espaçamento para a próxima seção
            SizedBox(height: 32 * scale),
          ],
        );
      },
    );
  }
}
