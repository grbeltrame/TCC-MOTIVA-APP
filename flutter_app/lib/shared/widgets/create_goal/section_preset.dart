import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/create_goal/create_goal_types.dart';
import 'package:flutter_app/shared/widgets/create_goal/mini_number_field.dart';
import 'package:flutter_app/shared/widgets/create_goal/plain_dropdown.dart';
import 'package:flutter_app/shared/widgets/create_goal/section_card.dart';

class SectionGoalPreset extends StatelessWidget {
  const SectionGoalPreset({
    super.key,
    required this.selectedPreset,
    required this.onChangedPreset,

    // Frequency
    required this.freqAction,
    required this.onChangedFreqAction,
    required this.freqQty,
    required this.onChangedFreqQty,
    required this.freqPeriod,
    required this.onChangedFreqPeriod,

    // PR
    required this.prDiscipline,
    required this.onChangedDiscipline,
    required this.prMovement,
    required this.onChangedMovement,
    required this.prTargetController,
    required this.lpoMoves,
    required this.gymMoves,
    required this.enduranceMoves,

    // Preview
    required this.previewTitle,
  });

  final GoalPresetCategory? selectedPreset;
  final ValueChanged<GoalPresetCategory?> onChangedPreset;

  final String freqAction;
  final ValueChanged<String> onChangedFreqAction;
  final int freqQty;
  final ValueChanged<int> onChangedFreqQty;
  final String freqPeriod;
  final ValueChanged<String> onChangedFreqPeriod;

  final String? prDiscipline;
  final ValueChanged<String?> onChangedDiscipline;
  final String? prMovement;
  final ValueChanged<String?> onChangedMovement;
  final TextEditingController prTargetController;
  final List<String> lpoMoves;
  final List<String> gymMoves;
  final List<String> enduranceMoves;

  final String previewTitle;

  List<String> _movesFor(String? discipline) {
    switch (discipline) {
      case 'LPO':
        return lpoMoves;
      case 'Ginástica':
        return gymMoves;
      case 'Endurance':
        return enduranceMoves;
      default:
        return const [];
    }
  }

  String _suffixForDiscipline(String? discipline) {
    switch (discipline) {
      case 'LPO':
        return 'kg';
      case 'Ginástica':
        return 'reps';
      case 'Endurance':
        return '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Text(
            'Monte sua meta',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 14 * scale,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 10 * scale),

          // Dropdown da categoria
          PlainDropdown<GoalPresetCategory>(
            value: selectedPreset,
            hintText: 'Escolher a categoria da sua meta',
            items: const [
              DropdownMenuItem(
                value: GoalPresetCategory.frequency,
                child: Text('Frequência'),
              ),
              DropdownMenuItem(value: GoalPresetCategory.pr, child: Text('PR')),
            ],
            onChanged: onChangedPreset,
          ),

          // Campos dependentes
          if (selectedPreset == GoalPresetCategory.frequency) ...[
            SizedBox(height: 10 * scale),
            Wrap(
              spacing: 10 * scale,
              runSpacing: 8 * scale,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PlainDropdown<String>(
                  value: freqAction,
                  items: const [
                    DropdownMenuItem(value: 'Treinar', child: Text('Treinar')),
                    DropdownMenuItem(
                      value: 'Registrar Resultado',
                      child: Text('Registrar Resultado'),
                    ),
                  ],
                  onChanged: (v) => onChangedFreqAction(v ?? 'Treinar'),
                ),
                MiniNumberField(
                  value: freqQty,
                  onChanged: (val) => onChangedFreqQty(val < 1 ? 1 : val),
                ),
                PlainDropdown<String>(
                  value: freqPeriod,
                  items: const [
                    DropdownMenuItem(
                      value: 'semana',
                      child: Text('por semana'),
                    ),
                    DropdownMenuItem(value: 'mês', child: Text('por mês')),
                  ],
                  onChanged: (v) => onChangedFreqPeriod(v ?? 'semana'),
                ),
              ],
            ),
          ],

          if (selectedPreset == GoalPresetCategory.pr) ...[
            SizedBox(height: 10 * scale),
            // Disciplina
            PlainDropdown<String>(
              value: prDiscipline,
              hintText: 'Escolha a categoria do PR',
              items: const [
                DropdownMenuItem(value: 'LPO', child: Text('LPO')),
                DropdownMenuItem(value: 'Ginástica', child: Text('Ginástica')),
                DropdownMenuItem(value: 'Endurance', child: Text('Endurance')),
              ],
              onChanged: onChangedDiscipline,
            ),
            SizedBox(height: 10 * scale),

            if (prDiscipline != null)
              Wrap(
                spacing: 10 * scale,
                runSpacing: 8 * scale,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Movimento
                  Builder(
                    builder: (context) {
                      final moves = _movesFor(prDiscipline);
                      final currentValue =
                          moves.contains(prMovement?.trim())
                              ? prMovement!.trim()
                              : null;
                      return PlainDropdown<String>(
                        key: ValueKey('mov-$prDiscipline-${moves.join("|")}'),
                        value: currentValue,
                        hintText: 'Movimento',
                        items:
                            moves
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                        onChanged: onChangedMovement,
                      );
                    },
                  ),
                  // Alvo
                  MiniNumberField(
                    controller: prTargetController,
                    suffix: _suffixForDiscipline(prDiscipline),
                    onChanged: (_) {},
                  ),
                ],
              ),
          ],

          if (selectedPreset != null) ...[
            SizedBox(height: 12 * scale),
            Text(
              'Pré-visualização:',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                fontSize: 12 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 4 * scale),
            Text(
              previewTitle,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
