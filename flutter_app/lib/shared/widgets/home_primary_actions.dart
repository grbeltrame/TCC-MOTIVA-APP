// lib/shared/widgets/home_primary_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class HomePrimaryActions extends StatelessWidget {
  final String trainingsRoute;
  final String evolutionRoute;

  const HomePrimaryActions({
    Key? key,
    this.trainingsRoute = AppRoutes.athleteTraining,
    this.evolutionRoute = AppRoutes.athleteEvolution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // ===== Botão primário: cheio azul =====
            Expanded(
              child: SizedBox(
                child: ElevatedButton.icon(
                  onPressed:
                      () => Navigator.of(context).pushNamed(trainingsRoute),
                  icon: SvgPicture.asset(
                    'assets/icons/run.svg',
                    width: 20 * scale,
                    height: 20 * scale,
                    color: AppColors.darkBlue,
                  ),
                  label: Text(
                    'Ver WOD',
                    style: TextStyle(
                      color: AppColors.darkBlue,
                      fontFamily: AppFonts.montserrat,
                      fontSize: 20 * scale,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * scale,
                      vertical: 12 * scale,
                    ),
                    backgroundColor: AppColors.baseBlue.withAlpha(70),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: AppColors.baseBlue,
                        width: 1 * scale,
                      ),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),

            SizedBox(width: 8),

            // ===== Botão secundário: contornado =====
            Expanded(
              child: SizedBox(
                child: OutlinedButton.icon(
                  onPressed:
                      () => Navigator.of(context).pushNamed(evolutionRoute),
                  icon: const Icon(Icons.bar_chart),
                  label: Text(
                    'Sua evolução',
                    style: TextStyle(
                      color: AppColors.darkBlue,
                      fontFamily: AppFonts.montserrat,
                      fontSize: 16 * scale,
                      fontWeight: AppFontWeight.regular,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * scale,
                      vertical: 12 * scale,
                    ),
                    side: BorderSide(
                      color: AppColors.baseBlue,
                      width: 1 * scale,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    foregroundColor: AppColors.baseBlue,
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Espaçamento para a próxima seção
        SizedBox(height: 16 * scale),
      ],
    );
  }
}
