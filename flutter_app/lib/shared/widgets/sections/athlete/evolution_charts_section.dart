// lib/shared/widgets/sections/athlete/evolution_charts_section.dart
//
// Seção de gráficos de evolução da tela /athlete_evolution.
// Duas abas: Volume (dias de treino por semana) e PRs (linha-escada do
// melhor registro ao longo do tempo). Reaproveita o período [from, to]
// selecionado no topo da tela.

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_prs_service.dart';
import 'package:flutter_app/core/services/weekly_load_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class EvolutionChartsSection extends StatefulWidget {
  final DateTime from;
  final DateTime to;

  const EvolutionChartsSection({
    Key? key,
    required this.from,
    required this.to,
  }) : super(key: key);

  @override
  State<EvolutionChartsSection> createState() =>
      _EvolutionChartsSectionState();
}

class _EvolutionChartsSectionState extends State<EvolutionChartsSection> {
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * scale),
            child: Text(
              'Evolução',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(height: 4 * scale),
          TabBar(
            labelColor: AppColors.baseBlue,
            unselectedLabelColor: AppColors.mediumGray,
            indicatorColor: AppColors.baseBlue,
            labelStyle: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.bold,
              fontSize: 12 * scale,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
            ),
            tabs: const [
              Tab(text: 'Volume'),
              Tab(text: 'PRs'),
            ],
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            height: 400 * scale,
            child: TabBarView(
              children: [
                _VolumeEvolutionTab(from: widget.from, to: widget.to),
                _PrsEvolutionTab(from: widget.from, to: widget.to),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Aba Volume — dias de treino por semana (WOD + Outros)
// =============================================================================

class _VolumeEvolutionTab extends StatefulWidget {
  final DateTime from;
  final DateTime to;
  const _VolumeEvolutionTab({required this.from, required this.to});

  @override
  State<_VolumeEvolutionTab> createState() => _VolumeEvolutionTabState();
}

class _VolumeEvolutionTabState extends State<_VolumeEvolutionTab> {
  late Future<List<WeeklyLoadEntry>> _future;

  // Cores de série do volume — distintas visualmente.
  static const _colorWod = AppColors.darkBlue;
  static const _colorOther = AppColors.lightMagenta;

  @override
  void initState() {
    super.initState();
    _future = WeeklyLoadService.fetchHistory(limit: 52);
  }

  @override
  void didUpdateWidget(_VolumeEvolutionTab old) {
    super.didUpdateWidget(old);
    if (old.from != widget.from || old.to != widget.to) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 2 * scale),
      child: FutureBuilder<List<WeeklyLoadEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(
              height: 300 * scale,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          final all = snap.data ?? const <WeeklyLoadEntry>[];

          // Filtra pelas semanas que intersectam o período.
          final fromDay = DateTime(
              widget.from.year, widget.from.month, widget.from.day);
          final toDay = DateTime(
              widget.to.year, widget.to.month, widget.to.day);
          final filtered = all.where((e) {
            final start = DateTime.tryParse(e.weekStart);
            if (start == null) return false;
            final end = DateTime.tryParse(e.weekEnd) ??
                start.add(const Duration(days: 6));
            return !end.isBefore(fromDay) && !start.isAfter(toDay);
          }).toList()
            ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

          if (filtered.isEmpty) {
            return _ChartCard(
              title: 'FREQUÊNCIA DE TREINOS',
              scale: scale,
              child: _EmptyMessage(
                text: 'Sem treinos registrados no período selecionado.',
                scale: scale,
              ),
            );
          }

          final totalTrainings = filtered.fold<int>(
            0,
            (s, e) => s + e.wodDays + e.otherDays,
          );
          final activeWeeks =
              filtered.where((e) => e.wodDays + e.otherDays > 0).length;
          final weeklyAvg =
              filtered.isEmpty ? 0.0 : totalTrainings / filtered.length;

          return _ChartCard(
            title: 'FREQUÊNCIA DE TREINOS',
            scale: scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _VolumeStatsHeader(
                  totalTrainings: totalTrainings,
                  weeklyAvg: weeklyAvg,
                  activeWeeks: activeWeeks,
                  totalWeeks: filtered.length,
                  scale: scale,
                ),
                SizedBox(height: 10 * scale),
                _VolumeStackedChart(
                  weeks: filtered,
                  scale: scale,
                  colorWod: _colorWod,
                  colorOther: _colorOther,
                ),
                SizedBox(height: 6 * scale),
                _LegendRow(
                  scale: scale,
                  items: const [
                    _LegendItem(color: _colorWod, label: 'CrossFit'),
                    _LegendItem(color: _colorOther, label: 'Outros'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VolumeStatsHeader extends StatelessWidget {
  final int totalTrainings;
  final double weeklyAvg;
  final int activeWeeks;
  final int totalWeeks;
  final double scale;

  const _VolumeStatsHeader({
    required this.totalTrainings,
    required this.weeklyAvg,
    required this.activeWeeks,
    required this.totalWeeks,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'TREINOS',
            value:
                '$totalTrainings ${totalTrainings == 1 ? 'dia' : 'dias'}',
            scale: scale,
            color: AppColors.baseBlue,
          ),
        ),
        SizedBox(width: 6 * scale),
        Expanded(
          child: _MiniStat(
            label: 'MÉDIA/SEM',
            value: '${weeklyAvg.toStringAsFixed(1)} dias',
            scale: scale,
            color: AppColors.darkBlue,
          ),
        ),
        SizedBox(width: 6 * scale),
        Expanded(
          child: _MiniStat(
            label: 'SEMANAS ATIVAS',
            value: '$activeWeeks/$totalWeeks',
            scale: scale,
            color: AppColors.lightBlue,
          ),
        ),
      ],
    );
  }
}

class _VolumeStackedChart extends StatelessWidget {
  final List<WeeklyLoadEntry> weeks;
  final double scale;
  final Color colorWod;
  final Color colorOther;

  const _VolumeStackedChart({
    required this.weeks,
    required this.scale,
    required this.colorWod,
    required this.colorOther,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180 * scale,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine:
              const AxisLine(width: 0.5, color: AppColors.lightGray),
          labelStyle: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 9 * scale,
            color: AppColors.mediumGray,
          ),
          majorTickLines: const MajorTickLines(size: 0),
          labelRotation: -25,
        ),
        primaryYAxis: NumericAxis(
          minimum: 0,
          maximum: 7,
          interval: 1,
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: AppColors.lightGray,
          ),
          axisLine: const AxisLine(width: 0),
          labelStyle: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 9 * scale,
            color: AppColors.mediumGray,
          ),
          majorTickLines: const MajorTickLines(size: 0),
          labelFormat: '{value}',
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          textStyle: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 10 * scale,
          ),
        ),
        series: <CartesianSeries>[
          StackedColumnSeries<WeeklyLoadEntry, String>(
            dataSource: weeks,
            xValueMapper: (e, _) => _shortLabel(e),
            yValueMapper: (e, _) => e.wodDays,
            name: 'CrossFit',
            color: colorWod,
            width: 0.65,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(2 * scale),
              topRight: Radius.circular(2 * scale),
            ),
          ),
          StackedColumnSeries<WeeklyLoadEntry, String>(
            dataSource: weeks,
            xValueMapper: (e, _) => _shortLabel(e),
            yValueMapper: (e, _) => e.otherDays,
            name: 'Outros',
            color: colorOther,
            width: 0.65,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(2 * scale),
              topRight: Radius.circular(2 * scale),
            ),
          ),
        ],
      ),
    );
  }

  static String _shortLabel(WeeklyLoadEntry e) {
    final start = DateTime.tryParse(e.weekStart);
    if (start == null) return e.weekLabel;
    return DateFormat('dd/MM').format(start);
  }
}

// =============================================================================
// Aba PRs — linha-escada do recorde + narrativa
// =============================================================================

class _PrsEvolutionTab extends StatefulWidget {
  final DateTime from;
  final DateTime to;
  const _PrsEvolutionTab({required this.from, required this.to});

  @override
  State<_PrsEvolutionTab> createState() => _PrsEvolutionTabState();
}

class _PrsEvolutionTabState extends State<_PrsEvolutionTab> {
  late Future<List<AthletePr>> _future;
  String? _selectedMovementId;

  @override
  void initState() {
    super.initState();
    _future = AthletePrsService.fetchUserPrs();
  }

  @override
  void didUpdateWidget(_PrsEvolutionTab old) {
    super.didUpdateWidget(old);
    if (old.from != widget.from || old.to != widget.to) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 2 * scale),
      child: FutureBuilder<List<AthletePr>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(
              height: 300 * scale,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          final all = snap.data ?? const <AthletePr>[];
          if (all.isEmpty) {
            return _ChartCard(
              title: 'PROGRESSO POR MOVIMENTO',
              scale: scale,
              child: _EmptyMessage(
                text:
                    'Registre seu primeiro PR para ver sua evolução aqui.',
                scale: scale,
              ),
            );
          }

          // Agrupa por movimento
          final Map<String, _MovementGroup> groups = {};
          for (final pr in all) {
            final g = groups.putIfAbsent(
              pr.movementId,
              () => _MovementGroup(
                id: pr.movementId,
                name: pr.movementName,
                prType: pr.prType,
                unit: pr.unit,
              ),
            );
            g.prs.add(pr);
          }
          final sortedMovements = groups.values.toList()
            ..sort((a, b) {
              final byCount = b.prs.length.compareTo(a.prs.length);
              if (byCount != 0) return byCount;
              return a.name
                  .toLowerCase()
                  .compareTo(b.name.toLowerCase());
            });

          _selectedMovementId ??= sortedMovements.first.id;
          final selected = sortedMovements.firstWhere(
            (g) => g.id == _selectedMovementId,
            orElse: () => sortedMovements.first,
          );

          final fromDay = DateTime(
              widget.from.year, widget.from.month, widget.from.day);
          final toDay = DateTime(widget.to.year, widget.to.month,
              widget.to.day, 23, 59, 59);
          final inRange = selected.prs
              .where((pr) =>
                  !pr.date.isBefore(fromDay) && !pr.date.isAfter(toDay))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          return _ChartCard(
            title: 'PROGRESSO POR MOVIMENTO',
            scale: scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MovementPicker(
                  scale: scale,
                  movements: sortedMovements,
                  selectedId: selected.id,
                  onChanged: (id) =>
                      setState(() => _selectedMovementId = id),
                ),
                SizedBox(height: 10 * scale),
                if (inRange.isEmpty)
                  _EmptyMessage(
                    text:
                        'Sem PRs deste movimento no período selecionado.',
                    scale: scale,
                  )
                else ...[
                  _PrNarrativeHeader(
                    prs: inRange,
                    movementName: selected.name,
                    unit: selected.unit,
                    prType: selected.prType,
                    scale: scale,
                  ),
                  SizedBox(height: 8 * scale),
                  _PrSteppedLineChart(
                    prs: inRange,
                    from: fromDay,
                    to: widget.to,
                    unit: selected.unit,
                    prType: selected.prType,
                    scale: scale,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MovementGroup {
  final String id;
  final String name;
  final PrType prType;
  final String unit;
  final List<AthletePr> prs = [];

  _MovementGroup({
    required this.id,
    required this.name,
    required this.prType,
    required this.unit,
  });
}

class _MovementPicker extends StatelessWidget {
  final double scale;
  final List<_MovementGroup> movements;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _MovementPicker({
    required this.scale,
    required this.movements,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale, vertical: 2 * scale,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down,
              size: 18 * scale, color: AppColors.darkText),
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 12 * scale,
            color: AppColors.darkText,
          ),
          items: movements
              .map(
                (g) => DropdownMenuItem(
                  value: g.id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * scale,
                          vertical: 1 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.baseBlue
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(6 * scale),
                        ),
                        child: Text(
                          '${g.prs.length}',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.bold,
                            fontSize: 10 * scale,
                            color: AppColors.baseBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _PrNarrativeHeader extends StatelessWidget {
  final List<AthletePr> prs;
  final String movementName;
  final String unit;
  final PrType prType;
  final double scale;

  const _PrNarrativeHeader({
    required this.prs,
    required this.movementName,
    required this.unit,
    required this.prType,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final isTimeBased = prType == PrType.time;

    // Melhor PR no período (max ou min dependendo do tipo)
    final best = isTimeBased
        ? prs.map((p) => p.value).reduce((a, b) => a < b ? a : b)
        : prs.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    final first = prs.first.value;
    final delta = isTimeBased ? first - best : best - first;

    // Nome do movimento já está visível no dropdown acima → não repetir
    // na frase pra evitar truncamento quando o nome é longo.
    final String narrative;
    if (prs.length == 1) {
      narrative = 'Primeiro PR registrado: ${_fmt(best)} $unit.';
    } else if (delta.abs() < 0.05) {
      narrative =
          '${prs.length} PRs registrados — melhor marca: ${_fmt(best)} $unit.';
    } else if (delta > 0) {
      final fmtStart = DateFormat("d 'de' MMM", 'pt_BR');
      final period = fmtStart.format(prs.first.date);
      final verb = isTimeBased ? 'Você melhorou' : 'Você evoluiu';
      narrative = '$verb ${_fmt(delta)} $unit desde $period.';
    } else {
      narrative = 'Melhor marca no período: ${_fmt(best)} $unit.';
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          10 * scale, 8 * scale, 10 * scale, 9 * scale,
        ),
        decoration: BoxDecoration(
          color: AppColors.baseBlue.withValues(alpha: 0.06),
          border: Border.all(
            color: AppColors.baseBlue.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2 * scale),
              child: Icon(
                Icons.trending_up,
                color: AppColors.baseBlue,
                size: 18 * scale,
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              // RichText bypassa qualquer DefaultTextStyle ancestral que
              // esteja forçando maxLines/overflow. Text herda esses valores
              // quando não são explicitamente setados — RichText não herda
              // nada e garante o comportamento esperado.
              child: RichText(
                softWrap: true,
                overflow: TextOverflow.visible,
                maxLines: 99,
                text: TextSpan(
                  text: narrative,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 11.5 * scale,
                    color: AppColors.darkText,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _PrSteppedLineChart extends StatelessWidget {
  final List<AthletePr> prs;
  final DateTime from;
  final DateTime to;
  final String unit;
  final PrType prType;
  final double scale;

  const _PrSteppedLineChart({
    required this.prs,
    required this.from,
    required this.to,
    required this.unit,
    required this.prType,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final isTimeBased = prType == PrType.time;

    // Constrói pontos com "isNewPr" marcando só onde a linha sobe.
    final List<_PrPoint> points = [];
    double? runningBest;
    for (final pr in prs) {
      bool isNew;
      if (runningBest == null) {
        runningBest = pr.value;
        isNew = true;
      } else {
        final improved = isTimeBased
            ? pr.value < runningBest
            : pr.value > runningBest;
        isNew = improved;
        if (improved) runningBest = pr.value;
      }
      points.add(_PrPoint(pr.date, runningBest, isNew, pr.value));
    }

    // Calcula intervalo do eixo X para evitar labels duplicadas.
    final totalDays = to.difference(from).inDays.clamp(1, 3650);
    final intervalDays = (totalDays / 4).ceil().toDouble();

    return SizedBox(
      height: 170 * scale,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        primaryXAxis: DateTimeAxis(
          minimum: from,
          maximum: to,
          intervalType: DateTimeIntervalType.days,
          interval: intervalDays,
          dateFormat: DateFormat('dd/MM'),
          majorGridLines: const MajorGridLines(width: 0),
          axisLine:
              const AxisLine(width: 0.5, color: AppColors.lightGray),
          labelStyle: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 9 * scale,
            color: AppColors.mediumGray,
          ),
          majorTickLines: const MajorTickLines(size: 0),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: AppColors.lightGray,
          ),
          axisLine: const AxisLine(width: 0),
          labelStyle: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 9 * scale,
            color: AppColors.mediumGray,
          ),
          majorTickLines: const MajorTickLines(size: 0),
          labelFormat: '{value} $unit',
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (data, point, series, pointIndex, seriesIndex) {
            if (data is! _PrPoint) return const SizedBox.shrink();
            final date =
                DateFormat("d 'de' MMM", 'pt_BR').format(data.date);
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 6 * scale,
              ),
              decoration: BoxDecoration(
                color: AppColors.darkText,
                borderRadius: BorderRadius.circular(6 * scale),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_fmt(data.actual)} $unit',
                    style: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight: FontWeight.bold,
                      fontSize: 13 * scale,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    data.isNewPr ? '$date — novo PR!' : date,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 10 * scale,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        onMarkerRender: (args) {
          final idx = args.pointIndex;
          if (idx == null || idx >= points.length) return;
          final p = points[idx];
          final c = p.isNewPr ? AppColors.baseBlue : AppColors.mediumGray;
          args.color = c;
          args.borderColor = c;
          args.markerHeight = 10 * scale;
          args.markerWidth = 10 * scale;
        },
        series: <CartesianSeries>[
          LineSeries<_PrPoint, DateTime>(
            dataSource: points,
            xValueMapper: (p, _) => p.date,
            yValueMapper: (p, _) => p.actual,
            color: AppColors.baseBlue.withValues(alpha: 0.55),
            width: 2,
            name: 'Registros',
            markerSettings: MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              borderWidth: 0,
            ),
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.middle,
              builder: (data, point, series, pointIndex, seriesIndex) {
                if (pointIndex >= points.length) {
                  return const SizedBox.shrink();
                }
                final current = points[pointIndex];
                final hasPrev = pointIndex > 0;
                final hasNext = pointIndex < points.length - 1;
                // A linha passa ACIMA do ponto atual se algum vizinho
                // (anterior ou próximo) tem valor MAIOR. Nesse caso o
                // rótulo vai ABAIXO pra não ser atravessado pela linha.
                // Caso contrário (pico, vale sem vizinho maior, único
                // ponto), rótulo vai acima.
                final prevHigher = hasPrev &&
                    points[pointIndex - 1].actual > current.actual;
                final nextHigher = hasNext &&
                    points[pointIndex + 1].actual > current.actual;
                final labelBelow = prevHigher || nextHigher;
                return Transform.translate(
                  offset: Offset(0, labelBelow ? 14 * scale : -14 * scale),
                  child: Text(
                    _fmt(current.actual),
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.w600,
                      fontSize: 9 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _PrPoint {
  final DateTime date;
  final double runningBest;
  final bool isNewPr;
  final double actual;
  _PrPoint(this.date, this.runningBest, this.isNewPr, this.actual);
}

// =============================================================================
// Componentes compartilhados
// =============================================================================

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double scale;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        7 * scale, 6 * scale, 7 * scale, 7 * scale,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.bold,
              fontSize: 8.5 * scale,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.montserrat,
              fontWeight: FontWeight.bold,
              fontSize: 13 * scale,
              color: AppColors.darkText,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
}

class _LegendRow extends StatelessWidget {
  final double scale;
  final List<_LegendItem> items;
  const _LegendRow({required this.scale, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: 14 * scale),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8 * scale,
                height: 8 * scale,
                decoration: BoxDecoration(
                  color: items[i].color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 5 * scale),
              Text(
                items[i].label,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 10 * scale,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final double scale;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.scale,
    required this.child,
  });

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
        padding: EdgeInsets.fromLTRB(
          10 * scale, 8 * scale, 10 * scale, 9 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 9.5 * scale,
                color: AppColors.darkBlue,
                letterSpacing: 0.7,
              ),
            ),
            SizedBox(height: 8 * scale),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  final double scale;
  const _EmptyMessage({required this.text, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scale,
        vertical: 20 * scale,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 11.5 * scale,
          color: AppColors.mediumGray,
        ),
      ),
    );
  }
}
