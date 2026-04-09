// lib/shared/widgets/cards/week_frequency_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';

/// Card de frequência semanal: "X de 7 dias treinados".
class WeekFrequencyCard extends StatelessWidget {
  final AthleteStatsSummary summary;

  const WeekFrequencyCard({Key? key, required this.summary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final count = summary.currentWeekTrainingDays;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 * scale, 14 * scale, 16 * scale, 16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'FREQUÊNCIA',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 11 * scale,
                color: AppColors.darkBlue,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10 * scale),

            // Número grande
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: FontWeight.bold,
                    fontSize: 44 * scale,
                    color: AppColors.darkBlue,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 7 * scale, left: 4 * scale),
                  child: Text(
                    'de 7',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 14 * scale,
                      color: AppColors.mediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            Text(
              count == 1 ? 'dia treinado' : 'dias treinados',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),

            SizedBox(height: 12 * scale),

            // Barra de progresso discreta (7 segmentos)
            Row(
              children: List.generate(7, (i) {
                final filled = i < count;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 6 ? 3 * scale : 0),
                    height: 5 * scale,
                    decoration: BoxDecoration(
                      color: filled ? AppColors.baseBlue : AppColors.lightGray,
                      borderRadius: BorderRadius.circular(3 * scale),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
