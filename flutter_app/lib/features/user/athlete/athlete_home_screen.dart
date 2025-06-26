import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/highlights_carousel.dart';
import 'package:flutter_app/shared/widgets/top_navbar.dart';
import 'package:flutter_app/core/services/profile_service.dart';
import 'package:flutter_app/shared/widgets/alerts_carousel.dart';
import 'package:flutter_app/core/services/alerts_service.dart';
import 'package:flutter_app/core/services/highlights_service.dart';

final _profileService = ProfileService();
final _alertsService = AlertsService();
final _highlightsService = HighlightsService();

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

  @override
  void initState() {
    super.initState();
    _futureAlerts = _alertsService.fetchAlerts();
    _futureEnabledTypes = _alertsService.fetchEnabledTypes();

    _futureHighlights = _highlightsService.fetchHighlights();
    _fetchEnabledHighlightsTypes =
        _highlightsService.fetchEnabledHighlightsTypes();
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
    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
          ],
        ),
      ),
    );
  }
}
