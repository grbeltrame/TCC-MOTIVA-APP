import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

class CoachCycleTrainingTypeDetailScreen extends StatefulWidget {
  static const routeName = '/coach_cycle_training_type_detail';
  const CoachCycleTrainingTypeDetailScreen({Key? key}) : super(key: key);

  @override
  State<CoachCycleTrainingTypeDetailScreen> createState() =>
      _CoachCycleTrainingTypeDetailScreenState();
}

class _CoachCycleTrainingTypeDetailScreenState
    extends State<CoachCycleTrainingTypeDetailScreen> {
  void _openRegisterBoxSheet() {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};

    final year = (args['year'] ?? DateTime.now().year) as int;
    final month = (args['month'] ?? DateTime.now().month) as int;
    final typeLabel = (args['typeLabel'] ?? 'Treinos') as String;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: _openRegisterBoxSheet),
      bottomNavigationBar: const BottomNavBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 8 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBackButton(),
            SizedBox(height: 12 * scale),
            Text(
              'Detalhe: $typeLabel',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 6 * scale),
            Text('Ciclo: $month/$year'),
            SizedBox(height: 16 * scale),
            const Text('Página mockada — vamos construir depois.'),
          ],
        ),
      ),
    );
  }
}
