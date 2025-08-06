// lib/shared/screens/athlete_training_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/training_service.dart';
import 'package:flutter_app/shared/models/box.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/inisghts_section.dart';
import 'package:flutter_app/shared/widgets/monthly_summary_widget.dart';
import 'package:flutter_app/shared/widgets/near_completion_section.dart';
import 'package:flutter_app/shared/widgets/top_navbar.dart';
import 'package:flutter_app/shared/widgets/training_info_section.dart';

class AthleteTrainingScreen extends StatefulWidget {
  static const routeName = '/athlete_training';
  const AthleteTrainingScreen({Key? key}) : super(key: key);

  @override
  State<AthleteTrainingScreen> createState() => _AthleteTrainingScreenState();
}

class _AthleteTrainingScreenState extends State<AthleteTrainingScreen> {
  Box? _currentBox;
  DateTime _currentDate = DateTime.now();
  List<Training> _trainings = [];

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  void _onBoxChanged(Box box) {
    _currentBox = box;
    _loadTrainings();
  }

  void _onDateChanged(DateTime date) {
    _currentDate = date;
    _loadTrainings();
  }

  Future<void> _loadTrainings() async {
    if (_currentBox == null) return;
    final list = await TrainingService.fetchTrainingsForBox(
      boxId: _currentBox!.id,
      date: _currentDate,
    );
    setState(() => _trainings = list);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),
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
            TrainingInfoSection(
              onBoxChanged: _onBoxChanged,
              onDateChanged: _onDateChanged,
            ),
            const SizedBox(height: 40),

            // Insights sobre o treino do dia
            InsightsSection(),

            // Metas proximas de serem concluidas
            const NearCompletionSection(),
          ],
        ),
      ),
    );
  }
}
