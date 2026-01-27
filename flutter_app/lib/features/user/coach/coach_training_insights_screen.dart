import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_cycle_insights_section.dart';

class CoachTrainingInsightsScreen extends StatefulWidget {
  static const routeName = '/coach_training_insights';
  const CoachTrainingInsightsScreen({Key? key}) : super(key: key);

  @override
  State<CoachTrainingInsightsScreen> createState() =>
      _CoachTrainingInsightsScreenState();
}

class _CoachTrainingInsightsScreenState
    extends State<CoachTrainingInsightsScreen> {
  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // Leitura opcional de argumentos (para no futuro já vir com mês específico).
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final DateTime? initialMonth = args?['month'] as DateTime?;
    final String boxId = (args?['boxId'] as String?) ?? '1';

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 8 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBackButton(),
            SizedBox(height: 12 * scale),

            CoachCycleInsightsSection(boxId: boxId, initialMonth: initialMonth),
          ],
        ),
      ),
    );
  }
}
