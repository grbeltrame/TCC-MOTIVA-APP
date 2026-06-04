// lib/shared/widgets/icon_text_action_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Botão de texto com ícone (Material ou SVG) à esquerda e fonte configurável.
/// Mantém a mesma estética do TextActionButton.
class IconTextActionButton extends StatelessWidget {
  /// Texto do botão.
  final String text;

  /// Callback ao pressionar.
  final VoidCallback onPressed;

  /// Ícone nativo do Material (ex: Icons.add).
  final IconData? iconData;

  /// Caminho do asset SVG (ex: 'assets/icons/rewards_ads.svg').
  final String? svgAsset;

  /// Cor do texto e do ícone.
  final Color color;

  /// Tamanho da fonte em pontos (padrão: 14 * scale).
  final double? fontSize;

  const IconTextActionButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.iconData,
    this.svgAsset,
    this.color = AppColors.baseBlue,
    this.fontSize,
  }) : assert(
         iconData != null || svgAsset != null,
         'Forneça ou iconData ou svgAsset.',
       ),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final txtSize = fontSize ?? 14 * scale;
    final iconSize = txtSize + 4 * scale;

    Widget iconWidget;
    if (svgAsset != null) {
      iconWidget = SvgPicture.asset(
        svgAsset!,
        width: iconSize,
        height: iconSize,
        color: color,
      );
    } else {
      iconWidget = Icon(iconData, size: iconSize, color: color);
    }

    return TextButton.icon(
      onPressed: onPressed,
      icon: iconWidget,
      label: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.bold,
          fontSize: txtSize,
          color: color,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: 2 * scale,
          vertical: 4 * scale,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
