import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/shared/widgets/goal_card_widget.dart';

/// Seção “Progresso Próximo”
/// Mostra apenas goals com progresso >= 80% (configurável no service).
/// Só aparece se o usuário tiver habilitado essa seção (mockado).
class NearCompletionSection extends StatelessWidget {
  const NearCompletionSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<bool>(
      future: GoalService.fetchShowNearCompleteSection(),
      builder: (ctx, snapShow) {
        if (snapShow.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        if (snapShow.data != true) {
          // usuário desabilitou a seção
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<Goal>>(
          future: GoalService.fetchNearCompleteGoals(minProgress: 0.8),
          builder: (ctx2, snapGoals) {
            if (snapGoals.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final goals = snapGoals.data!;

            // se não houver nenhum quase completo, mostramos apenas mensagem
            if (goals.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 12 * scale,
                ),
                child: Text(
                  'Nenhum progresso próximo de conclusão',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14 * scale,
                    color: AppColors.mediumGray,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // título da seção
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Text(
                    'Progresso próximo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 8 * scale),

                // lista dos cards
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Column(
                    children:
                        goals.map((g) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 12 * scale),
                            child: GoalCardWidget(
                              badgeAsset: g.badgeAsset,
                              title: g.title,
                              deadlineWeeks: g.deadlineWeeks,
                              startDate: g.startDate,
                              unitsPerWeek: g.unitsPerWeek,
                              completedUnits: g.completedUnits,
                              showAddButton: false,
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
