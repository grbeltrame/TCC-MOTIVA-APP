// lib/shared/widgets/app_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Dialog estilizado para confirmações, alertas e etc.
/// Permite botões primário e secundário posicionados lado a lado e centralizados,
/// com cores e estilos de fonte customizáveis.
class AppDialog extends StatelessWidget {
  /// Ícone de topo do dialog.
  final IconData icon;

  /// Cor do ícone.
  final Color iconColor;

  /// Título principal do dialog.
  final String title;

  /// Mensagem de corpo do dialog.
  final String message;

  /// Botão secundário (opcional), exibido à esquerda.
  final Widget? secondaryAction;

  /// Botão primário, exibido à direita.
  final Widget primaryAction;

  const AppDialog({
    Key? key,
    required this.icon,
    this.iconColor = AppColors.darkBlue,
    required this.title,
    required this.message,
    this.secondaryAction,
    required this.primaryAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(horizontal: 40 * scale),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24 * scale,
          24 * scale,
          24 * scale,
          16 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de confirmação
            Icon(icon, size: 24 * scale, color: iconColor),
            SizedBox(height: 16 * scale),
            // Título
            Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 20 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 8 * scale),
            // Mensagem
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.regular,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 24 * scale),
            // Botões centrais: secundário e primário
            TextButtonTheme(
              data: TextButtonThemeData(
                style: TextButton.styleFrom(
                  textStyle: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 18 * scale,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (secondaryAction != null) ...[
                    secondaryAction!,
                    SizedBox(width: 16 * scale),
                  ],
                  primaryAction,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
