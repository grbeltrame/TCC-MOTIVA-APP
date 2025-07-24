import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/goal_card_widget.dart';
import 'package:flutter_app/shared/widgets/highlights_carousel.dart';
import 'package:flutter_app/shared/widgets/monthly_summary_widget.dart';
import 'package:flutter_app/shared/widgets/recomendations_carousel.dart';
import 'package:flutter_app/core/services/recomendations_service.dart';
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
            // ----- Título Widget de Resumo Mensal -----
            const MonthlySummaryWidget(),
            const SizedBox(height: 24),

            // ----- Título da seção de Highlights -----
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Destaques Inteligentes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            SizedBox(height: 8 * scale),
            FutureBuilder<List<HighlightModel>>(
              future: _futureHighlights,
              builder: (context, snapHighlights) {
                return FutureBuilder<Set<String>>(
                  future: _fetchEnabledHighlightsTypes,
                  builder: (context, snapHighlightTypes) {
                    if (snapHighlights.connectionState !=
                            ConnectionState.done ||
                        snapHighlightTypes.connectionState !=
                            ConnectionState.done) {
                      return const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final highlights = snapHighlights.data!;
                    final enabled = snapHighlightTypes.data!;
                    return HighlightsCarousel(
                      allHighlights: highlights,
                      enabledHighlightsTypes: enabled,
                    );
                  },
                );
              },
            ),

            SizedBox(height: 32 * scale),

            // ----- Título da seção de Alertas -----
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Alertas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            // 1) Carrega ambos os futuros e renderiza o carousel quando prontos
            FutureBuilder<List<AlertModel>>(
              future: _futureAlerts,
              builder: (context, snapAlerts) {
                return FutureBuilder<Set<String>>(
                  future: _futureEnabledTypes,
                  builder: (context, snapTypes) {
                    if (snapAlerts.connectionState != ConnectionState.done ||
                        snapTypes.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final alerts = snapAlerts.data!;
                    final enabled = snapTypes.data!;
                    return AlertsCarousel(
                      allAlerts: alerts,
                      enabledTypes: enabled,
                    );
                  },
                );
              },
            ),

            SizedBox(height: 32 * scale),

            // ----- Título da seção de Sugestão de Objetivos -----
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Text(
                    'Sugestões de Objetivos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Text(
                    'Clique em + para adicionar objetivo a lista',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.medium,
                      fontSize: 12 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
                SizedBox(height: 16 * scale),
                const SuggestedGoalsSection(),
              ],
            ),

            SizedBox(height: 32 * scale),
            // ----- Título da seção de Recomendations -----
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Recomendações Inteligentes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<RecomendationModel>>(
              future: _futureRecomendations,
              builder: (context, snapRecomendations) {
                return FutureBuilder<Set<String>>(
                  future: _fetchEnabledRecomendationsTypes,
                  builder: (context, snapRecomendationsTypes) {
                    if (snapRecomendations.connectionState !=
                            ConnectionState.done ||
                        snapRecomendationsTypes.connectionState !=
                            ConnectionState.done) {
                      return const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final recomendations = snapRecomendations.data!;
                    final enabled = snapRecomendationsTypes.data!;
                    return RecomendationsCarousel(
                      allRecomendations: recomendations,
                      enabledRecomendationsTypes: enabled,
                    );
                  },
                );
              },
            ),

            SizedBox(height: 32 * scale),
            // ----- Seção de Resumo Semanal -----
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Resumo Semanal',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            SizedBox(height: 8 * scale),

            // --- Widget principal de Resumo Semanal ---
            const WeeklySummaryWidget(),
          ],
        ),
      ),
    );
  }
}
