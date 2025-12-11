// lib/shared/widgets/sections/coach/coach_quick_actions.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';

class CoachQuickActions extends StatelessWidget {
  const CoachQuickActions({super.key});

  // deixe true por enquanto para visualizar os dois
  static const bool _showAnalysis = false;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final double height = 46 * scale; // ↑ um pouco mais alto
    final double radius = 12 * scale;
    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: 12 * scale,
      vertical: 0,
    );

    Widget treinoBtn = OutlinedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.coachTrainings);
      },
      icon: Icon(
        Icons.calendar_month_rounded,
        size: 18 * scale,
        color: AppColors.darkBlue,
      ),
      label: Text(
        'Treino do Dia',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.bold,
          fontSize: 16 * scale,
          color: AppColors.darkBlue,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, height),
        padding: padding,
        backgroundColor: AppColors.baseBlue.withAlpha(48),
        side: BorderSide(color: AppColors.baseBlue, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );

    Widget analiseBtn = OutlinedButton.icon(
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
          fontWeight: AppFontWeight.medium, // mais fino
          fontSize: 16 * scale,
          color: AppColors.baseBlue,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, height),
        padding: padding,
        side: BorderSide(color: AppColors.baseBlue, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );

    // Com Expanded, cada botão ocupa 50% (ou 100% se só houver um)
    return Row(
      children: [
        Expanded(child: treinoBtn),
        if (_showAnalysis) ...[
          SizedBox(width: 12 * scale),
          Expanded(child: analiseBtn),
        ],
      ],
    );
  }
}
