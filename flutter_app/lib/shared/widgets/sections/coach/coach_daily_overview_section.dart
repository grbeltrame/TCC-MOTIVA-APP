import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_daily_insights_section.dart';

// IMPORTA a section de abas que fizemos agora há pouco
import 'package:flutter_app/shared/widgets/sections/coach/daily_summary_tabs.dart';

/// Section MAIOR: "Resumo do dia (Coach)"
/// - Renderiza o título "Resumo do dia"
/// - Chama a section das tabs (WOD/LPO/Ginástica/Endurance)
/// - Servirá para agrupar as próximas subsections (insights, CTAs, etc.)
class CoachDailyOverviewSection extends StatelessWidget {
  final DateTime date;
  final String boxId;

  const CoachDailyOverviewSection({
    Key? key,
    required this.date,
    required this.boxId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ----- TÍTULO DA SECTION -----
        Text('Resumo do dia', style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 8 * scale),

        // ----- SUBSECTION: TAB BAR + GRÁFICOS + ESFORÇO -----
        CoachDailySummaryTabs(date: date, boxId: boxId),

        CoachDailyInsightsSection(
          date: DateTime.now(),
          boxId: 'BOX_123', // passe o id real do seu box
        ),
      ],
    );
  }
}
