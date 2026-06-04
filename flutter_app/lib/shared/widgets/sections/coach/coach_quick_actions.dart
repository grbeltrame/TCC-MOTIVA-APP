// lib/shared/widgets/sections/coach/coach_quick_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';

// O botão "Treino do Dia" foi removido daqui pois já existe o botão
// "Ver treino" dentro do CoachTodayWorkoutCard, evitando duplicidade.
// Se _showAnalysis for true, o botão de Análise do Box ocupa 100% da largura.

class CoachQuickActions extends StatelessWidget {
  const CoachQuickActions({super.key});

  static const bool _showAnalysis = false;

  @override
  Widget build(BuildContext context) {
    if (!_showAnalysis) return const SizedBox.shrink();

    final scale = MediaQuery.of(context).size.width / 375.0;
    final double height = 46 * scale;
    final double radius = 12 * scale;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: 12 * scale,
      vertical: 0,
    );

    return OutlinedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.coachEvolutions);
      },
      icon: Icon(
        Icons.bar_chart_rounded,
        size: 18 * scale,
        color: AppColors.baseBlue,
      ),
      label: Text(
        'Análise do Box',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.medium,
          fontSize: 16 * scale,
          color: AppColors.baseBlue,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, height),
        padding: padding,
        side: BorderSide(color: AppColors.baseBlue, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}
