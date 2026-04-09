// lib/shared/widgets/cards/week_calendar_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';

/// Card de calendário semanal (seg → dom).
/// Exibe um ícone por tipo de atividade em cada dia.
class WeekCalendarCard extends StatelessWidget {
  final AthleteStatsSummary summary;

  const WeekCalendarCard({Key? key, required this.summary}) : super(key: key);

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final weekStart = DateTime.tryParse(summary.weekStart) ?? DateTime.now();
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 * scale, 14 * scale, 16 * scale, 16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'SEMANA',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 11 * scale,
                color: AppColors.darkBlue,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 14 * scale),

            // 7 dias
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (i) {
                final day = weekStart.add(Duration(days: i));
                final dateKey = _dateKey(day);
                final type = summary.activityTypeFor(dateKey);
                final isToday = dateKey == todayKey;
                final label =
                    DateFormat.E('pt_BR').format(day).substring(0, 1).toUpperCase();

                return _DayCell(
                  label: label,
                  type: type,
                  isToday: isToday,
                  scale: scale,
                );
              }),
            ),

            SizedBox(height: 12 * scale),

            // Legenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendItem(
                  color: AppColors.baseBlue,
                  icon: Icons.fitness_center,
                  label: 'Treino',
                  scale: scale,
                ),
                SizedBox(width: 14 * scale),
                _LegendItem(
                  color: AppColors.mediumGray,
                  icon: Icons.bedtime_outlined,
                  label: 'Descanso',
                  scale: scale,
                ),
                SizedBox(width: 14 * scale),
                _LegendItem(
                  color: AppColors.lightMagenta,
                  icon: Icons.directions_run,
                  label: 'Outra',
                  scale: scale,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Célula de um dia
// ─────────────────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final String label;
  final DayActivityType type;
  final bool isToday;
  final double scale;

  const _DayCell({
    required this.label,
    required this.type,
    required this.isToday,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, iconColor, icon) = switch (type) {
      DayActivityType.wod => (
          AppColors.baseBlue,
          Colors.white,
          Icons.fitness_center,
        ),
      DayActivityType.rest => (
          AppColors.lightGray,
          AppColors.mediumGray,
          Icons.bedtime_outlined,
        ),
      DayActivityType.other => (
          AppColors.lightMagenta.withValues(alpha: 0.15),
          AppColors.lightMagenta,
          Icons.directions_run,
        ),
      DayActivityType.none => (
          Colors.transparent,
          AppColors.lightGray,
          Icons.circle_outlined,
        ),
    };

    return Column(
      children: [
        Container(
          width: 36 * scale,
          height: 36 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            border: isToday
                ? Border.all(color: AppColors.darkBlue, width: 2)
                : type == DayActivityType.none
                    ? Border.all(color: AppColors.lightGray, width: 1.5)
                    : null,
          ),
          child: type == DayActivityType.none
              ? null
              : Icon(icon, size: 17 * scale, color: iconColor),
        ),
        SizedBox(height: 5 * scale),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 11 * scale,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w400,
            color: isToday ? AppColors.darkBlue : AppColors.darkText,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item de legenda
// ─────────────────────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final double scale;

  const _LegendItem({
    required this.color,
    required this.icon,
    required this.label,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11 * scale, color: color),
        SizedBox(width: 3 * scale),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 10 * scale,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }
}
