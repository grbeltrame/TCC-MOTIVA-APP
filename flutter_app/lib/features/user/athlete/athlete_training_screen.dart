// lib/shared/screens/athlete_training_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/pre_workout_insights_section.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/training_info_section.dart';

class AthleteTrainingScreen extends StatefulWidget {
  static const routeName = '/athlete_training';
  const AthleteTrainingScreen({Key? key}) : super(key: key);

  @override
  State<AthleteTrainingScreen> createState() => _AthleteTrainingScreenState();
}

class _AthleteTrainingScreenState extends State<AthleteTrainingScreen> {
  DateTime _currentDate = DateTime.now();

  void _onDateChanged(DateTime date) {
    _currentDate = date;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 8 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Treinos do dia
            TrainingInfoSection(onDateChanged: _onDateChanged),
            const SizedBox(height: 40),

            // Insights pré-treino — carrossel real (Gemini) com link
            // "Ver todos" pra tela de detalhe. Resolve workoutId pela
            // data atual; se não houver treino publicado ou insights
            // ainda, a seção fica oculta.
            PreWorkoutInsightsSection(date: _currentDate),

            // // Metas proximas de serem concluidas
            // const NearCompletionSection(),
          ],
        ),
      ),
    );
  }
}
