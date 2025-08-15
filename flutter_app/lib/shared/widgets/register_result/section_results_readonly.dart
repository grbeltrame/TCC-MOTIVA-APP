import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';

class SectionResultsReadonly extends StatelessWidget {
  const SectionResultsReadonly({
    super.key,
    required this.coachName,
    required this.result,
    required this.classLabel, // ex.: "06:00 - WOD"
  });

  final String coachName;
  final CoachFilledResult result;
  final String classLabel;

  String _mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título contextual
        Text(
          'Seu resultado no treino de hoje foi preenchido pelo coach $coachName',
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
            fontSize: 16 * scale,
            color: AppColors.darkText,
          ),
        ),
        SizedBox(height: 10 * scale),

        // ==== Linha 1: Categoria + Adaptado ====
        Wrap(
          spacing: 12 * scale,
          runSpacing: 10 * scale,
          children: [
            _ChipValue(label: 'Categoria:', value: result.category),
            _ChipValue(
              label: 'Adaptado?:',
              value: result.adapted ? 'Sim' : 'Não',
            ),
          ],
        ),
        SizedBox(height: 4 * scale),

        // ==== Linha 2: Concluiu + Turma ====
        Wrap(
          spacing: 12 * scale,
          runSpacing: 10 * scale,
          children: [
            _ChipValue(
              label: 'Concluiu?:',
              value: result.completed ? 'Sim' : 'Não',
            ),
            _ChipValue(label: 'Turma:', value: classLabel),
          ],
        ),
        SizedBox(height: 4 * scale),

        // ==== Linha 3: Tipo ====
        _ChipValue(label: 'Tipo:', value: result.wodType),

        // ==== Condicionais (mesma regra do sheet original) ====
        if (result.wodType == 'AMRAP') ...[
          SizedBox(height: 10 * scale),
          Wrap(
            spacing: 12 * scale,
            runSpacing: 10 * scale,
            children: [
              _ChipValue(
                label: 'Rounds:',
                value: (result.amrapRounds ?? 0).toString(),
              ),
              _ChipValue(
                label: 'Reps:',
                value: (result.amrapReps ?? 0).toString(),
              ),
            ],
          ),
        ],
        if (result.wodType == 'For time' && result.forTimeSec != null) ...[
          SizedBox(height: 10 * scale),
          _ChipValue(label: 'Tempo?:', value: _mmss(result.forTimeSec!)),
        ],
      ],
    );
  }
}

/// Chip de label + texto (sem caixinha), igual estética das outras sections.
class _ChipValue extends StatelessWidget {
  const _ChipValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // chip
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 3 * scale,
            ),
            decoration: BoxDecoration(
              color: AppColors.lightBlue.withAlpha(50),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                fontSize: 12 * scale,
                color: AppColors.baseBlue,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),

          // valor (texto simples, sem borda/caixa)
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.regular,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
