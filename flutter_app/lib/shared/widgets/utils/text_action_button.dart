// lib/shared/widgets/text_action_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Botão de texto com estilo consistente, opcionalmente acompanhado de ícone.
///
/// Exemplo de uso:
/// TextActionButton(
///   text: 'Esqueci minha senha',
///   icon: Icons.help_outline,
///   onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
/// )
class TextActionButton extends StatelessWidget {
  /// Texto a ser exibido no botão.
  final String text;

  /// Callback disparado ao pressionar.
  final VoidCallback onPressed;

  /// Ícone opcional exibido à esquerda do texto.
  final IconData? icon;

  /// Cor do texto e do ícone.
  final Color color;

  final double? fontSize;
  const TextActionButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.fontSize,
    this.color = AppColors.baseBlue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final fs = (fontSize ?? 12) * scale; // default menor (12)
    final textWidget = Text(
      text,
      style: TextStyle(
        fontFamily: AppFonts.roboto,
        fontWeight: AppFontWeight.bold,
        fontSize: fs,
        color: color,
      ),
    );

    // Se houver ícone, usa TextButton.icon, senão TextButton simples
    if (icon != null) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18 * scale, color: color),
        label: textWidget,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      child: textWidget,
    );
  }
}
