import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_daily_overview_section.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_daily_summary_section.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_daily_trainings_section.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_trainings_actions_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class CoachTrainingScreen extends StatefulWidget {
  static const routeName = '/coach_training';
  const CoachTrainingScreen({Key? key}) : super(key: key);

  @override
  State<CoachTrainingScreen> createState() => _CoachTrainingScreenState();
}

class _CoachTrainingScreenState extends State<CoachTrainingScreen> {
  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const Placeholder());
    // TODO: trocar Placeholder pelo bottom sheet real quando existir
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
            // Botoes inicais
            const CoachTrainingActionsSection(),

            // Resumo dos treinos do dia
            const SizedBox(height: 16),
            const CoachDailyTrainingsSection(boxId: '1'),

            // TODO: passe o boxId real do coach
            // const SizedBox(height: 16),
            // CoachDailySummarySection(date: DateTime.now()),
            const SizedBox(height: 16),
            CoachDailyOverviewSection(
              date:
                  DateTime.now(), // ou a data selecionada pelo seu DateSelector
              boxId: '1', // TODO: passar o boxId real selecionado
            ),
          ],
        ),
      ),
    );
  }
}
