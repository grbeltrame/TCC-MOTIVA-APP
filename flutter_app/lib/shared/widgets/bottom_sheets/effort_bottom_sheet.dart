// lib/shared/widgets/effort_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/info_button.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:flutter_app/core/services/weekly_summary_service.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/core/services/highlights_service.dart';
import 'package:flutter_app/core/services/alerts_service.dart';

import 'package:flutter_app/shared/widgets/carousels/highlights_carousel.dart';
import 'package:flutter_app/shared/widgets/carousels/alerts_carousel.dart';

class EffortBottomSheet extends StatefulWidget {
  const EffortBottomSheet({Key? key}) : super(key: key);

  @override
  _EffortBottomSheetState createState() => _EffortBottomSheetState();
}

class _EffortBottomSheetState extends State<EffortBottomSheet> {
  final _weeklySvc = WeeklySummaryService();
  final _effortSvc = EffortService();
  final _highlightsSvc = HighlightsService();
  final _alertsSvc = AlertsService();

  late Future<WeekRange> _weekFut;
  late Future<List<DailyEffort>> _effortFut;
  late Future<List<HighlightModel>> _highlightsFut;
  late Future<List<AlertModel>> _alertsFut;

  @override
  void initState() {
    super.initState();
    // 1) buscamos o intervalo da semana corrente
    _weekFut = Future.value(_weeklySvc.fetchCurrentWeekRange());

    // 2) quando tivermos a semana, disparamos os outros carregamentos
    _weekFut.then((week) {
      _effortFut = _effortSvc.fetchWeeklyEffortSeries(week);
      _highlightsFut = _highlightsSvc.fetchWeeklyHighlights(week);
      _alertsFut = _alertsSvc.fetchWeeklyAlerts(week);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return FutureBuilder<WeekRange>(
      future: _weekFut,
      builder: (ctx, snapWeek) {
        if (!snapWeek.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final fmt = DateFormat('d/MM');

        return AppBottomSheet(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20 * scale,
              vertical: 20 * scale,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Título e gráfico de esforço ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Seu Esforço essa semana',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 8 * scale),
                Container(
                  height: 200 * scale,
                  decoration: BoxDecoration(
                    color: Colors.white, // fundo branco
                    borderRadius: BorderRadius.circular(8 * scale),
                    border: Border.all(
                      color: AppColors.mediumGray,
                    ), // borda cinza
                  ),
                  padding: EdgeInsets.all(
                    8 * scale,
                  ), // se quiser um pequeno padding interno
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1) título "Esforço" + InfoButton
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Esforço',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontWeight: FontWeight.bold,
                                fontSize: 16 * scale,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                          InfoButton(
                            message:
                                'Toque ou segure nos pontos do gráfico\npara ver o valor exato.',
                          ),
                        ],
                      ),

                      // 2) o gráfico em si
                      Expanded(
                        child: FutureBuilder<List<DailyEffort>>(
                          future: _effortFut,
                          builder: (ctx, snapE) {
                            if (!snapE.hasData)
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            return SfCartesianChart(
                              primaryXAxis: CategoryAxis(
                                majorGridLines: MajorGridLines(width: 0),
                                labelStyle: TextStyle(
                                  fontSize: 12 * scale,
                                  color: AppColors.darkText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              primaryYAxis: NumericAxis(
                                minimum: 0,
                                maximum: 10,
                                interval: 2,
                                majorGridLines: MajorGridLines(width: 0.5),
                                axisLine: AxisLine(width: 0),
                                labelStyle: TextStyle(
                                  fontSize: 12 * scale,
                                  color: AppColors.darkText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              series: <LineSeries<DailyEffort, String>>[
                                LineSeries<DailyEffort, String>(
                                  dataSource: snapE.data!,
                                  xValueMapper: (d, _) => fmt.format(d.date),
                                  yValueMapper: (d, _) => d.percent,
                                  markerSettings: const MarkerSettings(
                                    isVisible: true,
                                  ),
                                  enableTooltip: true,
                                ),
                              ],
                              // 2) Ativa um tooltip simples
                              tooltipBehavior: TooltipBehavior(
                                enable: true,
                                header: '', // remove cabeçalho extra
                                // aumenta a fonte e coloca texto branco
                                textStyle: TextStyle(
                                  fontSize: 16 * scale,
                                  color: Colors.white,
                                ),
                                borderColor: AppColors.baseBlue,
                                borderWidth: 1,
                                canShowMarker: true,
                              ),

                              // (Opcional) Se quiser um “cross‑hair” que aparece no tap:
                              trackballBehavior: TrackballBehavior(
                                enable: true,
                                activationMode: ActivationMode.singleTap,
                                tooltipSettings: InteractiveTooltip(
                                  format: 'Esforço em point.x: point.y',
                                  textStyle: TextStyle(
                                    fontSize: 16 * scale,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16 * scale),
                const Divider(),
                SizedBox(height: 16 * scale),

                // --- Destaques Inteligentes ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Destaques Inteligentes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 8 * scale),
                FutureBuilder<List<HighlightModel>>(
                  future: _highlightsFut,
                  builder: (ctx, snapH) {
                    if (!snapH.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final highlights = snapH.data!;
                    // os tipos já foram filtrados pelo serviço
                    final types = highlights.map((h) => h.type).toSet();
                    return HighlightsCarousel(
                      allHighlights: highlights,
                      enabledHighlightsTypes: types,
                    );
                  },
                ),

                SizedBox(height: 16 * scale),

                // --- Alertas ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Alertas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 8 * scale),
                FutureBuilder<List<AlertModel>>(
                  future: _alertsFut,
                  builder: (ctx, snapA) {
                    if (!snapA.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final alerts = snapA.data!;
                    final types = alerts.map((a) => a.type).toSet();
                    return AlertsCarousel(
                      allAlerts: alerts,
                      enabledTypes: types,
                    );
                  },
                ),
                SizedBox(height: 8 * scale),

                // --- Botões no rodapé ---
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24 * scale),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: AppTheme.secondaryButtonStyle(
                          AppColors.darkBlue,
                          AppColors.baseBlue,
                        ),
                        onPressed: () {
                          // TODO: implementar ação de "Registrar Esforço"
                        },
                        child: const Text('Registrar Esforço'),
                      ),

                      OutlinedButton(
                        style: AppTheme.tertiaryButtonStyle(
                          AppColors.baseMagenta,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
