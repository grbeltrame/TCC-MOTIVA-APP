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

      // Paleta de cores
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkBlue,
        background: AppColors.offWhite,
        primary: AppColors.darkBlue,
        onPrimary: Colors.white,
        secondary: AppColors.baseBlue,
      ),

      // Cor de fundo global
      scaffoldBackgroundColor: AppColors.offWhite,

      // ======================
      // TextTheme global
      // ======================
      textTheme: TextTheme(
        headlineLarge: const TextStyle(
          // títulos grandes
          fontFamily: AppFonts.montserrat,
          fontWeight: AppFontWeight.bold,
          fontSize: 30,
          color: AppColors.darkText,
        ),
        titleMedium: const TextStyle(
          // labels de input
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.light,
          fontSize: 12,
          color: AppColors.darkText,
        ),
        bodyMedium: const TextStyle(
          // placeholder de input
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.regular,
          fontSize: 14,
          color: AppColors.mediumGray,
        ),
        labelLarge: const TextStyle(
          // botões de texto
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.bold,
          fontSize: 14,
          color: AppColors.darkBlue,
        ),
        titleLarge: const TextStyle(
          // texto interno de ElevatedButton
          fontFamily: AppFonts.montserrat,
          fontWeight: AppFontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
        bodySmall: const TextStyle(
          // textos pequenos (LGPD)
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.light,
          fontSize: 8,
          color: AppColors.darkText,
        ),
      ),

      // ======================
      // AppBar padrão
      // ======================
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.offWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.montserrat,
          fontWeight: AppFontWeight.bold,
          fontSize: 18,
          color: AppColors.darkText,
        ),
      ),

      // ======================
      // ElevatedButton padrão
      // ======================
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),

      // ======================
      // TextButton padrão
      // ======================
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkBlue,
          textStyle: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),

      // ======================
      // InputDecoration padrão
      // ======================
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.mediumGray),
        ),
        errorStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.regular,
          fontSize: 12,
          color: Colors.red,
        ),
      ),

      // ======================
      // Dialogs
      // ======================
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.montserrat,
          fontWeight: AppFontWeight.bold,
          fontSize: 20,
          color: AppColors.darkText,
        ),
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.regular,
          fontSize: 14,
          color: AppColors.darkText,
        ),
      ),

      // ======================
      // SnackBar
      // ======================
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkBlue,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.regular,
          fontSize: 14,
          color: Colors.white,
        ),
      ),

      // ======================
      // PopupMenu
      // ======================
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        textStyle: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.regular,
          fontSize: 14,
          color: AppColors.darkText,
        ),
      ),

      // ======================
      // BottomSheet
      // ======================
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.offWhite,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // ======================
      // Checkboxes e Radios
      // ======================
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.all(AppColors.darkBlue),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.all(AppColors.darkBlue),
      ),
    );
  }
}
