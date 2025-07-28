import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/shared/widgets/alerts_section.dart';
import 'package:flutter_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/goal_card_widget.dart';
import 'package:flutter_app/shared/widgets/highlights_carousel.dart';
import 'package:flutter_app/shared/widgets/highlights_section.dart';
import 'package:flutter_app/shared/widgets/monthly_summary_widget.dart';
import 'package:flutter_app/shared/widgets/recomendations_carousel.dart';
import 'package:flutter_app/core/services/recomendations_service.dart';
import 'package:flutter_app/shared/widgets/recomendations_section.dart';
import 'package:flutter_app/shared/widgets/suggested_goal_section.dart';
import 'package:flutter_app/shared/widgets/top_navbar.dart';
import 'package:flutter_app/shared/widgets/alerts_carousel.dart';
import 'package:flutter_app/core/services/alerts_service.dart';
import 'package:flutter_app/core/services/highlights_service.dart';
import 'package:flutter_app/shared/widgets/weekly_summary_widget.dart';

final _alertsService = AlertsService();
final _highlightsService = HighlightsService();
final _recomendationsService = RecomendationsService();

class AthleteInsightScreen extends StatefulWidget {
  static const routeName = '/athlete_insight';
  const AthleteInsightScreen({Key? key}) : super(key: key);

  @override
  State<AthleteInsightScreen> createState() => _AthleteInsightScreenState();
}

class _AthleteInsightScreenState extends State<AthleteInsightScreen> {
  late Future<List<AlertModel>> _futureAlerts;
  late Future<Set<String>> _futureEnabledTypes;

  late Future<List<HighlightModel>> _futureHighlights;
  late Future<Set<String>> _fetchEnabledHighlightsTypes;

  late Future<List<RecomendationModel>> _futureRecomendations;
  late Future<Set<String>> _fetchEnabledRecomendationsTypes;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _futureAlerts = _alertsService.fetchAlerts();
    _futureEnabledTypes = _alertsService.fetchEnabledTypes();

    _futureHighlights = _highlightsService.fetchHighlights();
    _fetchEnabledHighlightsTypes =
        _highlightsService.fetchEnabledHighlightsTypes();

    _futureRecomendations = _recomendationsService.fetchRecomendations();
    _fetchEnabledRecomendationsTypes =
        _recomendationsService.fetchEnabledRecomendationsTypes();
  }

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),
      bottomNavigationBar: const BottomNavBar(),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ----- Seção de Resumo Mensal -----
            const MonthlySummaryWidget(),
            SizedBox(height: 24 * scale),

            // ----- Seção de Highlights -----
            const HighlightsSection(),

            // ----- Seção de Alertas -----
            const AlertsSection(),

            // -----  Seção de Sugestão de Objetivos -----
            const SuggestedGoalsSection(),

            // ----- Título da seção de Recomendations -----
            const RecomendationsSection(),

            // ----- Seção de Resumo Semanal -----
            const WeeklySummaryWidget(),
          ],
        ),
      ),
    );
  }
}
