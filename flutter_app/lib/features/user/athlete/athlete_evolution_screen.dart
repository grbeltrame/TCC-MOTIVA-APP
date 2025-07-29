// lib/shared/screens/athlete_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/exercise_weekly_summary_widget.dart';
import 'package:flutter_app/shared/widgets/weekly_statistics_widget.dart';
import 'package:flutter_app/shared/widgets/top_navbar.dart';

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
            // Resumo semanal de exercícios (simples ou complexo)
            const ExerciseWeeklySummaryWidget(),
            const SizedBox(height: 24),

            // Estatísticas da Semana
            const WeeklyStatisticsWidget(),
            const SizedBox(height: 24),

            // ... quaisquer outras seções da página ...
          ],
        ),
      ),
    );
  }
}
