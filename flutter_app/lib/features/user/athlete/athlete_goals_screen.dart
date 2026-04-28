// lib/shared/screens/athlete_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/create_goal/create_goal_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/mocks/near_completion_section.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/section_badges_summary.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class AthleteGoalsScreen extends StatefulWidget {
  static const routeName = '/athlete_goals';
  const AthleteGoalsScreen({Key? key}) : super(key: key);

  @override
  State<AthleteGoalsScreen> createState() => _AthleteGoalsScreenState();
}

class _AthleteGoalsScreenState extends State<AthleteGoalsScreen> {
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),

      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 8.0 * scale,
          left: 6.0 * scale,
          right: 6.0 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBackButton(),
            SizedBox(height: 12 * scale),
            const SectionBadgesSummary(),
            // Metas quase atingidas
            AlmostReachedGoalsSection(
              title: 'Próximas Metas',
              buttonLabel: 'Cadastrar metas',
              onButtonPressed: () => showCreateGoalBottomSheet(context),
            ),
          ],
        ),
      ),
    );
  }
}
