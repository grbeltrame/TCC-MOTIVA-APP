// lib/shared/widgets/exercise_weekly_summary_complex_card.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/exercise_weekly_summary_service.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart'
    show StimulusCount;

class ExerciseWeeklySummaryComplexCard extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  const ExerciseWeeklySummaryComplexCard({Key? key, this.from, this.to})
    : super(key: key);

  static const _pieColors = [
    AppColors.baseMagenta,
    AppColors.baseBlue,
    AppColors.darkBlue,
    AppColors.lightBlue,
    AppColors.lightMagenta,
  ];

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final scale = screenW / 375.0;

    // Pizza menor pra manter o card compacto
    final pieSize = screenW * 0.25;

    return FutureBuilder<ComplexExerciseSummary>(
      future: ExerciseWeeklySummaryService.fetchComplexSummary(
        from: from,
        to: to,
      ),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            height: 140 * scale,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return _EmptyCard(scale: scale, message: 'Erro ao carregar resumo');
        }

        final summary = snap.data!;
        final total = summary.distribution.fold<int>(
          0,
          (sum, d) => sum + d.count,
        );

        return Card(
          margin: EdgeInsets.symmetric(vertical: 3 * scale),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.mediumGray),
            borderRadius: BorderRadius.circular(14 * scale),
          ),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              10 * scale,
              8 * scale,
              10 * scale,
              9 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título padronizado
                Text(
                  'DISTRIBUIÇÃO DE ESTÍMULOS',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5 * scale,
                    color: AppColors.darkBlue,
                    letterSpacing: 0.7,
                  ),
                ),
                SizedBox(height: 6 * scale),

                if (summary.distribution.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8 * scale),
                    child: Text(
                      'Nenhum estímulo registrado no período.',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 11.5 * scale,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  )
                else ...[
                  // ── Conteúdo: pizza (esq) + bloco estruturado (dir) ──────
                  SizedBox(
                    height: pieSize,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: pieSize,
                          height: pieSize,
                          child: SfCircularChart(
                            margin: EdgeInsets.zero,
                            palette: _pieColors,
                            series: <PieSeries<StimulusCount, String>>[
                              PieSeries<StimulusCount, String>(
                                dataSource: summary.distribution,
                                xValueMapper: (d, _) => d.name,
                                yValueMapper: (d, _) => d.count,
                                dataLabelMapper: (d, _) =>
                                    d.name.substring(0, 1),
                                dataLabelSettings: DataLabelSettings(
                                  isVisible: true,
                                  labelPosition:
                                      ChartDataLabelPosition.inside,
                                  textStyle: TextStyle(
                                    fontSize: 10 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                radius: '100%',
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 12 * scale),

                        // Bloco à direita: tudo top-aligned com hierarquia clara
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Rótulo de seção (mesmo estilo do card title)
                              Text(
                                'ESTÍMULO PRINCIPAL',
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8.5 * scale,
                                  color: AppColors.darkBlue,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              SizedBox(height: 2 * scale),

                              // Nome em destaque
                              Text(
                                summary.predominantStimulus,
                                style: TextStyle(
                                  fontFamily: AppFonts.montserrat,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17 * scale,
                                  color: AppColors.darkBlue,
                                  height: 1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Separador sutil
                              SizedBox(height: 6 * scale),
                              Container(
                                height: 1,
                                width: 24 * scale,
                                color: AppColors.mediumGray
                                    .withValues(alpha: 0.35),
                              ),
                              SizedBox(height: 6 * scale),

                              // Insight curto
                              Expanded(
                                child: Text(
                                  summary.shortInsight,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontSize: 9.5 * scale,
                                    color: AppColors.darkText,
                                    height: 1.25,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8 * scale),

                  // Legenda compacta
                  Wrap(
                    spacing: 7 * scale,
                    runSpacing: 3 * scale,
                    children: summary.distribution.asMap().entries.map((e) {
                      final color = _pieColors[e.key % _pieColors.length];
                      final pct = total > 0
                          ? ((e.value.count / total) * 100).round()
                          : 0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6 * scale,
                            height: 6 * scale,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 3 * scale),
                          Text(
                            '${e.value.name} $pct%',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontSize: 9 * scale,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final double scale;
  final String message;
  const _EmptyCard({required this.scale, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 3 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(14 * scale),
        child: Text(
          message,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 11.5 * scale,
            color: AppColors.mediumGray,
          ),
        ),
      ),
    );
  }
}
