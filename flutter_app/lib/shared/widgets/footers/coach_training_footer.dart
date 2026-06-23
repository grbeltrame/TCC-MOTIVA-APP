// lib/shared/widgets/footers/coach_training_footer.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class CoachTrainingFooter extends StatelessWidget {
  const CoachTrainingFooter({
    Key? key,
    required this.onTapVerResultados,
    required this.onTapComentariosDoCriador,
    required this.onTapRegistrarResultado,
  }) : super(key: key);

  final VoidCallback onTapVerResultados;
  final VoidCallback onTapComentariosDoCriador;
  final VoidCallback onTapRegistrarResultado;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 8 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Linha 1: dois botões
          Row(
            children: [
              // Expanded(
              //   child: TextButton.icon(
              //     onPressed: onTapVerResultados, // TODO
              //     icon: Icon(
              //       Icons.groups_outlined,
              //       size: 14 * scale,
              //       color: AppColors.baseBlue,
              //     ),
              //     label: Text(
              //       'Resultados dos alunos',
              //       maxLines: 1,
              //       overflow: TextOverflow.ellipsis,
              //       style: TextStyle(
              //         fontFamily: AppFonts.roboto,
              //         fontWeight: AppFontWeight.bold,
              //         fontSize: 11 * scale,
              //         color: AppColors.baseBlue,
              //       ),
              //     ),
              //     style: TextButton.styleFrom(
              //       padding: EdgeInsets.symmetric(
              //         horizontal: 8 * scale,
              //         vertical: 4 * scale,
              //       ),
              //       minimumSize: const Size(0, 0),
              //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //     ),
              //   ),
              // ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: TextButton.icon(
                  onPressed: onTapComentariosDoCriador, // TODO
                  icon: Icon(
                    Icons.comment_outlined,
                    size: 14 * scale,
                    color: AppColors.baseBlue,
                  ),
                  label: Text(
                    'Comentários do criador',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 11 * scale,
                      color: AppColors.baseBlue,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * scale,
                      vertical: 4 * scale,
                    ),
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8 * scale),
          Container(height: 1, color: AppColors.lightGray),
          SizedBox(height: 6 * scale),

          // Linha 2: Registrar resultado (alinhado à direita)
          // Align(
          //   alignment: Alignment.centerRight,
          //   child: TextButton.icon(
          //     onPressed: onTapRegistrarResultado, // TODO
          //     icon: Icon(
          //       Icons.emoji_events_outlined,
          //       size: 16 * scale,
          //       color: AppColors.baseBlue,
          //     ),
          //     label: Text(
          //       'Registrar Resultado',
          //       style: TextStyle(
          //         fontFamily: AppFonts.roboto,
          //         fontWeight: AppFontWeight.bold,
          //         fontSize: 13 * scale,
          //         color: AppColors.baseBlue,
          //       ),
          //     ),
          //     style: TextButton.styleFrom(
          //       padding: EdgeInsets.symmetric(
          //         horizontal: 8 * scale,
          //         vertical: 4 * scale,
          //       ),
          //       minimumSize: const Size(0, 0),
          //       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
