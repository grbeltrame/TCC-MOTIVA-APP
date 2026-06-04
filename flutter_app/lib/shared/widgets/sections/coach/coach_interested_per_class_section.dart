// lib/shared/widgets/sections/coach/coach_interested_per_class_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/users/coach/daily_training_analytics_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/hourly_metric_pont.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';

/// Section: "Interessados por turma (horário)"
/// Mostra, para a CATEGORIA atual no DIA informado, um card por horário com
/// a quantidade de alunos interessados.
///
/// ⚠️ MOCK: por enquanto reaproveita `DailyTrainingAnalyticsService.fetchHourlyFrequency`
/// como proxy de "interesse". Substituir por endpoint real quando existir.
/// TODO(back): trocar por `InterestService.fetchInterestedCountByHour(...)`.
class CoachInterestedPerClassSection extends StatelessWidget {
  final DateTime date;
  final String boxId;
  final String category; // 'WOD' | 'LPO' | 'Ginastica' | 'Endurance'

  /// Opcional: callback quando clicar em "Ver alunos" de um horário.
  /// Recebe o label do horário (ex.: '06h') e a contagem exibida.
  final void Function(String hourLabel, int count)? onViewStudents;

  const CoachInterestedPerClassSection({
    super.key,
    required this.date,
    required this.boxId,
    required this.category,
    this.onViewStudents,
  });

  Future<List<HourlyMetricPoint>> _fetchInterestedByHour() async {
    // MOCK: usa frequência por horário como “interessados”.
    // Substituir no backend quando houver endpoint de interesse.
    return DailyTrainingAnalyticsService.fetchHourlyFrequency(
      boxId: boxId,
      date: date,
      category: category,
    );
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
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
          future: _fetchInterestedByHour(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 120 * scale,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final data = snap.data ?? const <HourlyMetricPoint>[];

            // Mesmo sem dados, mostramos 0 interessados num cartão "vazio" para o dia.
            if (data.isEmpty) {
              return _InterestedCard(
                scale: scale,
                dateLabel: _fmtDate(date),
                hourLabel: '--',
                interestedCount: 0,
                onView: () {
                  // Navegação padrão/placeholder
                  _defaultNavigate(context, hourLabel: '--', count: 0);
                },
              );
            }

            // Renderiza um card por horário.
            return Column(
              children: [
                // Data do agrupamento (rótulo discreto acima dos cards)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Text(
                    '${_fmtDate(date)} · $category',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: AppColors.mediumGray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 6 * scale),

                ...data.map((p) {
                  // ignore: unnecessary_type_check
                  final count = (p.value is num) ? p.value.toInt() : 0;
                  final hour = p.hour; // ex.: '06h'
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8 * scale),
                    child: _InterestedCard(
                      scale: scale,
                      dateLabel: _fmtDate(date),
                      hourLabel: hour,
                      interestedCount: count,
                      onView: () {
                        if (onViewStudents != null) {
                          onViewStudents!(hour, count);
                          return;
                        }
                        _defaultNavigate(
                          context,
                          hourLabel: hour,
                          count: count,
                        );
                      },
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ],
    );
  }

  void _defaultNavigate(
    BuildContext context, {
    required String hourLabel,
    required int count,
  }) {
    Navigator.pushNamed(
      context,
      AppRoutes.interestedAtlhetes, // usa a constante que você já tem
      arguments: {
        'date': date,
        'boxId': boxId,
        'category': category,
        'hour': hourLabel,
        'count': count,
      },
    );
  }
}

class _InterestedCard extends StatelessWidget {
  final double scale;
  final String dateLabel;
  final String hourLabel;
  final int interestedCount;
  final VoidCallback onView;

  const _InterestedCard({
    required this.scale,
    required this.dateLabel,
    required this.hourLabel,
    required this.interestedCount,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 10 * scale,
        horizontal: 12 * scale,
      ),
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
      child: Row(
        children: [
          // Texto principal
          Expanded(
            child: Text(
              '$interestedCount alunos interessados no horário $hourLabel',
              style: TextStyle(
                fontSize: 14 * scale,
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),

          // Botão "Ver alunos"
          TextActionButton(
            text: 'Ver alunos',
            onPressed: onView,
            icon: Icons.visibility_outlined,
            color: AppColors.baseBlue,
          ),
        ],
      ),
    );
  }
}
