/// lib/shared/widgets/weekly_statistics_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';
import 'package:flutter_app/shared/widgets/cards/mini_card_widget.dart';
import 'package:flutter_app/core/services/weekly_stats_service.dart';
import 'package:flutter_svg/svg.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Título ---
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Text(
            'Estatísticas de treino',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: 10 * scale),

        // --- Filtro de tipo com expand/collapse ---
        FutureBuilder<List<String>>(
          future: _typesFuture,
          builder: (context, snap) {
            final types = snap.data ?? [];
            if (types.isEmpty) return const SizedBox.shrink();

            final selectedLabel = _selectedType ?? 'Todos';

            return SizedBox(
              height: 30 * scale,
              child: Row(
                children: [
                  SizedBox(width: 6 * scale),

                  // Botão principal "Todos ▶" ou "WOD ▶"
                  GestureDetector(
                    onTap: () =>
                        setState(() => _filterExpanded = !_filterExpanded),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * scale,
                        vertical: 5 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.baseBlue,
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            selectedLabel,
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 4 * scale),
                          AnimatedRotation(
                            turns: _filterExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_right,
                              size: 14 * scale,
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
                              padding: EdgeInsets.only(left: 6 * scale),
                              child: Row(
                                children: [null, ...types].map((type) {
                                  final isSelected = _selectedType == type;
                                  final label = type ?? 'Todos';
                                  return Padding(
                                    padding: EdgeInsets.only(right: 6 * scale),
                                    child: GestureDetector(
                                      onTap: () => setState(() {
                                        _selectedType = type;
                                        _filterExpanded = false;
                                      }),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12 * scale,
                                          vertical: 5 * scale,
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
                                          borderRadius: BorderRadius.circular(
                                              20 * scale),
                                        ),
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontFamily: AppFonts.roboto,
                                            fontSize: 12 * scale,
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
            );
          },
        ),
        SizedBox(height: 10 * scale),

        // --- 4 MiniCards ---
        Row(
          children: [
            Expanded(
              child: MiniCardWidget(
                iconWidget: SvgPicture.asset(
                  'assets/icons/exercise.svg',
                  width: 14,
                  height: 14,
                  color: AppColors.darkText,
                ),
                title: 'Cargas',
                tipo: WeeklyStatsType.cargas,
                from: widget.from,
                to: widget.to,
                trainingType: _selectedType,
                borderColor: AppColors.darkBlue,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
                titleFontSize: 11,
                valueFontSize: 11,
              ),
            ),
            SizedBox(width: 4 * scale),
            Expanded(
              child: MiniCardWidget(
                iconWidget: Icon(
                  Icons.calendar_month_outlined,
                  size: 14,
                  color: AppColors.darkText,
                ),
                title: 'Frequência',
                tipo: WeeklyStatsType.frequencia,
                from: widget.from,
                to: widget.to,
                trainingType: _selectedType,
                borderColor: AppColors.darkBlue,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
                titleFontSize: 11,
                valueFontSize: 11,
              ),
            ),
            SizedBox(width: 4 * scale),
            Expanded(
              child: MiniCardWidget(
                iconWidget: SvgPicture.asset(
                  'assets/icons/relax.svg',
                  width: 14,
                  height: 14,
                  color: AppColors.darkText,
                ),
                title: 'Esforço',
                tipo: WeeklyStatsType.esforco,
                from: widget.from,
                to: widget.to,
                trainingType: _selectedType,
                borderColor: AppColors.darkBlue,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
                titleFontSize: 11,
                valueFontSize: 11,
              ),
            ),
            SizedBox(width: 4 * scale),
            Expanded(
              child: MiniCardWidget(
                iconWidget: Icon(
                  Icons.hotel_outlined,
                  size: 14,
                  color: AppColors.darkText,
                ),
                title: 'Descanso',
                tipo: WeeklyStatsType.descanso,
                from: widget.from,
                to: widget.to,
                borderColor: AppColors.darkBlue,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
                titleFontSize: 11,
                valueFontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
