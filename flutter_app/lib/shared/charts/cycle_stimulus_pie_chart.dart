// lib/shared/charts/cycle_stimulus_pie_chart.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/models/cycle_models.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CycleStimulusPieCard extends StatelessWidget {
  final List<CycleStimulusSlice> data;
  final String biggestLabel;

  const CycleStimulusPieCard({
    super.key,
    required this.data,
    required this.biggestLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // topo: gráfico + textos
          Row(
            children: [
              SizedBox(
                width: 120 * scale,
                height: 120 * scale,
                child: SfCircularChart(
                  margin: EdgeInsets.zero,
                  series: <CircularSeries<CycleStimulusSlice, String>>[
                    PieSeries<CycleStimulusSlice, String>(
                      dataSource: data,
                      xValueMapper: (d, _) => d.stimulus,
                      yValueMapper: (d, _) => d.count,

                      // ✅ melhor legibilidade: sem labels dentro do gráfico
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: false,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Essa é a distribuição de estímulos\ndo ciclo',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 12 * scale,
                        color: AppColors.darkText,
                        height: 1.2,
                        fontWeight: AppFontWeight.medium,
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Text(
                      biggestLabel,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 12 * scale,
                        color: AppColors.darkText,
                        height: 1.2,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12 * scale),

          // ✅ legenda em 2 colunas
          _LegendGrid2Cols(data: data),
        ],
      ),
    );
  }
}

/// Legenda compacta em 2 colunas.
/// Observação: por enquanto usamos uma paleta fixa (mock).
class _LegendGrid2Cols extends StatelessWidget {
  final List<CycleStimulusSlice> data;
  const _LegendGrid2Cols({required this.data});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final palette = <Color>[
      AppColors.baseBlue,
      AppColors.lightMagenta,
      AppColors.darkBlue,
      AppColors.baseMagenta,
      AppColors.mediumGray,
      AppColors.lightBlue,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8 * scale,
        crossAxisSpacing: 10 * scale,
        childAspectRatio: 5.2, // controla a altura do item (mais compacto)
      ),
      itemBuilder: (_, i) {
        final d = data[i];
        final color = palette[i % palette.length];

        return Row(
          children: [
            Container(
              width: 10 * scale,
              height: 10 * scale,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3 * scale),
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Text(
                '${d.stimulus} (${d.count})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 12 * scale,
                  fontWeight: AppFontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
