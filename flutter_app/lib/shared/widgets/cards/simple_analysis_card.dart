// lib/shared/widgets/simple_analysis_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/analysis_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_app/shared/models/analysis_summary.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Um único “card” de análise simples + destaque abaixo:
///  • largura = 0.9 da largura da tela
///  • cabeçalho: título do gráfico + dropdown de intervalo
///  • gráficos cartesianos para todos os tipos
///  • fundo transparente + borda cinza arredondada
///  • abaixo do card: texto “Destaque:” + frase de destaque
class SimpleAnalysisCard extends StatefulWidget {
  final AnalysisSummary summary;
  const SimpleAnalysisCard({super.key, required this.summary});

  @override
  _SimpleAnalysisCardState createState() => _SimpleAnalysisCardState();
}

class _SimpleAnalysisCardState extends State<SimpleAnalysisCard> {
  static const _intervals = [
    '7 dias',
    '15 dias',
    '30 dias',
    '60 dias',
    '90 dias',
  ];
  late String _selectedInterval;

  static const _typeLabels = {
    AnalysisType.effort: 'Esforço',
    AnalysisType.frequency: 'Frequência',
    AnalysisType.volume: 'Volume',
    AnalysisType.load: 'Carga',
  };

  @override
  void initState() {
    super.initState();
    _selectedInterval = _intervals[2]; // "30 dias" por padrão
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final scale = screenW / 375.0;
    final cardW = screenW * 0.9;

    // Escolhe o gráfico conforme o tipo (todos cartesianos)
    late final Widget chart;
    switch (widget.summary.type) {
      case AnalysisType.effort:
        // dentro do seu case AnalysisType.effort:
        final days = widget.summary.intervalDays;
        final intervalCount = (days / 6).ceil();

        chart = SfCartesianChart(
          primaryXAxis: DateTimeAxis(
            intervalType: DateTimeIntervalType.days,
            interval: intervalCount.toDouble(), // <-- converte para double
            dateFormat: DateFormat('dd/MM'),
            edgeLabelPlacement: EdgeLabelPlacement.shift,
            majorGridLines: const MajorGridLines(width: 0),
            labelRotation: -45,
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: 10,
            interval: 2,
            majorGridLines: const MajorGridLines(width: 0.5),
            axisLine: const AxisLine(width: 0),
          ),
          series: <SplineAreaSeries<ChartData, DateTime>>[
            SplineAreaSeries<ChartData, DateTime>(
              dataSource: widget.summary.data,
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y,
              markerSettings: const MarkerSettings(isVisible: true),
              color: AppColors.baseBlue.withOpacity(0.3),
            ),
          ],
          tooltipBehavior: TooltipBehavior(
            enable: true,
            header: '',
            canShowMarker: true,
            textStyle: TextStyle(fontSize: 16 * scale, color: Colors.white),
            borderColor: AppColors.baseBlue,
            borderWidth: 1,
          ),
          trackballBehavior: TrackballBehavior(
            enable: true,
            activationMode: ActivationMode.singleTap,
            tooltipSettings: InteractiveTooltip(
              format: 'point.x : point.y',
              textStyle: TextStyle(fontSize: 16 * scale, color: Colors.white),
            ),
          ),
        );

      case AnalysisType.frequency:
        chart = SfCartesianChart(
          primaryXAxis: CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
          primaryYAxis: NumericAxis(minimum: 0),
          series: <ColumnSeries<ChartData, String>>[
            ColumnSeries<ChartData, String>(
              dataSource: widget.summary.data,
              xValueMapper:
                  (d, _) => DateFormat.E('pt_BR').format(d.x).substring(0, 1),
              yValueMapper: (d, _) => d.y,
              color: AppColors.lightBlue,
            ),
          ],
          tooltipBehavior: TooltipBehavior(enable: true),
        );
        break;

      case AnalysisType.volume:
        chart = SfCartesianChart(
          primaryXAxis: DateTimeAxis(isVisible: false),
          primaryYAxis: NumericAxis(isVisible: false),
          series: <StackedAreaSeries<ChartData, DateTime>>[
            StackedAreaSeries<ChartData, DateTime>(
              dataSource: widget.summary.data,
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y * 0.6,
              color: AppColors.baseBlue.withOpacity(0.6),
            ),
            StackedAreaSeries<ChartData, DateTime>(
              dataSource: widget.summary.data,
              xValueMapper: (d, _) => d.x,
              yValueMapper: (d, _) => d.y * 0.4,
              color: AppColors.lightBlue.withOpacity(0.6),
            ),
          ],
        );
        break;

      case AnalysisType.load:
        chart = SfCartesianChart(
          primaryXAxis: CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: widget.summary.yMax,
            interval: (widget.summary.yMax / 5).ceilToDouble(),
            axisLine: const AxisLine(width: 0),
          ),
          series: <LineSeries<ChartData, String>>[
            LineSeries<ChartData, String>(
              dataSource: widget.summary.data,
              xValueMapper:
                  (d, _) => DateFormat.E('pt_BR').format(d.x).substring(0, 1),
              yValueMapper: (d, _) => d.y,
              markerSettings: const MarkerSettings(isVisible: true),
              width: 2 * scale,
              color: AppColors.darkBlue,
            ),
          ],
          tooltipBehavior: TooltipBehavior(enable: true),
        );
        break;
    }

    return SizedBox(
      width: cardW,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Container do gráfico ───
          Container(
            padding: EdgeInsets.all(12 * scale),
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.mediumGray),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cabeçalho: título + dropdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _typeLabels[widget.summary.type]!,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 14 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _selectedInterval,
                      underline: const SizedBox.shrink(),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        size: 20 * scale,
                        color: AppColors.darkText,
                      ),
                      items:
                          _intervals
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    i,
                                    style: TextStyle(fontSize: 12 * scale),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedInterval = v);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8 * scale),
                SizedBox(height: 120 * scale, child: chart),
              ],
            ),
          ),

          SizedBox(height: 8 * scale),

          // ─── Destaque abaixo do gráfico ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 4 * scale),
                child: Text(
                  'Destaque:',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 12 * scale,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
              SizedBox(width: 4 * scale),
              Expanded(
                child: Text(
                  widget.summary.highlight,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    height: 1.3,
                    color: AppColors.darkText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
