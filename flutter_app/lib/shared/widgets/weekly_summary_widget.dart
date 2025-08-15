// lib/shared/widgets/weekly_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/effort_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/carousels/text_carousel.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart';
import 'package:flutter_app/shared/widgets/register_pr/register_pr_bottom_sheet.dart';

/// O widget principal de Resumo Semanal, agora incluindo o título da seção.
class WeeklySummaryWidget extends StatefulWidget {
  const WeeklySummaryWidget({Key? key}) : super(key: key);

  @override
  _WeeklySummaryWidgetState createState() => _WeeklySummaryWidgetState();
}

class _WeeklySummaryWidgetState extends State<WeeklySummaryWidget> {
  final _service = WeeklySummaryService();

  late Future<WeekRange> _weekRangeFut;
  late Future<Set<DateTime>> _daysTrainedFut;
  late Future<List<StimulusCount>> _stimuliFut;
  late Future<TotalLoad> _loadFut;
  late Future<List<PRModel>> _prsFut;
  late Future<EffortModel> _effortFut;
  late Future<List<InsightModel>> _insightsFut;

  @override
  void initState() {
    super.initState();
    _weekRangeFut = Future.value(_service.fetchCurrentWeekRange());
    _daysTrainedFut = _service.fetchDaysTrained();
    _stimuliFut = _service.fetchStimuliCounts();
    _loadFut = _service.fetchTotalLoad();
    _prsFut = _service.fetchPRs();
    _effortFut = _service.fetchEffort();
    _insightsFut = _service.fetchInsights();
  }

  String _formatWeekLabel(WeekRange w) {
    final fmt = DateFormat('d');
    final mes = DateFormat('MMMM', 'pt_BR').format(w.start);
    return 'Semana de ${fmt.format(w.start)} a ${fmt.format(w.end)} de $mes';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final stimuliColors = <Color>[
      AppColors.baseMagenta,
      AppColors.baseBlue,
      AppColors.darkBlue,
    ];

    return FutureBuilder<WeekRange>(
      future: _weekRangeFut,
      builder: (c, snapWeek) {
        if (!snapWeek.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final week = snapWeek.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título da seção
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Resumo Semanal',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            SizedBox(height: 8 * scale),

            // Card principal do resumo
            Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8 * scale),
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppColors.mediumGray),
                    borderRadius: BorderRadius.circular(24 * scale),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: EdgeInsets.all(16 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cabeçalho de semana
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 23 * scale,
                              color: AppColors.baseBlue,
                            ),
                            SizedBox(width: 8 * scale),
                            Expanded(
                              child: Text(
                                _formatWeekLabel(week),
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18 * scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12 * scale),

                        // Dias treinados
                        Text(
                          'DIAS TREINADOS',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.bold,
                            fontSize: 14 * scale,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        SizedBox(height: 8 * scale),
                        FutureBuilder<Set<DateTime>>(
                          future: _daysTrainedFut,
                          builder: (c, snap) {
                            final trained = snap.data ?? {};
                            final start = week.start;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(7, (i) {
                                final day = start.add(Duration(days: i));
                                final label = DateFormat.E(
                                  'pt_BR',
                                ).format(day).substring(0, 1);
                                final filled = trained.any(
                                  (d) =>
                                      d.year == day.year &&
                                      d.month == day.month &&
                                      d.day == day.day,
                                );
                                return Column(
                                  children: [
                                    Container(
                                      width: 20 * scale,
                                      height: 20 * scale,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            filled
                                                ? AppColors.baseBlue
                                                : Colors.transparent,
                                        border: Border.all(
                                          color: AppColors.mediumGray,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 4 * scale),
                                    Text(
                                      label.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12 * scale,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            );
                          },
                        ),
                        SizedBox(height: 16 * scale),

                        // Gráfico de pizza + tabela de estímulos
                        FutureBuilder<List<StimulusCount>>(
                          future: _stimuliFut,
                          builder: (ctx, snapStimuli) {
                            if (!snapStimuli.hasData) {
                              return SizedBox(
                                height: 140 * scale,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final data = snapStimuli.data!;
                            return SizedBox(
                              height: 140 * scale,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: 130 * scale,
                                      child: SfCircularChart(
                                        palette: stimuliColors,
                                        margin: EdgeInsets.zero,
                                        series:
                                            <PieSeries<StimulusCount, String>>[
                                              PieSeries<StimulusCount, String>(
                                                dataSource: data,
                                                xValueMapper: (d, _) => d.name,
                                                yValueMapper: (d, _) => d.count,
                                                dataLabelMapper:
                                                    (d, _) =>
                                                        d.name.substring(0, 1),
                                                dataLabelSettings:
                                                    DataLabelSettings(
                                                      isVisible: true,
                                                      labelPosition:
                                                          ChartDataLabelPosition
                                                              .inside,
                                                      textStyle: TextStyle(
                                                        fontSize: 12 * scale,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                radius: '90%',
                                              ),
                                            ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12 * scale),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'ESTÍMULOS PREDOMINANTES',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12 * scale,
                                            color: AppColors.baseBlue,
                                          ),
                                        ),
                                        SizedBox(height: 4 * scale),
                                        Table(
                                          border: TableBorder(
                                            horizontalInside: BorderSide(
                                              color: AppColors.baseBlue
                                                  .withOpacity(0.2),
                                            ),
                                          ),
                                          children:
                                              data.map((d) {
                                                final id = d.name.substring(
                                                  0,
                                                  1,
                                                );
                                                return TableRow(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            vertical: 4 * scale,
                                                          ),
                                                      child: Text(
                                                        '$id • ${d.name} – ${d.count} vezes',
                                                        style: TextStyle(
                                                          fontSize: 12 * scale,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 8 * scale),

                        // Carga total levantada
                        FutureBuilder<TotalLoad>(
                          future: _loadFut,
                          builder: (ctx, snapLoad) {
                            if (!snapLoad.hasData) {
                              return SizedBox(
                                height: 40 * scale,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final load = snapLoad.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CARGA TOTAL LEVANTADA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14 * scale,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  '${load.totalKg.toStringAsFixed(1)} kg - ${load.changeComment}',
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                SizedBox(height: 2 * scale),
                              ],
                            );
                          },
                        ),

                        SizedBox(height: 10 * scale),

                        // PRs batidos
                        FutureBuilder<List<PRModel>>(
                          future: _prsFut,
                          builder: (c, snapPRs) {
                            final prs = snapPRs.data ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'PRs BATIDOS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14 * scale,
                                        color: AppColors.darkBlue,
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: 0.9,
                                      alignment: Alignment.centerRight,
                                      child: TextActionButton(
                                        icon: Icons.add,
                                        text: 'Registrar PR',
                                        onPressed: () async {
                                          await showRegisterPrBottomSheet(
                                            context,
                                          );
                                          if (!mounted) return;
                                          setState(() {
                                            // reconsulta os PRs pra refletir o que acabou de ser registrado
                                            _prsFut = _service.fetchPRs();
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 1 * scale),
                                if (prs.isEmpty)
                                  const Text(
                                    'Essa semana você não atualizou PRs.',
                                  )
                                else
                                  TextCarousel(
                                    items: prs.map((p) => p.label).toList(),
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.normal,
                                  ),
                              ],
                            );
                          },
                        ),

                        SizedBox(height: 10 * scale),

                        // Esforço Médio
                        FutureBuilder<EffortModel>(
                          future: _effortFut,
                          builder: (c, snapE) {
                            if (!snapE.hasData) return const SizedBox.shrink();
                            final ef = snapE.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ESFORÇO MÉDIO',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14 * scale,
                                        color: AppColors.darkBlue,
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: 0.9,
                                      alignment: Alignment.centerRight,
                                      child: TextActionButton(
                                        icon: Icons.add,
                                        text: 'Ver gráfico de Esforço',
                                        onPressed:
                                            () => showAppBottomSheet(
                                              context,
                                              const EffortBottomSheet(),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 2 * scale),
                                Text(
                                  '${ef.score.toStringAsFixed(1)} de 10 - ${ef.comment}',
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        SizedBox(height: 16 * scale),

                        // Insights da Semana
                        FutureBuilder<List<InsightModel>>(
                          future: _insightsFut,
                          builder: (c, snapI) {
                            if (!snapI.hasData) return const SizedBox.shrink();
                            final ins = snapI.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INSIGHTS DA SEMANA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14 * scale,
                                    color: AppColors.darkBlue,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                TextCarousel(
                                  items: ins.map((i) => i.message).toList(),
                                  fontWeight: FontWeight.w300,
                                  fontStyle: FontStyle.italic,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
