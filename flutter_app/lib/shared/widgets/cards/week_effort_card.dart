// lib/shared/widgets/cards/week_effort_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';

/// Card de esforço médio semanal com barra colorida.
/// Azul < 5 | Cinza 5–6 | Vermelho ≥ 7
class WeekEffortCard extends StatelessWidget {
  final AthleteStatsSummary summary;

  const WeekEffortCard({Key? key, required this.summary}) : super(key: key);

  Color _barColor(double score) {
    if (score < 5) return AppColors.baseBlue;
    if (score < 7) return AppColors.mediumGray;
    return AppColors.baseMagenta;
  }

  String _comment(double score) {
    if (score == 0) return 'Sem treinos';
    if (score < 4) return 'Semana tranquila';
    if (score < 6) return 'Intensidade moderada';
    if (score < 8) return 'Semana intensa';
    return 'Muito intensa';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final score = summary.averageEffortCurrentWeek;
    final hasData = score > 0;
    final barColor = _barColor(score);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 3 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12 * scale, 10 * scale, 12 * scale, 11 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'ESFORÇO MÉDIO',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 10 * scale,
                color: AppColors.darkBlue,
                letterSpacing: 0.7,
              ),
            ),
            SizedBox(height: 6 * scale),

            // Número grande
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hasData ? score.toStringAsFixed(1) : '–',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: FontWeight.bold,
                    fontSize: 26 * scale,
                    color: barColor,
                    height: 1,
                  ),
                ),
                if (hasData)
                  Padding(
                    padding: EdgeInsets.only(bottom: 4 * scale, left: 3 * scale),
                    child: Text(
                      '/10',
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

            Text(
              _comment(score),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 10.5 * scale,
                color: AppColors.mediumGray,
              ),
            ),

            SizedBox(height: 8 * scale),

            // Barra de progresso colorida
            ClipRRect(
              borderRadius: BorderRadius.circular(3 * scale),
              child: LinearProgressIndicator(
                value: hasData ? (score / 10).clamp(0.0, 1.0) : 0,
                backgroundColor: AppColors.lightGray,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 4 * scale,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
