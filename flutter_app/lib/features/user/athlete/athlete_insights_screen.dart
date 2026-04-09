// lib/features/user/athlete/athlete_insights_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';
import 'package:flutter_app/shared/widgets/cards/week_calendar_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_effort_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_frequency_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_stimuli_card.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/alerts_section.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/highlights_section.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/recomendations_section.dart';
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

  @override
  void initState() {
    super.initState();
    _futureSummary = AthleteStatsService.fetchSummary();
  }

  /// Dias restantes até domingo (fim da semana).
  String _weekCountdownText() {
    final now = DateTime.now();
    final daysUntilSunday = 7 - now.weekday; // weekday: 1=seg, 7=dom
    if (daysUntilSunday == 0) return 'A semana acaba hoje';
    if (daysUntilSunday == 1) return 'A semana acaba amanhã';
    return 'A semana acaba em $daysUntilSunday dias';
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
            // ── Título da seção ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insights da Semana',
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

            // ── Cards A3 — carregados de uma só leitura ──────────────────────
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

                    SizedBox(height: 4 * scale),

                    // Frequência + Esforço lado a lado
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: WeekFrequencyCard(summary: summary),
                          ),
                          SizedBox(width: 8 * scale),
                          Expanded(
                            child: WeekEffortCard(summary: summary),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4 * scale),

                    // Estímulos — largura total
                    WeekStimuliCard(summary: summary),
                  ],
                );
              },
            ),

            SizedBox(height: 24 * scale),

            // ── Seções legadas (highlights, alertas, recomendações) ──────────
            const HighlightsSection(),
            const AlertsSection(),
            const RecomendationsSection(),
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
            'Registre seu primeiro treino para ver os insights da semana.',
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
