import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Dropdown “sem seta”, com underline escondido e borda leve.
class PlainDropdown<T> extends StatelessWidget {
  const PlainDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // evita assert quando 'value' não está entre os items
    final values = items.map((e) => e.value).toList();
    final T? safeValue = values.contains(value) ? value : null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: AppColors.mediumGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: safeValue,
          isDense: true,
          isExpanded: false,
          icon: const SizedBox.shrink(), // sem seta
          hint:
              hintText != null
                  ? Text(
                    hintText!,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 14 * scale,
                      color: AppColors.mediumGray,
                    ),
                  )
                  : null,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
