import 'package:flutter/material.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/utils/date_selector.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training.dart';

/// Section: Título + Subtítulo + DateSelector + botões por tipo existente no dia.
/// Usa TrainingService.fetchTrainingsByCategoryForDate e o model Training.
class CoachDailyTrainingsSection extends StatefulWidget {
  final String boxId; // id do box atual do coach

  const CoachDailyTrainingsSection({super.key, required this.boxId});

  @override
  State<CoachDailyTrainingsSection> createState() =>
      _CoachDailyTrainingsSectionState();
}

class _CoachDailyTrainingsSectionState
    extends State<CoachDailyTrainingsSection> {
  DateTime _date = DateTime.now();
  bool _loading = true;
  Map<String, Training?> _byCategory =
      const {}; // 'WOD' | 'LPO' | 'Ginastica' | 'Endurance'

  // ordem visual como no mock: WOD, Ginástica, LPO, Endurance
  static const List<String> _order = ['WOD', 'Ginastica', 'LPO', 'Endurance'];

  @override
  void initState() {
    super.initState();
    _load(_date);
  }

  Future<void> _load(DateTime d) async {
    setState(() {
      _loading = true;
      _date = d;
    });

    final map = await TrainingService.fetchTrainingsByCategoryForDate(
      boxId: widget.boxId,
      date: d,
    );

    if (!mounted) return;
    setState(() {
      _byCategory = map;
      _loading = false;
    });
  }

  void _openDetail(String category) {
    Navigator.of(context).pushNamed(
      AppRoutes.coachTrainingDetail,
      arguments: {
        'category': category,
        'date': _date, // << mande o DateTime diretamente
        'boxId': widget.boxId, // mantém compat, mesmo sendo 1 box
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título / Subtítulo (imutáveis)
        Text(
          'Treinos do Dia',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 2 * scale),
        Text(
          'Clique no card do treino para ve-lo completo e registrar resultados.',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 12 * scale,
            color: AppColors.mediumGray,
          ),
        ),

        SizedBox(height: 12 * scale),

        // Date selector (seu widget)
        DateSelector(initialDate: _date, onDateChanged: (d) => _load(d)),

        SizedBox(height: 16 * scale),

        if (_loading)
          const Center(child: CircularProgressIndicator())
        else
          Column(
            children: [
              for (final cat in _order)
                if (_byCategory[cat] != null)
                  _TrainingTypeButton(
                    // 👉 Aqui usamos o model Training já retornado pelo service:
                    label: _titleFor(cat, _byCategory[cat]!),
                    onPressed: () => _openDetail(cat),
                  ),
            ],
          ),
      ],
    );
  }

  /// Usa o `Training` do dia para o título do botão (ex.: "WOD - Isabel").
  /// Se por algum motivo vier nulo, usa um rótulo padrão por categoria.
  String _titleFor(String category, Training training) {
    final title = training.title.trim();
    if (title.isNotEmpty) return title;

    switch (category) {
      case 'WOD':
        return 'WOD';
      case 'Ginastica':
        return 'Específico de Ginástica';
      case 'LPO':
        return 'Específico de LPO';
      case 'Endurance':
        return 'Específico de Endurance';
      default:
        return category;
    }
  }
}

/// Botão azul cheio, largura 100%, texto alinhado à esquerda — igual ao mock.
class _TrainingTypeButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _TrainingTypeButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: SizedBox(
        height: 44 * scale,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.baseBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12 * scale),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 14 * scale,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
