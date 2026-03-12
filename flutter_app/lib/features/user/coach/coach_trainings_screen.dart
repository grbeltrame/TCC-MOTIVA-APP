import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_daily_trainings_section.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_trainings_actions_section.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/date_selector.dart'; // Importante para o seletor funcionar

class CoachTrainingScreen extends StatefulWidget {
  static const routeName = '/coach_training';
  const CoachTrainingScreen({Key? key}) : super(key: key);

  @override
  State<CoachTrainingScreen> createState() => _CoachTrainingScreenState();
}

class _CoachTrainingScreenState extends State<CoachTrainingScreen> {
  // Estado local para a data selecionada
  DateTime _selectedDate = DateTime.now();

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const Placeholder());
  }

  // Função chamada quando trocamos a data no DateSelector
  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
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
            // Botões de Ação
            const CoachTrainingActionsSection(),

            const SizedBox(height: 16),

            // Seletor de Data (Controla o que aparece embaixo)
            DateSelector(
              initialDate: _selectedDate,
              onDateChanged: _onDateChanged,
            ),

            const SizedBox(height: 16),

            // SEÇÃO DE TREINOS DO DIA
            // Passamos a data selecionada para que ele busque WOD, LPO, etc daquele dia
            CoachDailyTrainingsSection(boxId: '1', date: _selectedDate),
          ],
        ),
      ),
    );
  }
}
