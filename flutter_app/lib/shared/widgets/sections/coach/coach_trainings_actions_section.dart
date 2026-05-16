import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_box.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';

class CoachTrainingActionsSection extends StatelessWidget {
  const CoachTrainingActionsSection({Key? key, this.selectedDate})
    : super(key: key);

  /// Data selecionada na tela pai. Usada como data inicial ao criar
  /// um treino novo. Se null, usa a data atual.
  final DateTime? selectedDate;

  void _goToRegisteredTrainings(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.coachRegisteredTrainings);
  }

  void _goToCreateTraining(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.coachTrainingCreate,
      arguments: {
        'boxId': AppBox.id,
        'date': selectedDate ?? DateTime.now(),
        'category': 'WOD',
        'isCreating': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final double height = 40 * scale;
    final double radius = 8 * scale;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: 12 * scale,
      vertical: 8 * scale,
    );

    final outlineStyle = OutlinedButton.styleFrom(
      side: const BorderSide(color: AppColors.baseBlue, width: 1.2),
      backgroundColor: Colors.white,
      padding: padding,
      minimumSize: Size(0, height),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final labelStyle = TextStyle(
      fontSize: 13 * scale,
      fontFamily: AppFonts.roboto,
      fontWeight: AppFontWeight.bold,
      color: AppColors.baseBlue,
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _goToCreateTraining(context),
            icon: Icon(
              Icons.add_circle_outline,
              size: 16 * scale,
              color: AppColors.baseBlue,
            ),
            label: Text(
              'Criar treino',
              maxLines: 1,
              softWrap: false,
              style: labelStyle,
            ),
            style: outlineStyle,
          ),
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _goToRegisteredTrainings(context),
            icon: Icon(Icons.edit, size: 16 * scale, color: AppColors.baseBlue),
            label: Text(
              'Editar treinos',
              maxLines: 1,
              softWrap: false,
              style: labelStyle,
            ),
            style: outlineStyle,
          ),
        ),
      ],
    );
  }
}
