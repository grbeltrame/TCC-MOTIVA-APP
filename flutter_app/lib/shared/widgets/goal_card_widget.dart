// lib/shared/widgets/goal_card_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Cartão de acompanhamento de meta.
/// 1) Linha superior com duas colunas:
///    - Coluna 1: emblema (hexágono + ícone), maior.
///    - Coluna 2: título + botão “+” ao lado, abaixo prazo e tempo decorrido.
/// 2) Abaixo dos textos, indicador de progresso alinhado à coluna 2.
class GoalCardWidget extends StatelessWidget {
  final String badgeAsset;
  final String title;
  final int deadlineWeeks;
  final DateTime startDate;
  final int unitsPerWeek;
  final int completedUnits;
  final bool showAddButton;
  final VoidCallback? onAdd;

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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Escala baseada na largura de design (375dp)
    final scale = MediaQuery.of(context).size.width / 375.0;

    // Cálculo de semanas e progresso
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
          // Coluna 1: emblema maior
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

          // Coluna 2: textos e botão
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha do título com botão “+”
                // Dentro do Column da Coluna 2:

                // 1) Título + botão sem padding extra
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
                        // 1) reduz o padding interno ao mínimo
                        padding: EdgeInsets.zero,
                        // 2) remove as constraints padrões do IconButton
                        constraints: const BoxConstraints(),
                        // 3) encolhe o hit‑area para caber no tamanho do ícone
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.add,
                          size: 20 * scale,
                          color: AppColors.mediumGray,
                        ),
                        onPressed: onAdd,
                      ),
                  ],
                ),

                // 2) Subtítulos com line-height menor
                Text(
                  'Prazo: $deadlineWeeks ${deadlineWeeks == 1 ? 'semana' : 'semanas'}',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 12 * scale,
                    height: 1.0, // <— controla o espaçamento entre as linhas
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  'Tempo decorrido: $elapsedWeeks ${elapsedWeeks == 1 ? 'semana' : 'semanas'}',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 12 * scale,
                    height: 1.0, // <— menos espaço entre subtítulos
                    color: AppColors.darkText,
                  ),
                ),

                SizedBox(height: 2 * scale),

                // Indicador + contador de unidades concluídas
                Row(
                  children: [
                    SizedBox(
                      width:
                          210 *
                          scale, // ajuste esse valor até ficar do tamanho desejado
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
