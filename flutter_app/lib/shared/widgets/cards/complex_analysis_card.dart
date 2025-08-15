import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/analysis_service.dart';
import 'package:flutter_app/shared/models/analysis_summary.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Card de análise **complexa**:
/// – largura = 100%
/// – cabeçalho: título genérico + dropdown de intervalo
/// – TODO: mock de gráfico + destaque (igual ao simples, mas sem carrossel)
class ComplexAnalysisCard extends StatefulWidget {
  final AnalysisType type;
  const ComplexAnalysisCard({super.key, required this.type});

  @override
  State<ComplexAnalysisCard> createState() => _ComplexAnalysisCardState();
}

class _ComplexAnalysisCardState extends State<ComplexAnalysisCard> {
  static const _intervals = [
    '7 dias',
    '15 dias',
    '30 dias',
    '60 dias',
    '90 dias',
  ];
  late String _selectedInterval;
  late Future<AnalysisSummary> _fut;

  static const _labels = {
    AnalysisType.effort: 'Movimentos',
    AnalysisType.frequency: 'WODs',
    AnalysisType.volume: 'Volume',
    AnalysisType.load: 'Carga', // não usada aqui
  };

  @override
  void initState() {
    super.initState();
    _selectedInterval = _intervals[2]; // 30 dias padrão
    _load();
  }

  void _load() {
    final days = int.parse(_selectedInterval.split(' ')[0]);
    // TODO: criar fetchSummaryByType no service
    _fut = AnalysisService.fetchSummaryByType(
      type: widget.type,
      intervalDays: days,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final scale = screenW / 375.0;

    return FutureBuilder<AnalysisSummary>(
      future: _fut,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final s = snap.data!;
        // gráfico de mock — substituir pelo real quando houver backend
        final chart = SfCartesianChart(
          primaryXAxis: CategoryAxis(majorGridLines: MajorGridLines(width: 0)),
          series: [
            LineSeries<ChartData, String>(
              dataSource: s.data,
              xValueMapper: (d, _) => DateFormat('dd/MM').format(d.x),
              yValueMapper: (d, _) => d.y,
            ),
          ],
          tooltipBehavior: TooltipBehavior(enable: true),
        );

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Card sem fundo e sem borda
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
                    // cabeçalho
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _labels[widget.type]!,
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
                            setState(() {
                              _selectedInterval = v!;
                              _load();
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * scale),

                    // gráfico
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
                      s.highlight,
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
      },
    );
  }
}
