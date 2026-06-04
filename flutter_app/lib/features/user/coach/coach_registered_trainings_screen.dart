import 'package:flutter/material.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};

    if (args.containsKey('year') && args.containsKey('month')) {
      final year = args['year'] as int;
      final month = args['month'] as int;
      final now = DateTime.now();
      _selectedDate =
          (now.year == year && now.month == month)
              ? DateTime(now.year, now.month, now.day)
              : DateTime(year, month, 1);
    } else {
      _selectedDate = DateTime.now();
    }

    if (args.containsKey('typeLabel')) {
      _selectedCategory = _mapTypeLabelToCategory(args['typeLabel'] as String);
    }
  }

  String _mapTypeLabelToCategory(String typeLabel) {
    final l = typeLabel.toLowerCase().trim();
    if (l.contains('wod')) return 'WOD';
    if (l.contains('lpo')) return 'LPO';
    if (l.contains('endurance')) return 'Endurance';
    if (l.contains('gin') || l.contains('gym')) return 'Ginastica';
    return typeLabel.trim();
  }

  // Fix Bug 4: assinatura alinhada com a section.
  // trainingBlockId é String? (nullable) — igual à declaração na section.
  // Antes estava "required String" causando erro de tipo na compilação.
  void _onSelectionChanged({
    required DateTime date,
    required String category,
    String? trainingBlockId,
  }) {
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

            // A section já gerencia o reload internamente via
            // _onTapEditarTreino → .then((saved) { if (saved==true) _reload(); })
            // Não precisamos de refreshKey nem onEditCompleted aqui.
            CoachRegisteredTrainingsSection(
              key: const ValueKey('registered_trainings'),
              initialDate: _selectedDate,
              initialCategory: _selectedCategory,
              onSelectionChanged: _onSelectionChanged,
            ),

            SizedBox(height: 16 * scale),
          ],
        ),
      ),
    );
  }
}
