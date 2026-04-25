// lib/shared/widgets/cards/week_points_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';

/// Card de "Pontos" — mostra o volume semanal em AU (Session-RPE) e a
/// base individual (carga crônica). Não exibe status de zona ACWR; isso
/// é responsabilidade do gráfico de Evolução, que cruza pontos × ICN.
///
/// Padrão visual alinhado a [WeekFrequencyCard] e [WeekEffortCard].
class WeekPointsCard extends StatelessWidget {
  final AthleteStatsSummary summary;

  const WeekPointsCard({Key? key, required this.summary}) : super(key: key);

  void _showInfoModal(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            titlePadding: EdgeInsets.fromLTRB(
              20 * scale,
              18 * scale,
              12 * scale,
              0,
            ),
            contentPadding: EdgeInsets.fromLTRB(
              20 * scale,
              12 * scale,
              20 * scale,
              4 * scale,
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'O que são os pontos da semana?',
                    style: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight: FontWeight.bold,
                      fontSize: 14 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  icon: Icon(
                    Icons.close,
                    size: 20 * scale,
                    color: AppColors.mediumGray,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 12 * scale,
                      color: AppColors.darkText,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text:
                            'Os pontos medem o seu desgaste real. São calculados pela fórmula:\n\n',
                      ),
                      TextSpan(
                        text: 'Pontos = Esforço × Duração do treino',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(
                        text:
                            '\n\nUm treino curto e leve gera poucos pontos, enquanto um longo e exaustivo gera muitos. É o histórico acumulado desses pontos que usamos para analisar a sua evolução e definir se a sua semana atual é de Recuperação, de Esforço Ideal ou de Sobrecarga.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actionsPadding: EdgeInsets.fromLTRB(
              12 * scale,
              0,
              12 * scale,
              10 * scale,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Entendi',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * scale,
                    color: AppColors.baseBlue,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final pts = summary.weeklyLoadAll;
    final hasData = pts > 0;
    final base = summary.weeklyCargaCronica;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 3 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12 * scale,
          10 * scale,
          8 * scale,
          11 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + botão de info
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'PONTOS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.bold,
                      fontSize: 10 * scale,
                      color: AppColors.darkBlue,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showInfoModal(context),
                  borderRadius: BorderRadius.circular(12 * scale),
                  child: Padding(
                    padding: EdgeInsets.all(2 * scale),
                    child: Icon(
                      Icons.info_outline,
                      size: 16 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6 * scale),

            // Valor principal (pontos da semana)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasData ? pts.toStringAsFixed(0) : '–',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: FontWeight.bold,
                    fontSize: 26 * scale,
                    color: AppColors.darkBlue,
                    height: 1,
                  ),
                ),
                if (hasData)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 4 * scale,
                      left: 3 * scale,
                    ),
                    child: Text(
                      'pts',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 12 * scale,
                        color: AppColors.mediumGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            // Base (carga crônica) — individualidade do atleta
            Text(
              base != null
                  ? 'base: ${base.toStringAsFixed(0)} pts'
                  : 'sem base ainda',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 10.5 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
