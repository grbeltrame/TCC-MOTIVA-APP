import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/goal_service.dart';

/// Section "Selos e Conquistas"
/// - mostra apenas os badges das metas CONCLUÍDAS
/// - corta a lista para caber em UMA linha (varia por aparelho)
/// - o CTA "Ver todos os selos" navega por conta própria
class AchievementsBadgesSection extends StatelessWidget {
  /// Rota genérica para a lista completa de selos
  final String seeAllRoute;

  /// Tamanho do selo (lado do hex/ícone)
  final double badgeSize;

  const AchievementsBadgesSection({
    Key? key,
    this.seeAllRoute = '/badges', // TODO: troque pela sua rota real
    this.badgeSize = 64,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final gap = 10 * scale;

    return FutureBuilder<List<String>>(
      future: GoalService.fetchCompletedBadges(), // <-- novo no service
      builder: (ctx, snap) {
        final isLoading = snap.connectionState != ConnectionState.done;
        final badges = snap.data ?? const <String>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título + CTA
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Selos e Conquistas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: chamar fluxo de adicionar campeonato
                  },
                  icon: Icon(
                    Icons.add,
                    size: 20 * scale,
                    color: AppColors.baseBlue,
                  ),
                  label: Text(
                    'Ver todos os selos',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.medium,
                      fontSize: 12 * scale,
                      color: AppColors.baseBlue,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6 * scale),

            if (isLoading)
              SizedBox(
                height: badgeSize * scale,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (badges.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8 * scale),
                child: Text(
                  'Nenhum selo ainda',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14 * scale,
                    color: AppColors.darkText.withOpacity(0.7),
                  ),
                ),
              )
            else
              // Só renderiza o que CABE em uma linha
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (badgeSize * scale);
                  final perRow =
                      itemWidth <= 0
                          ? badges.length
                          : ((constraints.maxWidth + gap) / (itemWidth + gap))
                              .floor()
                              .clamp(0, badges.length);
                  final toShow = badges.take(perRow).toList();

                  return Row(
                    children: [
                      for (int i = 0; i < toShow.length; i++) ...[
                        SizedBox(
                          width: itemWidth,
                          height: itemWidth,
                          child: Image.asset(
                            toShow[i], // caminho do PNG/SVG do badge
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (i < toShow.length - 1) SizedBox(width: gap),
                      ],
                    ],
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
