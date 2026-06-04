import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/models/athlete_result.dart';

class AthleteResultListItem extends StatelessWidget {
  final AthleteResult result;
  final VoidCallback onTapMore; // abre a tela de perfil do aluno

  const AthleteResultListItem({
    Key? key,
    required this.result,
    required this.onTapMore,
  }) : super(key: key);

  String _formatForTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 10 * scale,
        horizontal: 8 * scale,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.lightGray)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha 1: Nome - Categoria  + ícone (+)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${result.athleteName} – ${result.category}',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 14 * scale,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Icon(
                  Icons.add,
                  color: AppColors.baseBlue,
                  size: 20 * scale,
                ),
                onPressed: onTapMore,
              ),
            ],
          ),

          SizedBox(height: 4 * scale),

          // Linha 2: Concluiu / Adaptou
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 2 * scale,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withAlpha(50),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Row(
                  children: [
                    Text(
                      'Concluiu?: ',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: 12 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4 * scale),

              Text(
                result.completed ? 'Sim' : 'Não',
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: AppColors.mediumGray,
                ),
              ),

              SizedBox(width: 16 * scale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 2 * scale,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withAlpha(50),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Row(
                  children: [
                    Text(
                      'Adaptou?: ',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: 12 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4 * scale),

              Text(
                result.adapted ? 'Sim' : 'Não',
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),

          SizedBox(height: 4 * scale),

          // Linha 3: tipo-dependente + esforço
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 2 * scale,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withAlpha(50),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Row(
                  children: [
                    Text(
                      result.wodType.toLowerCase() == 'for time'
                          ? 'Tempo: '
                          : result.wodType.toLowerCase() == 'amrap'
                          ? 'Rounds e Reps: '
                          : 'Resultado: ',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: 12 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4 * scale),
              Text(
                () {
                  if (result.wodType.toLowerCase() == 'for time') {
                    return result.forTimeSec != null
                        ? _formatForTime(result.forTimeSec!)
                        : '-';
                  }
                  if (result.wodType.toLowerCase() == 'amrap') {
                    final r = result.amrapRounds ?? 0;
                    final reps = result.amrapReps ?? 0;
                    return '$r rounds + $reps reps';
                  }
                  // genérico
                  if (result.forTimeSec != null) {
                    return _formatForTime(result.forTimeSec!);
                  }
                  return '-';
                }(),
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
              SizedBox(width: 16 * scale),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6 * scale,
                  vertical: 2 * scale,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue.withAlpha(50),
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                child: Row(
                  children: [
                    Text(
                      'Esforço: ',
                      style: TextStyle(
                        fontWeight: AppFontWeight.bold,
                        fontSize: 12 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 4 * scale),
              Text(
                '${result.effort}/10',
                style: TextStyle(
                  fontSize: 12 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
