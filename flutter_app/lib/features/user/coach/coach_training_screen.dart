// lib/shared/screens/athlete_training_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_trainings_actions_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';

import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class CoachTrainingScreen extends StatefulWidget {
  static const routeName = '/coach_training';
  const CoachTrainingScreen({Key? key}) : super(key: key);

  @override
  State<CoachTrainingScreen> createState() => _CoachTrainingScreenState();
}

class _CoachTrainingScreenState extends State<CoachTrainingScreen> {
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
          vertical: 8 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botoes de navegação
            CoachTrainingsActionsSection(),
          ],
        ),
      ),
    );
  }
}
