import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/users/coach/daily_training_analytics_service.dart';
import 'package:flutter_app/shared/models/hourly_metric_pont.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class CoachDailySummaryTabs extends StatelessWidget {
  final DateTime date;
  final String boxId;

  const CoachDailySummaryTabs({
    super.key,
    required this.date,
    required this.boxId,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    // padding horizontal padrão usado nas páginas (ex.: 12 * scale)
    final outerPadding = 12 * scale;

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- TAB BAR (fundo transparente + linha total na base) ---
          Stack(
            children: [
              // Linha (borda) inferior ocupando 100% da largura da tela,
              // mesmo com padding externo da página.
              Positioned(
                left: -outerPadding,
                right: -outerPadding,
                bottom: 0,
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.lightGray,
                ),
              ),
              // Próprio TabBar (sem container, fundo transparente)
              TabBar(
                labelPadding: EdgeInsets.symmetric(horizontal: 2 * scale),
                labelColor: AppColors.darkBlue,
                unselectedLabelColor: AppColors.mediumGray,
                indicatorColor: AppColors.darkBlue,
                indicatorWeight: 3 * scale,
                tabs: const [
                  Tab(text: 'WOD'),
                  Tab(text: 'LPO'),
                  Tab(text: 'Ginastica'),
                  Tab(text: 'Endurance'),
                ],
              ),
            ],
          ),
          SizedBox(height: 12 * scale),

          // --- CONTEÚDO DE CADA ABA ---
          SizedBox(
            height: 240 * scale, // 2 gráficos + barra de esforço
            child: TabBarView(
              children: const [
                _CategoryPanel(category: 'WOD'),
                _CategoryPanel(category: 'LPO'),
                _CategoryPanel(category: 'Ginastica'),
                _CategoryPanel(category: 'Endurance'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPanel extends StatelessWidget {
  final String category;
  const _CategoryPanel({required this.category});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final parent =
        context.findAncestorWidgetOfExactType<CoachDailySummaryTabs>()!;
    final date = parent.date;
    final boxId = parent.boxId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- LINHA COM 2 GRÁFICOS ----
        Row(
          children: [
            Expanded(
              child: _ChartCard(
                title: 'Frequência',
                future: DailyTrainingAnalyticsService.fetchHourlyFrequency(
                  boxId: boxId,
                  date: date,
                  category: category,
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: _ChartCard(
                title: 'Registros',
                future: DailyTrainingAnalyticsService.fetchHourlyRegistrations(
                  boxId: boxId,
                  date: date,
                  category: category,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: 12 * scale),

        // ---- PROGRESS BAR DE ESFORÇO ----
        _EffortBar(
          future: DailyTrainingAnalyticsService.fetchAverageEffortScore(
            boxId: boxId,
            date: date,
            category: category,
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Future<List<HourlyMetricPoint>> future;

  const _ChartCard({required this.title, required this.future});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      padding: EdgeInsets.all(4 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3 * scale,
            offset: Offset(0, 1 * scale),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
          SizedBox(height: 6 * scale),

          // Gráfico (barras)
          SizedBox(
            height: 120 * scale,
            child: FutureBuilder<List<HourlyMetricPoint>>(
              future: future,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!;
                return SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  primaryXAxis: CategoryAxis(
                    majorGridLines: const MajorGridLines(width: 0),
                    axisLine: const AxisLine(width: 0),
                    labelStyle: TextStyle(fontSize: 10 * scale),
                  ),
                  primaryYAxis: NumericAxis(
                    majorGridLines: MajorGridLines(
                      width: 0.5,
                      color: AppColors.lightGray,
                    ),
                    axisLine: const AxisLine(width: 0),
                    labelStyle: TextStyle(fontSize: 10 * scale),
                  ),
                  series: <CartesianSeries<HourlyMetricPoint, String>>[
                    ColumnSeries<HourlyMetricPoint, String>(
                      dataSource: data,
                      xValueMapper: (p, _) => p.hour,
                      yValueMapper: (p, _) => p.value,
                      borderRadius: BorderRadius.circular(4 * scale),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EffortBar extends StatelessWidget {
  final Future<double> future;
  const _EffortBar({required this.future});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<double>(
      future: future,
      builder: (context, snapshot) {
        final score = snapshot.data ?? 0.0;
        final clamped = score.clamp(0.0, 10.0);
        final fraction = clamped / 10.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // label + valor (x/10) à direita
            Row(
              children: [
                Text(
                  'Esforço Médio :',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                const Spacer(),
                Text(
                  '${clamped.toStringAsFixed(1)}/10',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * scale,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6 * scale),

            // barra ocupa toda a largura da linha de cima (igual aos cards)
            ClipRRect(
              borderRadius: BorderRadius.circular(6 * scale),
              child: LinearProgressIndicator(
                value:
                    snapshot.hasData
                        ? fraction
                        : null, // anima enquanto carrega
                minHeight: 8 * scale,
                backgroundColor: AppColors.lightGray.withAlpha(120),
                color: AppColors.darkBlue,
              ),
            ),
          ],
        );
      },
    );
  }
}
