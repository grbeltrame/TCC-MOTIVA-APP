// lib/features/coach_home/presentation/coach_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/cards/coach_today_workout_card.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_quick_actions.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class CoachHomeScreen extends StatefulWidget {
  static const routeName = '/coach_home';
  const CoachHomeScreen({Key? key}) : super(key: key);

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
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
            //Botoes de redirecionamento
            const CoachQuickActions(),

            SizedBox(height: 32 * scale),

            // Card de resumo
            CoachTodayWorkoutCard(
              boxId: '1', // ajuste para o boxId real
              date: DateTime.now(), // dia atual
            ),
          ],
        ),
      ),
    );
  }
}
