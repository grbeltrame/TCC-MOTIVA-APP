import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/highlights_carousel.dart';
import 'package:flutter_app/shared/widgets/recomendations_carousel.dart';
import 'package:flutter_app/core/services/recomendations_service.dart';
import 'package:flutter_app/shared/widgets/top_navbar.dart';
import 'package:flutter_app/core/services/profile_service.dart';
import 'package:flutter_app/shared/widgets/alerts_carousel.dart';
import 'package:flutter_app/core/services/alerts_service.dart';
import 'package:flutter_app/core/services/highlights_service.dart';

final _profileService = ProfileService();
final _alertsService = AlertsService();
final _highlightsService = HighlightsService();
final _recomendationsService = RecomendationsService();

class AthleteHomeScreen extends StatefulWidget {
  static const routeName = '/athlete_home';
  const AthleteHomeScreen({Key? key}) : super(key: key);

  @override
  State<AthleteHomeScreen> createState() => _AthleteHomeScreenState();
}

class _AthleteHomeScreenState extends State<AthleteHomeScreen> {
  late Future<List<AlertModel>> _futureAlerts;
  late Future<Set<String>> _futureEnabledTypes;

  late Future<List<HighlightModel>> _futureHighlights;
  late Future<Set<String>> _fetchEnabledHighlightsTypes;

  late Future<List<RecomendationModel>> _futureRecomendations;
  late Future<Set<String>> _fetchEnabledRecomendationsTypes;

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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Container(
            height: 200,
            alignment: Alignment.center,
            child: const Text('Formulário de cadastro de box aqui'),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            const SizedBox(height: 24),
            // ----- Título da seção de Highlights -----
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Destaques Inteligentes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
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

            const SizedBox(height: 24),
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
          ],
        ),
      ),
    );
  }
}
