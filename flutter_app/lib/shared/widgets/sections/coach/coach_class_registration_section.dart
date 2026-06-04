import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/users/coach/daily_training_analytics_service.dart';
import 'package:flutter_app/shared/models/hourly_metric_pont.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Section: "Registros por turma"
/// - Independente do tipo de treino.
/// - Soma os registros por horário das 4 categorias (WOD/LPO/Ginastica/Endurance)
///   reaproveitando o DailyTrainingAnalyticsService existente.
/// - Exibe um gráfico de barras HORIZONTAIS (Y = horário, X = total de registros).
class CoachClassRegistrationsSection extends StatelessWidget {
  final DateTime date;
  final String boxId;

  const CoachClassRegistrationsSection({
    super.key,
    required this.date,
    required this.boxId,
  });

  // Agrega (soma) registros por horário a partir das 4 categorias existentes.
  Future<List<HourlyMetricPoint>> _fetchTotals() async {
    const cats = ['WOD', 'LPO', 'Ginastica', 'Endurance'];

    // Busca em paralelo
    final futures =
        cats.map((cat) {
          return DailyTrainingAnalyticsService.fetchHourlyRegistrations(
            boxId: boxId,
            date: date,
            category: cat,
          );
        }).toList();

    final results = await Future.wait(futures);
    // Usa a primeira lista como base para ordem/labels
    final base = results.isNotEmpty ? results.first : <HourlyMetricPoint>[];

    // Somatório por horário em DOUBLE
    final Map<String, double> sumByHour = {for (final p in base) p.hour: 0.0};

    for (final list in results) {
      for (final p in list) {
        sumByHour[p.hour] = (sumByHour[p.hour] ?? 0.0) + p.value.toDouble();
      }
    }

    // Retorna na ordem da base
    return [
      for (final h in sumByHour.keys) HourlyMetricPoint(h, sumByHour[h] ?? 0.0),
    ];
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título da section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Text(
            'Registros por turma',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: 8 * scale),

        FutureBuilder<List<HourlyMetricPoint>>(
          future: _fetchTotals(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 160 * scale,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final data = snap.data ?? const <HourlyMetricPoint>[];
            if (data.isEmpty) {
              return Container(
                padding: EdgeInsets.all(12 * scale),
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
                child: Text(
                  'Sem registros de turmas em ${_fmtDate(date)}.',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              );
            }

            // Altura dinâmica para mostrar todos os horários sem paginação/scroll
            final chartHeight =
                ((data.length * (26 * scale)).clamp(120 * scale, 560 * scale) +
                        (24 * scale))
                    .toDouble();

            return Container(
              padding: EdgeInsets.all(8 * scale),
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
                      _fmtDate(date),
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: AppColors.mediumGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 6 * scale),

                  SizedBox(
                    height: chartHeight,
                    child: SfCartesianChart(
                      isTransposed: true, // ← barras horizontais
                      legend: const Legend(isVisible: false),
                      plotAreaBorderWidth: 0,
                      // X = horários (categorias)
                      primaryXAxis: CategoryAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        axisLine: const AxisLine(width: 0),
                        labelStyle: TextStyle(fontSize: 10 * scale),
                      ),
                      // Y = quantidade (numérica)
                      primaryYAxis: NumericAxis(
                        majorGridLines: MajorGridLines(
                          width: 0.5,
                          color: AppColors.lightGray,
                        ),
                        axisLine: const AxisLine(width: 0),
                        labelStyle: TextStyle(fontSize: 10 * scale),
                      ),
                      // Use ColumnSeries com isTransposed para barras horizontais
                      series: <CartesianSeries<HourlyMetricPoint, String>>[
                        ColumnSeries<HourlyMetricPoint, String>(
                          dataSource: data,
                          xValueMapper: (p, _) => p.hour, // categoria (String)
                          yValueMapper:
                              (p, _) => p.value, // quantidade (double)
                          borderRadius: BorderRadius.circular(4 * scale),
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(fontSize: 10 * scale),
                          ),
                        ),
                      ],
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
