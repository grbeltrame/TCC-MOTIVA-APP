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
  bool _didInit = false;
  late DateTime _selectedDate;
  String? _selectedCategory; // 'WOD' | 'LPO' | 'Ginastica' | 'Endurance'
  String? _selectedTrainingId;
  final String _boxId = 'DEFAULT_BOX';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    // ✅ Captura os argumentos da rota (se vier da tela de Ciclo)
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};

    if (args.containsKey('year') && args.containsKey('month')) {
      final year = args['year'] as int;
      final month = args['month'] as int;
      // Se estamos no mesmo mês atual, abre no dia de hoje. Se for mês passado/futuro, abre no dia 1.
      final now = DateTime.now();
      _selectedDate =
          (now.year == year && now.month == month)
              ? DateTime(now.year, now.month, now.day)
              : DateTime(year, month, 1);
    } else {
      _selectedDate = DateTime.now();
    }

    // ✅ Mapeia a categoria que veio do clique (WOD, LPO, etc)
    if (args.containsKey('typeLabel')) {
      _selectedCategory = _mapTypeLabelToCategory(args['typeLabel'] as String);
    }
  }

  // Função auxiliar para garantir que o filtro vá com o nome exato que a aba espera
  String _mapTypeLabelToCategory(String typeLabel) {
    final l = typeLabel.toLowerCase().trim();
    if (l.contains('wod')) return 'WOD';
    if (l.contains('lpo')) return 'LPO';
    if (l.contains('endurance')) return 'Endurance';
    if (l.contains('gin') || l.contains('gym')) return 'Ginastica';
    return typeLabel.trim();
  }

  void _onSelectionChanged({
    required DateTime date,
    required String category,
    required String trainingBlockId,
  }) {
    // Evita setState desnecessário se nada mudou
    if (_selectedDate == date &&
        _selectedCategory == category &&
        _selectedTrainingId == trainingBlockId)
      return;

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

            // ✅ Passamos as variáveis iniciais para a Section desenhar a tela certa
            CoachRegisteredTrainingsSection(
              key: const ValueKey('registered_trainings'),
              initialDate: _selectedDate, // Precisamos adicionar isso lá!
              initialCategory:
                  _selectedCategory, // Precisamos adicionar isso lá!
              // onSelectionChanged: _onSelectionChanged, // Descomente quando a section suportar
            ),

            SizedBox(height: 16 * scale),

            CoachDailyInsightsSection(
              date: _selectedDate,
              boxId: _boxId,
              selectedCategory: _selectedCategory,
              trainingId: _selectedTrainingId,
              title: 'Insights do Treino',
              showSeeAllButton: true,
              showWeeklyAnalysisButton: false,
              showCycleProjectionButton: false,
            ),
            SizedBox(height: 16 * scale),
          ],
        ),
      ),
    );
  }

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const Placeholder());
  }
}
