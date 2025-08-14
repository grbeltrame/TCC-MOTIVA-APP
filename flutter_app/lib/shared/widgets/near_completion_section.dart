import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
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

/// Section: AlmostReachedGoalsSection
/// Mesma lógica/visual, mas com título, label e navegação configuráveis.
class AlmostReachedGoalsSection extends StatelessWidget {
  const AlmostReachedGoalsSection({
    Key? key,
    this.title = 'Metas proximas', // título padrão
    this.buttonLabel = 'Ver todas as metas', // label padrão
    this.buttonIcon = Icons.add, // ícone padrão
    this.routeName, // use pushNamed se informado
    this.onButtonPressed, // ou passe um callback
    this.minProgress = 0.8, // mesmas metas por padrão
    this.showCta = true, // mostrar CTA ao lado do título
  }) : super(key: key);

  /// Título da seção.
  final String title;

  /// Rótulo do botão à direita do título.
  final String buttonLabel;

  /// Ícone do botão (mantém o mesmo do exemplo por padrão).
  final IconData buttonIcon;

  /// Nome da rota a navegar com Navigator.pushNamed, se fornecido.
  final String? routeName;

  /// Callback de clique no botão (tem prioridade sobre [routeName], se ambos forem passados).
  final VoidCallback? onButtonPressed;

  /// Threshold para considerar meta “quase atingida”.
  final double minProgress;

  /// Exibe (ou não) o CTA ao lado do título.
  final bool showCta;

  void _handleCtaTap(BuildContext context) {
    if (onButtonPressed != null) {
      onButtonPressed!.call();
      return;
    }
    if (routeName != null) {
      Navigator.pushNamed(context, routeName!);
      return;
    }
    // Se nada foi passado, não faz nada (ou poderia exibir um SnackBar)
  }

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
          return const SizedBox.shrink();
        }

        return FutureBuilder<List<Goal>>(
          future: GoalService.fetchNearCompleteGoals(minProgress: minProgress),
          builder: (ctx2, snapGoals) {
            if (snapGoals.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final goals = snapGoals.data ?? [];

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
                // Título + CTA (configuráveis)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      if (showCta)
                        TextButton.icon(
                          onPressed: () => _handleCtaTap(context),
                          icon: Icon(
                            buttonIcon,
                            size: 16 * scale,
                            color: AppColors.baseBlue,
                          ),
                          label: Text(
                            buttonLabel,
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: AppFontWeight.regular,
                              fontSize: 12 * scale,
                              color: AppColors.baseBlue,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6 * scale,
                              vertical: 0,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 8 * scale),

                // Lista dos cards (mesmos cards)
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
