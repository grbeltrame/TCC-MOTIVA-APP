// lib/shared/widgets/championships/upcoming_champ_list_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/models/championship.dart';

class UpcomingChampListItem extends StatelessWidget {
  const UpcomingChampListItem({
    super.key,
    required this.champ,
    required this.onTapRegister,
    required this.onTapDelete,
  });

  final Championship champ;
  final VoidCallback onTapRegister;
  final VoidCallback onTapDelete;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final fmt = DateFormat('dd/MM/yyyy');

    final String dateText =
        (champ.startDate.year == champ.endDate.year &&
                champ.startDate.month == champ.endDate.month &&
                champ.startDate.day == champ.endDate.day)
            ? fmt.format(champ.startDate)
            : '${fmt.format(champ.startDate)}–${fmt.format(champ.endDate)}';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ESQUERDA: título + "+" colado + data abaixo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título e "+" NA MESMA LINHA, COLADOS
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        champ.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 14 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    SizedBox(width: 6 * scale),
                    // Ícone de "+" simples, sem círculo
                    IconButton(
                      onPressed: onTapRegister,
                      icon: Icon(Icons.add, color: AppColors.baseBlue),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 18 * scale,
                      tooltip: 'Registrar resultado',
                    ),
                  ],
                ),
                SizedBox(height: 2 * scale),
                Text(
                  dateText,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.medium,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),

          // DIREITA: Lixeira vermelha (simples, sem círculo)
          IconButton(
            onPressed: onTapDelete,
            icon: const Icon(Icons.delete_outline),
            color: Colors.red,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 20 * scale,
            tooltip: 'Excluir campeonato',
          ),
        ],
      ),
    );
  }
}
