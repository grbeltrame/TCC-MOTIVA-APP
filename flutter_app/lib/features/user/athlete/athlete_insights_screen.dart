// lib/features/user/athlete/athlete_insights_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';
import 'package:flutter_app/features/user/athlete/athlete_weekly_insights_detail_screen.dart';
import 'package:flutter_app/shared/widgets/cards/week_calendar_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_effort_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_points_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_prs_mini_card.dart';
import 'package:flutter_app/shared/widgets/cards/week_stimuli_card.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/athlete_insights_carousel_loader.dart';
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

  Future<void> _onRefresh() async {
    setState(() {
      _futureSummary = AthleteStatsService.fetchSummary();
    });
    await _futureSummary;
  }

  String _weekCountdownText() {
    final now = DateTime.now();
    final daysUntilSaturday = (6 - now.weekday + 7) % 7;
    if (daysUntilSaturday == 0) return 'A semana acaba hoje';
    if (daysUntilSaturday == 1) return 'A semana acaba amanhã';
    return 'A semana acaba em $daysUntilSaturday dias';
  }

  void _openDetail() {
    Navigator.pushNamed(
      context,
      AthleteWeeklyInsightsDetailScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),
      bottomNavigationBar: const BottomNavBar(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: 16 * scale,
            horizontal: 12 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo semanal',
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
                    // Calendário semanal
                    WeekCalendarCard(summary: summary),

                    SizedBox(height: 8 * scale),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Análise da semana',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.bold,
                            fontSize: 13 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                        _SeeAllLink(scale: scale, onTap: _openDetail),
                      ],
                    ),
                    SizedBox(height: 4 * scale),

                    // Insights da Semana — carrossel
                    AthleteInsightsCarouselLoader(
                      mode: AthleteInsightsMode.weeklyOnly,
                      onTap: _openDetail,
                    ),

                    SizedBox(height: 8 * scale),

                    // PRs + Esforço + Pontos (cards quadrados na mesma grade)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Expanded(
                            child: WeekPrsMiniCard(),
                          ),
                          SizedBox(width: 6 * scale),
                          Expanded(
                            child: WeekEffortCard(summary: summary),
                          ),
                          SizedBox(width: 6 * scale),
                          Expanded(
                            child: WeekPointsCard(summary: summary),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 2 * scale),

                    // Estímulos
                    WeekStimuliCard(summary: summary),
                  ],
                );
              },
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeeAllLink extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;
  const _SeeAllLink({required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 6 * scale,
            vertical: 2 * scale,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ver todos',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w600,
                  color: AppColors.baseBlue,
                ),
              ),
              SizedBox(width: 2 * scale),
              Icon(
                Icons.chevron_right,
                size: 14 * scale,
                color: AppColors.baseBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
