// lib/shared/screens/athlete_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/analysis_section.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/championship_section.dart';
import 'package:flutter_app/shared/widgets/exercise_weekly_summary_widget.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/user_goals_section.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/weekly_recomendation_section.dart';
import 'package:flutter_app/shared/widgets/weekly_statistics_widget.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/well_being_section.dart';

class AthleteEvolutionScreen extends StatefulWidget {
  static const routeName = '/athlete_evolution';
  const AthleteEvolutionScreen({Key? key}) : super(key: key);

  @override
  State<AthleteEvolutionScreen> createState() => _AthleteEvolutionScreenState();
}

class _AthleteEvolutionScreenState extends State<AthleteEvolutionScreen> {
  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
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
            // Resumo semanal de exercícios (simples ou complexo)
            const ExerciseWeeklySummaryWidget(),
            const SizedBox(height: 24),

            // Estatísticas da Semana
            const WeeklyStatisticsWidget(),
            const SizedBox(height: 24),

            // Analises
            const AnalysisSection(),

            // // Campeonatos
            // const ChampionshipsSection(),

            // // Metas do Usuario
            // const UserGoalsSection(),

            // // Bem estar do Usuario
            // const WellBeingSection(),

            // Destaques da Semana
            const WeeklyRecomendationSection(),
          ],
        ),
      ),
    );
  }
}
