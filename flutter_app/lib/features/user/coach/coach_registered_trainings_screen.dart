import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_class_registration_section.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_daily_insights_section.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_registered_trainings_section.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

typedef OnTrainingSelection =
    void Function(DateTime date, String category, String? trainingBlockId);

class CoachRegisteredTrainingScreen extends StatefulWidget {
  static const routeName = '/coach_registered_training';
  const CoachRegisteredTrainingScreen({Key? key}) : super(key: key);

  @override
  State<CoachRegisteredTrainingScreen> createState() =>
      _CoachRegisteredTrainingScreenState();
}

class _CoachRegisteredTrainingScreenState
    extends State<CoachRegisteredTrainingScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategory; // 'WOD' | 'LPO' | 'Ginastica' | 'Endurance'
  String? _selectedTrainingId; // id do bloco/treino exibido no card
  final String _boxId = 'DEFAULT_BOX';

  void _onSelectionChanged({
    required DateTime date,
    required String category,
    required String trainingBlockId,
  }) {
    setState(() {
      _selectedDate = date;
      _selectedCategory = category;
      _selectedTrainingId = trainingBlockId;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBackButton(),

            // Passe o callback para receber alterações de data/tipo/treino
            CoachRegisteredTrainingsSection(
              // Adicione este parâmetro na section:
              // final void Function({required DateTime date, required String category, required String trainingBlockId})?
              //     onSelectionChanged;
              // E dispare sempre que mudar a data, o tipo, ou carregar o bloco.
              // Exemplo de chamada interna:
              // widget.onSelectionChanged?.call(
              //   date: _date,
              //   category: _category,
              //   trainingBlockId: block.id,
              // );
              key: const ValueKey('registered_trainings'),
              // ignore: avoid_types_on_closure_parameters
              // onSelectionChanged: _onSelectionChanged,  // ← descomente quando implementar na section
            ),

            SizedBox(height: 16 * scale),

            // Insights do treino selecionado (cai para "do dia" se faltarem params)
            CoachDailyInsightsSection(
              date: _selectedDate,
              boxId: 'DEFAULT_BOX',
              selectedCategory: _selectedCategory, // opcional
              trainingId: _selectedTrainingId, // opcional
              title: 'Insights do Treino',
              showSeeAllButton: true,
              showWeeklyAnalysisButton: false,
              showCycleProjectionButton: false,
            ),
            SizedBox(height: 16 * scale),

            // CoachClassRegistrationsSection(
            //   date:
            //       DateTime.now(), // ou a mesma data da section acima, se elevar o estado
            //   boxId: _boxId, // opcional: nº de barras por página
            // ),
          ],
        ),
      ),
    );
  }

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const Placeholder());
  }
}
