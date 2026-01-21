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

  // Paleta fixa (mantém cores iguais no gráfico e na legenda)
  List<Color> _palette() => const [
    AppColors.baseBlue,
    AppColors.lightBlue,
    AppColors.baseMagenta,
    AppColors.lightMagenta,
    AppColors.darkBlue,
    AppColors.darkMagenta,
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final palette = _palette();

    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Topo: gráfico + textos (igual seu layout)
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

                      // ✅ cores consistentes
                      pointColorMapper: (d, i) => palette[i! % palette.length],

                      // ✅ remove labels dentro do gráfico (melhora legibilidade)
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

          // Legenda embaixo
          if (data.isNotEmpty) ...[
            SizedBox(height: 12 * scale),
            _LegendGrid(data: data, palette: palette, scale: scale),
          ],
        ],
      ),
    );
  }
}

class _LegendGrid extends StatelessWidget {
  final List<CycleStimulusSlice> data;
  final List<Color> palette;
  final double scale;

  const _LegendGrid({
    required this.data,
    required this.palette,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    // 2 colunas como padrão (melhor pra iPhone)
    // Se tiver muita coisa, ele quebra automaticamente (Wrap).
    return Wrap(
      spacing: 14 * scale,
      runSpacing: 10 * scale,
      children: List.generate(data.length, (i) {
        final d = data[i];
        final color = palette[i % palette.length];

        return SizedBox(
          width: 155 * scale, // ajustado pra caber 2 por linha
          child: Row(
            children: [
              Container(
                width: 10 * scale,
                height: 10 * scale,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                    color: AppColors.darkText,
                    fontWeight: AppFontWeight.medium,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
