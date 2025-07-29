// lib/shared/widgets/exercise_weekly_summary_complex_card.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/exercise_weekly_summary_service.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart'
    show StimulusCount;

class ExerciseWeeklySummaryComplexCard extends StatelessWidget {
  const ExerciseWeeklySummaryComplexCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final scale = screenW / 375.0;

    // Mesma proporção do simples: 32% da largura
    final indicatorW = screenW * 0.32;
    final gap = screenW * 0.06;

    return FutureBuilder<ComplexExerciseSummary>(
      future: ExerciseWeeklySummaryService.fetchComplexSummary(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) {
          return const Center(child: Text('Erro ao carregar resumo completo'));
        }

        final summary = snap.data!;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 2 * scale),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent, // fundo transparente
              border: Border.all(
                color: AppColors.mediumGray, // borda cinza
                width: 1 * scale,
              ),
              borderRadius: BorderRadius.circular(16 * scale),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 4 * scale,
              ),
              child: SizedBox(
                height: indicatorW,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Coluna 1: gráfico de pizza dos estímulos
                    SizedBox(
                      width: indicatorW,
                      height: indicatorW,
                      child: SfCircularChart(
                        palette: [
                          AppColors.baseMagenta,
                          AppColors.baseBlue,
                          AppColors.darkBlue,
                        ],
                        series: <PieSeries<StimulusCount, String>>[
                          PieSeries<StimulusCount, String>(
                            dataSource: summary.distribution,
                            xValueMapper: (d, _) => d.name,
                            yValueMapper: (d, _) => d.count,
                            dataLabelMapper: (d, _) => d.name.substring(0, 1),
                            dataLabelSettings: DataLabelSettings(
                              isVisible: true,
                              labelPosition: ChartDataLabelPosition.inside,
                              textStyle: TextStyle(
                                fontSize: 12 * scale,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            radius: '100%',
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: gap),

                    // Coluna 2: textos alinhados verticalmente ao centro
                    Expanded(
                      child: SizedBox(
                        height: indicatorW,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Olá, ${summary.userName}!',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontWeight: AppFontWeight.bold,
                                fontSize: 14 * scale,
                                color: AppColors.darkText,
                              ),
                            ),
                            SizedBox(height: 4 * scale),

                            Text(
                              'Essa é a sua distribuição de estímulos da semana',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontWeight: AppFontWeight.regular,
                                fontSize: 12 * scale,
                                color: AppColors.darkText,
                              ),
                            ),
                            SizedBox(height: 4 * scale),

                            Text(
                              '${summary.predominantStimulus} – ${summary.shortInsight}',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontWeight: AppFontWeight.medium,
                                fontSize: 12 * scale,
                                color: AppColors.darkText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
