// lib/features/user/athlete/athlete_pr_item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/carousels/highlights_carousel.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/workout/pr_service.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/models/inisght_model.dart';
import 'package:flutter_app/shared/widgets/register_pr/register_pr_bottom_sheet.dart';

// NEW: bottom sheet de perfis semelhantes
import 'package:flutter_app/shared/widgets/bottom_sheets/similar_profile_bottom_sheets.dart';

// headers / cards
import 'package:flutter_app/shared/widgets/pr_item/pr_item_header_movement.dart';
import 'package:flutter_app/shared/widgets/pr_item/pr_item_header_wod.dart';

// container de gráfico com dropdown
import 'package:flutter_app/shared/widgets/pr_item/pr_line_chart_card.dart';

class AthletePrItemScreen extends StatefulWidget {
  static const routeName = '/athlete_pr_item';
  const AthletePrItemScreen({Key? key}) : super(key: key);

  @override
  State<AthletePrItemScreen> createState() => _AthletePrItemScreenState();
}

class _AthletePrItemScreenState extends State<AthletePrItemScreen> {
  // args
  late String _label;
  late PrCategory _category;

  // controle de bootstrap dos argumentos
  bool _bootstrapped = false;

  // states para gráficos
  int _periodDays = 30;

  // dados
  Future<String>? _movementDescFut;
  Future<PrBenchmark?>? _benchmarkFut;
  Future<List<String>>? _wodLinesFut;

  Future<List<TimePoint>>? _seriesMovementFut;
  Future<List<TimePoint>>? _seriesWodPerfFut; // time OR reps
  Future<List<TimePoint>>? _seriesWodLoadFut;
  Future<List<MovementVolumePoint>>? _seriesWodVolumeFut;

  Future<List<InsightsModel>>? _insightsFut;

  @override
  void initState() {
    super.initState();
    // NÃO leia ModalRoute.of(context) aqui
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;

    final args =
        (ModalRoute.of(context)?.settings.arguments as Map?) ?? const {};
    _label = (args['label'] ?? '') as String;
    _category = args['category'] as PrCategory? ?? PrCategory.lpo;

    _reloadData();
    _bootstrapped = true;
  }

  void _reloadData() {
    // header
    if (_category == PrCategory.wod) {
      _benchmarkFut = PRService.findBenchmarkByName(_label);
      _wodLinesFut = PRService.fetchWodLinesByName(_label);
    } else {
      _movementDescFut = PRService.fetchMovementDescription(_label);
    }

    // series
    if (_category == PrCategory.wod) {
      _seriesWodLoadFut = PRService.fetchWodLoadSeries(_label);
      _seriesWodVolumeFut = PRService.fetchWodAdaptedVolume(_label);
      _seriesWodPerfFut = _benchmarkFut!.then((b) {
        if (b?.type == PrWodType.amrap) {
          return PRService.fetchWodRepsSeries(_label);
        }
        return PRService.fetchWodTimeSeries(_label);
      });
    } else {
      _seriesMovementFut = PRService.fetchMovementSeries(
        _label,
        days: _periodDays,
      );
    }

    // insights
    _insightsFut = PRService.fetchPrInsights(
      category: _category,
      label: _label,
    );

    setState(() {});
  }

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  Future<void> _onRegisterResult() async {
    await showRegisterPrBottomSheet(context);
    if (!mounted) return;
    _reloadData(); // reconsulta séries e insights
  }

  // NEW: abre o bottom sheet de perfis semelhantes
  Future<void> _openSimilarProfiles() async {
    await showSimilarProfilesBottomSheet(
      context,
      benchmarkName: _category == PrCategory.wod ? _label : null,
      movementName: _category != PrCategory.wod ? _label : null,
      onTapRegister: _onRegisterResult, // nesta tela sempre registramos PR
    );
    if (!mounted) return;
    _reloadData();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // back
          Padding(
            padding: EdgeInsets.only(
              top: 8 * scale,
              left: 6 * scale,
              right: 6 * scale,
            ),
            child: const AppBackButton(),
          ),

          // conteúdo
          Expanded(
            child:
                !_bootstrapped
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ====== HEADER / CARD ======
                          if (_category == PrCategory.wod)
                            FutureBuilder<PrBenchmark?>(
                              future: _benchmarkFut,
                              builder: (ctx, snapB) {
                                final bench = snapB.data;
                                return FutureBuilder<List<String>>(
                                  future: _wodLinesFut,
                                  builder: (c2, snapLines) {
                                    final lines =
                                        snapLines.data ?? const <String>[];
                                    return PrItemHeaderWod(
                                      wodName: _label,
                                      lines: lines,
                                      onRegister: _onRegisterResult,
                                      onSeeSimilarProfiles:
                                          _openSimilarProfiles, // NEW
                                    );
                                  },
                                );
                              },
                            )
                          else
                            FutureBuilder<String>(
                              future: _movementDescFut,
                              builder: (ctx, snap) {
                                final desc =
                                    snap.hasData
                                        ? snap.data!
                                        : 'Descrição do movimento';
                                return PrItemHeaderMovement(
                                  movementName: _label,
                                  description: desc,
                                  onRegister: _onRegisterResult,
                                );
                              },
                            ),

                          SizedBox(height: 16 * scale),

                          // ====== GRÁFICOS ======
                          if (_category == PrCategory.wod)
                            _WodCharts(
                              wodName: _label,
                              benchmarkFut: _benchmarkFut!,
                              perfSeriesFut: _seriesWodPerfFut!,
                              loadSeriesFut: _seriesWodLoadFut!,
                              volumeSeriesFut: _seriesWodVolumeFut!,
                            )
                          else
                            _MovementChart(
                              title: 'Progresso',
                              movementName: _label,
                              days: _periodDays,
                              onChangeDays: (d) {
                                _periodDays = d;
                                _seriesMovementFut =
                                    PRService.fetchMovementSeries(
                                      _label,
                                      days: d,
                                    );
                                setState(() {});
                              },
                              seriesFut: _seriesMovementFut!,
                            ),

                          SizedBox(height: 20 * scale),

                          // ====== INSIGHTS ======
                          Text(
                            'Insights Inteligentes',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          FutureBuilder<List<InsightsModel>>(
                            future: _insightsFut,
                            builder: (ctx, snapI) {
                              final insights =
                                  snapI.data ?? const <InsightsModel>[];
                              if (insights.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final highlights =
                                  insights
                                      .map(
                                        (i) => HighlightModel(
                                          type: i.type,
                                          message: i.message,
                                        ),
                                      )
                                      .toList();
                              final enabledTypes =
                                  insights.map((i) => i.type).toSet();

                              return HighlightsCarousel(
                                allHighlights: highlights,
                                enabledHighlightsTypes: enabledTypes,
                              );
                            },
                          ),

                          SizedBox(height: 24 * scale),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}

// ===== Widgets internos (iguais aos que já te passei) =====

class _MovementChart extends StatelessWidget {
  const _MovementChart({
    required this.title,
    required this.movementName,
    required this.days,
    required this.onChangeDays,
    required this.seriesFut,
  });

  final String title;
  final String movementName;
  final int days;
  final ValueChanged<int> onChangeDays;
  final Future<List<TimePoint>> seriesFut;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return PrLineChartCard(
      title: title,
      trailingDropdownDays: days,
      onChangedDays: onChangeDays,
      child: FutureBuilder<List<TimePoint>>(
        future: seriesFut,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          return SfCartesianChart(
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(width: 0),
              labelStyle: TextStyle(
                fontSize: 12 * scale,
                color: AppColors.darkText,
                fontWeight: FontWeight.bold,
              ),
            ),
            primaryYAxis: NumericAxis(
              majorGridLines: const MajorGridLines(width: .5),
              axisLine: const AxisLine(width: 0),
              labelStyle: TextStyle(
                fontSize: 12 * scale,
                color: AppColors.darkText,
                fontWeight: FontWeight.bold,
              ),
            ),
            series: <LineSeries<TimePoint, String>>[
              LineSeries<TimePoint, String>(
                dataSource: data,
                xValueMapper:
                    (d, _) =>
                        '${d.date.day.toString().padLeft(2, '0')}/${d.date.month.toString().padLeft(2, '0')}',
                yValueMapper: (d, _) => d.value.toDouble(),
                markerSettings: const MarkerSettings(isVisible: true),
                enableTooltip: true,
              ),
            ],
            tooltipBehavior: TooltipBehavior(enable: true, header: ''),
          );
        },
      ),
    );
  }
}

class _WodCharts extends StatelessWidget {
  const _WodCharts({
    required this.wodName,
    required this.benchmarkFut,
    required this.perfSeriesFut,
    required this.loadSeriesFut,
    required this.volumeSeriesFut,
  });

  final String wodName;
  final Future<PrBenchmark?> benchmarkFut;
  final Future<List<TimePoint>> perfSeriesFut;
  final Future<List<TimePoint>> loadSeriesFut;
  final Future<List<MovementVolumePoint>> volumeSeriesFut;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // desempenho (tempo ou reps)
        FutureBuilder<PrBenchmark?>(
          future: benchmarkFut,
          builder: (ctx, snapB) {
            final bench = snapB.data;
            final perfTitle =
                bench?.type == PrWodType.amrap
                    ? 'Reps registradas'
                    : 'Tempo registrado';
            return PrLineChartCard(
              title: perfTitle,
              trailingDropdownDays: null, // sem dropdown
              onChangedDays: null,
              child: FutureBuilder<List<TimePoint>>(
                future: perfSeriesFut,
                builder: (c, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data!;
                  return SfCartesianChart(
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                    ),
                    primaryYAxis: NumericAxis(
                      majorGridLines: const MajorGridLines(width: .5),
                      axisLine: const AxisLine(width: 0),
                    ),
                    series: <LineSeries<TimePoint, String>>[
                      LineSeries<TimePoint, String>(
                        dataSource: data,
                        xValueMapper:
                            (d, _) =>
                                '${d.date.day.toString().padLeft(2, '0')}/${d.date.month.toString().padLeft(2, '0')}',
                        yValueMapper: (d, _) => d.value.toDouble(),
                        markerSettings: const MarkerSettings(isVisible: true),
                        enableTooltip: true,
                      ),
                    ],
                    tooltipBehavior: TooltipBehavior(enable: true, header: ''),
                  );
                },
              ),
            );
          },
        ),

        SizedBox(height: 12 * scale),

        // carga usada (kg)
        PrLineChartCard(
          title: 'Carga usada (kg)',
          trailingDropdownDays: null,
          onChangedDays: null,
          child: FutureBuilder<List<TimePoint>>(
            future: loadSeriesFut,
            builder: (c, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snap.data!;
              return SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(width: .5),
                  axisLine: const AxisLine(width: 0),
                ),
                series: <LineSeries<TimePoint, String>>[
                  LineSeries<TimePoint, String>(
                    dataSource: data,
                    xValueMapper:
                        (d, _) =>
                            '${d.date.day.toString().padLeft(2, '0')}/${d.date.month.toString().padLeft(2, '0')}',
                    yValueMapper: (d, _) => d.value.toDouble(),
                    markerSettings: const MarkerSettings(isVisible: true),
                    enableTooltip: true,
                  ),
                ],
                tooltipBehavior: TooltipBehavior(enable: true, header: ''),
              );
            },
          ),
        ),

        SizedBox(height: 12 * scale),

        // volume por movimento adaptado (barras)
        FutureBuilder<List<MovementVolumePoint>>(
          future: volumeSeriesFut,
          builder: (c, snap) {
            final data = snap.data ?? const <MovementVolumePoint>[];
            if (data.isEmpty) return const SizedBox.shrink();
            return PrLineChartCard(
              title: 'Volume por movimento (adaptações)',
              trailingDropdownDays: null,
              onChangedDays: null,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(width: .5),
                  axisLine: const AxisLine(width: 0),
                ),
                series: <ColumnSeries<MovementVolumePoint, String>>[
                  ColumnSeries<MovementVolumePoint, String>(
                    dataSource: data,
                    xValueMapper: (d, _) => d.movement,
                    yValueMapper: (d, _) => d.volume.toDouble(),
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: false,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
