// lib/shared/screens/athlete_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/cards/daily_training_summary_card.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/home_greeting_section.dart';
import 'package:flutter_app/shared/widgets/home_primary_actions.dart';
import 'package:flutter_app/shared/widgets/mocks/near_completion_section.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/pending_actions_section.dart';
import 'package:flutter_app/shared/widgets/carousels/performance_insights_carousel.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class AthleteHomeScreen extends StatefulWidget {
  static const routeName = '/athlete_home';
  const AthleteHomeScreen({Key? key}) : super(key: key);

  @override
  State<AthleteHomeScreen> createState() => _AthleteHomeScreenState();
}

class _AthleteHomeScreenState extends State<AthleteHomeScreen> {
  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),
      bottomNavigationBar: const BottomNavBar(),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 16 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Saudação inicial
            const HomeGreetingSection(),

            // Inisghts de performance do usuario
            const PerformanceInsightsCarousel(),

            // Navegação incial
            const HomePrimaryActions(),

            // Resumo do Treino
            const DailyTrainingSummaryCard(),

            // Ações Pendentes
            const PendingActionsSection(),

            // Metas quase atingidas
            AlmostReachedGoalsSection(
              title: 'Metas Próximas',
              buttonLabel: 'Ver todas as metas',
              onButtonPressed:
                  () => Navigator.pushNamed(context, AppRoutes.athleteGoals),
            ),
          ],
        ),
      ),
    );
  }
}
