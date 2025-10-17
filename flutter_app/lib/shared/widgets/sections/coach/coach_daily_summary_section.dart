import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/widgets/cards/mini_card_widget.dart';
import 'package:flutter_app/shared/widgets/utils/mini_card_button_widget.dart';

class CoachDailySummarySection extends StatefulWidget {
  final DateTime date;
  const CoachDailySummarySection({super.key, required this.date});

  @override
  State<CoachDailySummarySection> createState() =>
      _CoachDailySummarySectionState();
}

class _CoachDailySummarySectionState extends State<CoachDailySummarySection> {
  late Future<int> _resultsCount;
  late Future<double> _attendanceRate;

  @override
  void initState() {
    super.initState();
    _resultsCount = DailyStats.fetchResultsCountForDate(widget.date);
    _attendanceRate = DailyStats.fetchDailyAttendanceRate(widget.date);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16 * scale),
      child: IntrinsicHeight(
        // <- mesma altura baseada no maior conteúdo
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // <- ambos esticam à mesma altura
          children: [
            // CARD 1
            Expanded(
              child: FutureBuilder<int>(
                future: _resultsCount,
                builder: (context, snapshot) {
                  final value = snapshot.hasData ? '${snapshot.data}' : 'N/A';
                  return MiniCardWidget(
                    iconWidget: const Icon(
                      Icons.fitness_center,
                      color: AppColors.darkText,
                      size: 18,
                    ),
                    title: 'Resultados registrados',
                    tipo: 'daily_results',
                    titleFontSize: 12,
                    backgroundColor: AppColors.baseMagenta.withAlpha(50),
                    borderColor: AppColors.darkMagenta,
                    iconColor: AppColors.darkText,
                    showButton: true,
                    buttonWidget: const MiniCardButtonWidget(
                      icon: Icons.add,
                      label: 'Ver resultados',
                      textColor: AppColors.baseMagenta,
                      iconColor: AppColors.baseMagenta,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 8 * scale),

            // CARD 2
            Expanded(
              child: FutureBuilder<double>(
                future: _attendanceRate,
                builder: (context, snapshot) {
                  final value =
                      snapshot.hasData
                          ? '${snapshot.data!.toStringAsFixed(0)}%'
                          : 'N/A';
                  return MiniCardWidget(
                    iconWidget: const Icon(
                      Icons.favorite,
                      color: AppColors.darkText,
                      size: 18,
                    ),
                    title: 'Frequência geral',
                    tipo: 'daily_attendance',
                    titleFontSize: 12,
                    backgroundColor: AppColors.baseBlue.withAlpha(50),
                    borderColor: AppColors.darkBlue,
                    iconColor: AppColors.darkText,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
