/// lib/shared/widgets/weekly_statistics_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/mini_card_widget.dart';
import 'package:flutter_app/core/services/weekly_stats_service.dart';
import 'package:flutter_svg/svg.dart';

/// Exibe título fixo e três MiniCards com stats da semana:
/// • Cargas médias (total kg)
/// • Frequência (nº de treinos)
/* • Esforço médio (valor 0–10) */
class WeeklyStatisticsWidget extends StatelessWidget {
  const WeeklyStatisticsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Título fixo ---
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Text(
            'Estatísticas da Semana',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: 16 * scale),

        // --- Linha de MiniCards semanais ---
        Row(
          children: [
            Expanded(
              child: MiniCardWidget(
                iconWidget: SvgPicture.asset(
                  'assets/icons/exercise.svg',
                  width: 16,
                  height: 16,
                  color: AppColors.darkText, // se você quiser aplicar color
                ),
                title: 'Cargas',
                tipo: WeeklyStatsType.cargas,
                borderColor: AppColors.darkBlue,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
              ),
            ),
            SizedBox(width: 6 * scale),
            Expanded(
              child: MiniCardWidget(
                iconWidget: Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: AppColors.darkText,
                ),
                title: 'Frequência',
                tipo: WeeklyStatsType.frequencia,
                borderColor: AppColors.darkBlue,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
              ),
            ),
            SizedBox(width: 6 * scale),
            Expanded(
              child: MiniCardWidget(
                iconWidget: SvgPicture.asset(
                  'assets/icons/relax.svg',
                  width: 16,
                  height: 16,
                  color: AppColors.darkText, // se você quiser aplicar color
                ), // ou outro ícone de esforço
                title: 'Esforço',
                tipo: WeeklyStatsType.esforco,
                borderColor: AppColors.darkBlue,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
