// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Todas as cores utilizadas globalmente no app.
class AppColors {
  static const Color darkBlue = Color(0xFF092580); //azul escuro
  static const Color darkText = Color(0xFF212121); //textos
  static const Color mediumGray = Color(0xFFA1A1A1); //detalhes
  static const Color offWhite = Color(0xFFF3F3F3); //fundo
  static const Color baseBlue = Color(0xFF0E3ACC); //azul base

  /// Gradiente de elipse (da parte superior até o final):
  static const Color gradientStart = Color.fromRGBO(238, 42, 96, 0.84);
  static const Color gradientMid = Color.fromRGBO(204, 14, 67, 0.84);
  static const Color gradientEnd = Color.fromRGBO(153, 0, 44, 0.84);

  /// Sombra da elipse
  static const Color shadowPink = Color.fromRGBO(238, 42, 96, 0.5);
}

/// Se você quiser já criar o LinearGradient como constante:
class AppGradients {
  static const LinearGradient ellipseGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.gradientStart,
      AppColors.gradientMid,
      AppColors.gradientEnd,
    ],
  );
}
