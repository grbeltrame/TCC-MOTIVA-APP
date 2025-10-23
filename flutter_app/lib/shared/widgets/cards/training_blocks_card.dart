// lib/shared/widgets/cards/training_blocks_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/models/training_block.dart';

/// Card que lista, na ordem, todos os [TrainingBlock] do treino.
/// Por padrão, no rodapé exibe o botão “Registrar Resultado”.
/// Se [footer] for passado, ele substitui o rodapé padrão.
class TrainingBlocksCard extends StatelessWidget {
  const TrainingBlocksCard({
    Key? key,
    required this.blocks,
    required this.onTapRegisterResult,
    this.footer, // << novo
  }) : super(key: key);

  final List<TrainingBlock> blocks;
  final VoidCallback onTapRegisterResult;

  /// Rodapé customizado (opcional). Se informado, substitui o CTA padrão.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // conteúdo
          Padding(
            padding: EdgeInsets.fromLTRB(12 * scale, 12 * scale, 12 * scale, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < blocks.length; i++) ...[
                  if (i > 0) SizedBox(height: 12 * scale),
                  _Block(block: blocks[i]),
                ],
                SizedBox(height: 12 * scale),
              ],
            ),
          ),

          // divisor top do rodapé
          Container(height: 1, color: AppColors.lightGray),

          // rodapé
          footer ??
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 6 * scale,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onTapRegisterResult,
                    icon: Icon(
                      Icons.emoji_events_outlined,
                      size: 16 * scale,
                      color: AppColors.baseBlue,
                    ),
                    label: Text(
                      'Registrar Resultado',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 13 * scale,
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
              ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.block});
  final TrainingBlock block;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // título
        Text(
          block.title,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.bold,
            fontSize: 18 * scale,
            color: AppColors.darkText,
          ),
        ),
        if (block.subtitle.isNotEmpty) ...[
          SizedBox(height: 6 * scale),
          Text(
            block.subtitle,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
        ],
        if (block.items.isNotEmpty) SizedBox(height: 8 * scale),
        ...block.items.map(
          (line) => Padding(
            padding: EdgeInsets.only(bottom: 4 * scale),
            child: Text(
              line,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
