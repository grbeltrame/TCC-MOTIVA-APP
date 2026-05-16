import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_daily_trainings_section.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_trainings_actions_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/core/constants/app_box.dart';
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

  // Tick incrementa a cada pull-to-refresh; força a section dos treinos a
  // recriar seu Future via ValueKey, recarregando do Firestore.
  int _refreshTick = 0;

  // Função chamada quando trocamos a data no DateSelector
  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshTick++);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: 8 * scale,
            horizontal: 12 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Botões de Ação
              CoachTrainingActionsSection(selectedDate: _selectedDate),

              const SizedBox(height: 16),

              // Seletor de Data (Controla o que aparece embaixo)
              DateSelector(
                initialDate: _selectedDate,
                onDateChanged: _onDateChanged,
              ),

              const SizedBox(height: 16),

              // SEÇÃO DE TREINOS DO DIA
              // Passamos a data selecionada para que ele busque WOD, LPO, etc daquele dia
              CoachDailyTrainingsSection(
                key: ValueKey(
                  'coach_daily_trainings_${_selectedDate.toIso8601String()}_$_refreshTick',
                ),
                boxId: AppBox.id,
                date: _selectedDate,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
