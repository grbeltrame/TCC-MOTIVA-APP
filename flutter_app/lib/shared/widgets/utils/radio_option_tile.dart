// lib/shared/widgets/radio_option_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Widget de opção de seleção com rádio e texto.
/// Use para apresentar um grupo de opções mutuamente exclusivas.
class RadioOptionTile<T> extends StatelessWidget {
  /// Valor desta opção.
  final T value;

  /// Valor atualmente selecionado no grupo.
  final T? groupValue;

  /// Rótulo de texto para exibir ao lado do rádio.
  final String label;

  /// Callback disparado ao selecionar esta opção.
  final ValueChanged<T?> onChanged;

  const RadioOptionTile({
    Key? key,
    required this.value,
    required this.groupValue,
    required this.label,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return InkWell(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<T>(
            value: value,
            groupValue: groupValue,
            activeColor: AppColors.darkBlue,
            onChanged: onChanged,
            // compactar ainda mais o botão de rádio
            visualDensity: const VisualDensity(horizontal: -4, vertical: -1),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          SizedBox(width: 4 * scale),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.regular,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
