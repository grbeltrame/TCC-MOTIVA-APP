// lib/shared/widgets/goal_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class GoalCardWidget extends StatelessWidget {
  final String badgeAsset;
  final String title;
  final int deadlineWeeks;
  final DateTime startDate;
  final int unitsPerWeek;
  final int completedUnits;

  /// Botão “+” legado (mantido pra compatibilidade)
  final bool showAddButton;
  final VoidCallback? onAdd;

  /// NOVO: botão de lixeira vermelho
  final bool showDeleteButton;
  final VoidCallback? onDelete;

  const GoalCardWidget({
    Key? key,
    required this.badgeAsset,
    required this.title,
    required this.deadlineWeeks,
    required this.startDate,
    required this.unitsPerWeek,
    required this.completedUnits,
    this.showAddButton = false,
    this.onAdd,
    this.showDeleteButton = false,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final elapsedWeeks = DateTime.now().difference(startDate).inDays ~/ 7;
    final totalUnits = deadlineWeeks * unitsPerWeek;
    final progress = totalUnits == 0 ? 0.0 : completedUnits / totalUnits;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.baseBlue, width: 1 * scale),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      padding: EdgeInsets.all(8 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // emblema
          Container(
            width: 72 * scale,
            alignment: Alignment.topCenter,
            child: Image.asset(
              badgeAsset,
              width: 72 * scale,
              height: 72 * scale,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8 * scale),

          // textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 14 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    if (showAddButton)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.add,
                          size: 20 * scale,
                          color: AppColors.mediumGray,
                        ),
                        onPressed: onAdd,
                      ),
                    if (showDeleteButton)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 20 * scale,
                          color: AppColors.baseMagenta,
                        ),
                        onPressed: onDelete,
                        tooltip: 'Excluir meta',
                      ),
                  ],
                ),
                Text(
                  'Prazo: $deadlineWeeks ${deadlineWeeks == 1 ? 'semana' : 'semanas'}',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 12 * scale,
                    height: 1.0,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  'Tempo decorrido: $elapsedWeeks ${elapsedWeeks == 1 ? 'semana' : 'semanas'}',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 12 * scale,
                    height: 1.0,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Row(
                  children: [
                    SizedBox(
                      width: 210 * scale,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8 * scale),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4 * scale,
                          backgroundColor: AppColors.lightGray,
                          valueColor: AlwaysStoppedAnimation(
                            AppColors.baseBlue,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Text(
                      '$completedUnits',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 12 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
