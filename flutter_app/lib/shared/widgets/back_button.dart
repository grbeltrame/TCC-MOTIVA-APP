// lib/shared/widgets/back_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Botão de voltar padrão, com ícone e texto "Voltar" estilizado.
/// Sempre faz Navigator.pop() por padrão.
class AppBackButton extends StatelessWidget {
  /// Altura do ícone e tamanho da fonte escalam conforme a largura da tela.
  const AppBackButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return TextButton.icon(
      onPressed: () => Navigator.pop(context),
      icon: Icon(
        Icons.navigate_before,
        size: 20 * scale,
        color: AppColors.darkBlue,
      ),
      label: Text(
        'Voltar',
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.medium,
          fontSize: 16 * scale,
          color: AppColors.darkBlue,
        ),
      ),
    );
  }
}
