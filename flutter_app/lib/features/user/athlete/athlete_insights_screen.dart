// lib/features/user/athlete/athlete_insights_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart';
import 'package:flutter_app/shared/widgets/cards/week_calendar_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_effort_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_frequency_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_prs_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_stimuli_card.dart';
import 'package:flutter_app/shared/widgets/carousels/text_carousel.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class AthleteInsightScreen extends StatefulWidget {
  static const routeName = '/athlete_insight';
  const AthleteInsightScreen({Key? key}) : super(key: key);

  @override
  State<AthleteInsightScreen> createState() => _AthleteInsightScreenState();
}

class _AthleteInsightScreenState extends State<AthleteInsightScreen> {
  late Future<AthleteStatsSummary?> _futureSummary;
  late Future<List<InsightModel>> _futureInsights;

  @override
  void initState() {
    super.initState();
    _futureSummary = AthleteStatsService.fetchSummary();
    _futureInsights = WeeklySummaryService().fetchInsights();
  }

  String _weekCountdownText() {
    final now = DateTime.now();
    // Semana dom → sáb: o fim de semana é sábado.
    // Dart weekday: seg=1, ter=2, qua=3, qui=4, sex=5, sáb=6, dom=7
    // Fórmula: (6 - weekday + 7) % 7
    //   sáb(6) → (6-6+7)%7 = 0  ✓ hoje acaba
    //   dom(7) → (6-7+7)%7 = 6  ✓ faltam 6 dias
    //   sex(5) → (6-5+7)%7 = 1  ✓ falta 1 dia
    final daysUntilSaturday = (6 - now.weekday + 7) % 7;
    if (daysUntilSaturday == 0) return 'A semana acaba hoje';
    if (daysUntilSaturday == 1) return 'A semana acaba amanhã';
    return 'A semana acaba em $daysUntilSaturday dias';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),
      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 16 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Título ───────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo Semanal',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    _weekCountdownText(),
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * scale),

            // ── Cards A3 + PRs — carregados de uma só leitura ────────────────
            FutureBuilder<AthleteStatsSummary?>(
              future: _futureSummary,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final summary = snap.data;
                if (summary == null) {
                  return _EmptyState(scale: scale);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Calendário semanal — largura total
                    WeekCalendarCard(summary: summary),

                    SizedBox(height: 2 * scale),

                    // Frequência + Esforço lado a lado
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: WeekFrequencyCard(summary: summary),
                          ),
                          SizedBox(width: 6 * scale),
                          Expanded(
                            child: WeekEffortCard(summary: summary),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2 * scale),

                    // Estímulos — largura total
                    WeekStimuliCard(summary: summary),

                    SizedBox(height: 2 * scale),

                    // PRs batidos — largura total
                    const WeekPRsCard(),
                  ],
                );
              },
            ),

            SizedBox(height: 16 * scale),

            // ── Insights da Semana ───────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Insights da Semana',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            SizedBox(height: 8 * scale),

            Card(
              margin: EdgeInsets.symmetric(vertical: 4 * scale),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: AppColors.mediumGray),
                borderRadius: BorderRadius.circular(16 * scale),
              ),
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16 * scale,
                  14 * scale,
                  16 * scale,
                  16 * scale,
                ),
                child: FutureBuilder<List<InsightModel>>(
                  future: _futureInsights,
                  builder: (context, snap) {
                    final insights = snap.data ?? [];
                    if (insights.isEmpty) {
                      return Text(
                        'Em breve',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: FontWeight.w300,
                          fontStyle: FontStyle.italic,
                          fontSize: 13 * scale,
                          color: AppColors.mediumGray,
                        ),
                      );
                    }
                    return TextCarousel(
                      items: insights.map((i) => i.message).toList(),
                      fontWeight: FontWeight.w300,
                      fontStyle: FontStyle.italic,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estado vazio — atleta ainda não registrou nenhum treino
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final double scale;
  const _EmptyState({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 32 * scale,
        horizontal: 16 * scale,
      ),
      child: Column(
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48 * scale,
            color: AppColors.lightGray,
          ),
          SizedBox(height: 12 * scale),
          Text(
            'Nenhum dado disponível',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 15 * scale,
              fontWeight: FontWeight.bold,
              color: AppColors.mediumGray,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            'Registre seu primeiro treino para ver o resumo da semana.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 13 * scale,
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}
