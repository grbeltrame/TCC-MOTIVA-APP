import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';

/// Tema principal do aplicativo Motiva.
class AppTheme {
  /// Tema claro (light) utilizado como base para todo o app.
  static ThemeData get lightTheme {
    return ThemeData(
      // Fonte padrão para todo o app
      fontFamily: AppFonts.roboto,

      // Configuração global de TextTheme
      textTheme: TextTheme(
        // Título principal da tela de login (MONTIV A 30px)
        headlineLarge: const TextStyle(
          fontFamily: AppFonts.montserrat,
          fontWeight: AppFontWeight.bold,
          fontSize: 30,
          color: AppColors.darkText,
        ),
        // Label dos inputs (12px, Roboto Light)
        titleMedium: const TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.light,
          fontSize: 12,
          color: AppColors.darkText,
        ),
        // Placeholder dos inputs (14px, Roboto Regular)
        bodyMedium: const TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.regular,
          fontSize: 14,
          color: AppColors.mediumGray,
        ),
        // Botões de texto como "Esqueci minha senha" (14px, Roboto Bold)
        labelLarge: const TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.bold,
          fontSize: 14,
          color: AppColors.darkBlue,
        ),
        // Botão Entrar (16px, Montserrat Bold)
        titleLarge: const TextStyle(
          fontFamily: AppFonts.montserrat,
          fontWeight: AppFontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
        // Texto de LGPD (8px, Roboto Light)
        bodySmall: const TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.light,
          fontSize: 8,
          color: AppColors.darkText,
        ),
      ),

      // Paleta de cores
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkBlue,
        background: AppColors.offWhite,
      ),

      // Cor de fundo do Scaffold
      scaffoldBackgroundColor: AppColors.offWhite,
    );
  }
}
