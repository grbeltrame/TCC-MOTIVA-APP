/// lib/shared/widgets/weekly_statistics_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_prs_service.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';
import 'package:flutter_app/core/services/weekly_stats_service.dart';

class WeeklyStatisticsWidget extends StatefulWidget {
  final DateTime from;
  final DateTime to;

  const WeeklyStatisticsWidget({
    Key? key,
    required this.from,
    required this.to,
  }) : super(key: key);

  @override
  State<WeeklyStatisticsWidget> createState() =>
      _WeeklyStatisticsWidgetState();
}

class _WeeklyStatisticsWidgetState extends State<WeeklyStatisticsWidget> {
  String? _selectedType; // null = todos
  bool _filterExpanded = false;
  late Future<List<String>> _typesFuture;

  @override
  void initState() {
    super.initState();
    _typesFuture = _loadTypes();
  }

  @override
  void didUpdateWidget(WeeklyStatisticsWidget old) {
    super.didUpdateWidget(old);
    if (old.from != widget.from || old.to != widget.to) {
      setState(() {
        _selectedType = null;
        _typesFuture = _loadTypes();
      });
    }
  }

  Future<List<String>> _loadTypes() =>
      AthleteStatsService.fetchTrainingTypes(from: widget.from, to: widget.to);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 3 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          10 * scale,
          8 * scale,
          10 * scale,
          9 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Título padronizado (estilo insight) ---
            Text(
              'ESTATÍSTICAS DE TREINO',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 9 * scale,
                color: AppColors.darkBlue,
                letterSpacing: 0.7,
              ),
            ),
            SizedBox(height: 6 * scale),

            // --- Filtro de tipo com expand/collapse ---
            FutureBuilder<List<String>>(
              future: _typesFuture,
              builder: (context, snap) {
                final types = snap.data ?? [];
                if (types.isEmpty) return const SizedBox.shrink();

                final selectedLabel = _selectedType ?? 'Todos';

                return Padding(
                  padding: EdgeInsets.only(bottom: 10 * scale),
                  child: SizedBox(
                    height: 26 * scale,
                    child: Row(
                      children: [
                        // Botão principal "Todos ▶" ou "WOD ▶"
                        GestureDetector(
                          onTap: () => setState(
                              () => _filterExpanded = !_filterExpanded),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * scale,
                              vertical: 4 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.baseBlue,
                              borderRadius: BorderRadius.circular(18 * scale),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  selectedLabel,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontSize: 11 * scale,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 3 * scale),
                                AnimatedRotation(
                                  turns: _filterExpanded ? 0.25 : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    Icons.keyboard_arrow_right,
                                    size: 12 * scale,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Chips que aparecem lateralmente
                        Flexible(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            child: _filterExpanded
                                ? SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding:
                                        EdgeInsets.only(left: 6 * scale),
                                    child: Row(
                                      children: [null, ...types].map((type) {
                                        final isSelected =
                                            _selectedType == type;
                                        final label = type ?? 'Todos';
                                        return Padding(
                                          padding: EdgeInsets.only(
                                              right: 5 * scale),
                                          child: GestureDetector(
                                            onTap: () => setState(() {
                                              _selectedType = type;
                                              _filterExpanded = false;
                                            }),
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 150),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10 * scale,
                                                vertical: 4 * scale,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? AppColors.baseBlue
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: isSelected
                                                      ? AppColors.baseBlue
                                                      : AppColors.mediumGray,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        18 * scale),
                                              ),
                                              child: Text(
                                                label,
                                                style: TextStyle(
                                                  fontFamily: AppFonts.roboto,
                                                  fontSize: 11 * scale,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppColors.mediumGray,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // --- 4 Stat Blocks em grid 2x2 ---
            Column(
              children: [
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatBlock(
                          title: 'PRs Batidos',
                          subtitle: 'no período',
                          icon: Icons.emoji_events_outlined,
                          color: AppColors.baseBlue,
                          scale: scale,
                          valueFuture: _fetchPrCount(),
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Expanded(
                        child: _StatBlock(
                          title: 'Frequência',
                          subtitle: 'no período',
                          icon: Icons.calendar_month_outlined,
                          color: AppColors.darkBlue,
                          scale: scale,
                          valueFuture: WeeklyStatsService.getStatForPeriod(
                            tipo: WeeklyStatsType.frequencia,
                            from: widget.from,
                            to: widget.to,
                            trainingType: _selectedType,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4 * scale),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _StatBlock(
                          title: 'Esforço Médio',
                          subtitle: 'percebido',
                          icon: Icons.local_fire_department_outlined,
                          color: AppColors.baseMagenta,
                          scale: scale,
                          valueFuture: WeeklyStatsService.getStatForPeriod(
                            tipo: WeeklyStatsType.esforco,
                            from: widget.from,
                            to: widget.to,
                            trainingType: _selectedType,
                          ),
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Expanded(
                        child: _StatBlock(
                          title: 'Descanso',
                          subtitle: 'de descanso',
                          icon: Icons.hotel_outlined,
                          color: AppColors.mediumGray,
                          scale: scale,
                          valueFuture: WeeklyStatsService.getStatForPeriod(
                            tipo: WeeklyStatsType.descanso,
                            from: widget.from,
                            to: widget.to,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Conta PRs no período — ignora o filtro de tipo de treino (PR é por
  /// movimento, não por modalidade).
  Future<String> _fetchPrCount() async {
    try {
      final prs = await AthletePrsService.fetchWeekPrs(
        weekStart: widget.from,
        weekEnd: widget.to,
      );
      final n = prs.length;
      return '$n ${n == 1 ? 'PR' : 'PRs'}';
    } catch (_) {
      return '–';
    }
  }
}

// =============================================================================
// Bloco de estatística — visual alinhado ao estilo dos cards de insight
// =============================================================================

class _StatBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double scale;
  final Future<String> valueFuture;

  const _StatBlock({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.scale,
    required this.valueFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        7 * scale,
        6 * scale,
        7 * scale,
        7 * scale,
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
          // Cabeçalho: ícone + título uppercase
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 11 * scale, color: color),
              SizedBox(width: 4 * scale),
              Expanded(
                child: Text(
                  title.toUpperCase(),
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
              ),
            ],
          ),
          SizedBox(height: 5 * scale),

          // Valor grande
          FutureBuilder<String>(
            future: valueFuture,
            builder: (ctx, snap) {
              final loading =
                  snap.connectionState == ConnectionState.waiting;
              final raw = snap.data ?? '–';
              return Text(
                loading ? '…' : raw,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: FontWeight.bold,
                  fontSize: 17 * scale,
                  color: AppColors.darkText,
                  height: 1,
                ),
              );
            },
          ),

          if (subtitle != null) ...[
            SizedBox(height: 2 * scale),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 8.5 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
