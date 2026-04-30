// lib/shared/screens/athlete_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/cards/daily_training_summary_card.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/home_greeting_section.dart';
import 'package:flutter_app/shared/widgets/home_primary_actions.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/pending_actions_section.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/athlete_insights_carousel_loader.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class AthleteHomeScreen extends StatefulWidget {
  static const routeName = '/athlete_home';
  const AthleteHomeScreen({Key? key}) : super(key: key);

  @override
  State<AthleteHomeScreen> createState() => _AthleteHomeScreenState();
}

class _AthleteHomeScreenState extends State<AthleteHomeScreen> {
  // Tick incrementa a cada pull-to-refresh; usado como ValueKey para forçar
  // os widgets filhos a refazerem seus FutureBuilders/StreamBuilders.
  int _refreshTick = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshTick++);
    // Pequena espera dá feedback visual do indicador antes de o conteúdo
    // reaparecer; os fetches dos filhos rodam em paralelo.
    await Future<void>.delayed(const Duration(milliseconds: 400));
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
          child: KeyedSubtree(
            key: ValueKey('athlete_home_$_refreshTick'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Saudação inicial
                const HomeGreetingSection(),

                // Insights do atleta (2 semanais + 2 de evolução, sorteados)
                const AthleteInsightsCarouselLoader(
                  mode: AthleteInsightsMode.homeMix,
                ),

                // Navegação incial
                const HomePrimaryActions(),

                // Resumo do Treino
                const DailyTrainingSummaryCard(),

                // Ações Pendentes
                const PendingActionsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
