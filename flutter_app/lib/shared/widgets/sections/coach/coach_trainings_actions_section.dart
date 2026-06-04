import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_training_bottom_sheet.dart';

class CoachTrainingActionsSection extends StatelessWidget {
  const CoachTrainingActionsSection({Key? key}) : super(key: key);

  void _openRegisterTraining(BuildContext context) {
    showRegisterTrainingBottomSheet(context);
  }

  void _goToRegisteredTrainings(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.coachRegisteredTrainings);
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Botão "Cadastrar Treino" — borda azul, fundo azul translúcido, ícone de +
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: OutlinedButton.icon(
            onPressed: () => _openRegisterTraining(context),
            icon: Icon(Icons.add, size: 16 * scale, color: AppColors.baseBlue),
            label: Text(
              'Cadastrar Treino',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 13 * scale,
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                color: AppColors.baseBlue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.baseBlue, width: 1.2),
              backgroundColor: AppColors.baseBlue.withAlpha(40),
              padding: padding,
              minimumSize: Size(0, height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),

        SizedBox(width: 8 * scale),

        // Botão "Editar treinos" — borda azul, fundo branco, ícone de lápis
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: OutlinedButton.icon(
            onPressed: () => _goToRegisteredTrainings(context),
            icon: Icon(Icons.edit, size: 16 * scale, color: AppColors.baseBlue),
            label: Text(
              'Editar treinos',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 13 * scale,
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                color: AppColors.baseBlue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.baseBlue, width: 1.2),
              backgroundColor: Colors.white,
              padding: padding,
              minimumSize: Size(0, height),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }
}
