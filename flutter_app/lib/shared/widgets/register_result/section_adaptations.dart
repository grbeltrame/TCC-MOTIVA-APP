import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/register_result/movements.dart';

class SectionAdaptations extends StatelessWidget {
  const SectionAdaptations({
    super.key,
    required this.visible,
    required this.movementRows,
    required this.inputDecorationBuilder,
  });

  final bool visible;
  final List<MovementRowData> movementRows;
  final InputDecoration Function(
    BuildContext context, {
    String? suffixText,
    String? hintText,
  })
  inputDecorationBuilder;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    if (!visible) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adaptações',
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
            fontSize: 16 * scale,
            color: AppColors.darkText,
          ),
        ),
        SizedBox(height: 6 * scale),
        Text(
          'Informe a quantidade, tempo (em segundos), e/ou movimento que adaptou.',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.regular,
            fontSize: 12 * scale,
            color: AppColors.mediumGray,
          ),
        ),
        SizedBox(height: 10 * scale),

        ...movementRows.map(
          (row) => Padding(
            padding: EdgeInsets.only(bottom: 8 * scale),
            child: MovementRow(
              data: row,
              inputDecorationBuilder: inputDecorationBuilder,
            ),
          ),
        ),
      ],
    );
  }
}
