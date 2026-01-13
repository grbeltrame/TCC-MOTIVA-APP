// lib/features/user/coach/edit_profile/widgets/specialties_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class SpecialtiesSection extends StatelessWidget {
  const SpecialtiesSection({
    super.key,
    required this.scale,
    required this.categories,
    required this.selected,
    required this.onToggle,
    required this.onAddNew,
  });

  final double scale;
  final Map<String, List<String>> categories;
  final List<String> selected;
  final void Function(String item, bool checked) onToggle;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final selectedSet = selected.toSet();

    final catKeys = categories.keys.toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Especialidades',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 16 * scale,
                  color: AppColors.darkText,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAddNew,
                icon: Icon(
                  Icons.add,
                  size: 18 * scale,
                  color: AppColors.baseBlue,
                ),
                label: Text(
                  'Adicionar nova',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 12 * scale,
                    color: AppColors.baseBlue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * scale),
          ...catKeys.map((cat) {
            final items = [...(categories[cat] ?? <String>[])]..sort();

            return Padding(
              padding: EdgeInsets.only(bottom: 10 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 13 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  ...items.map((s) {
                    final checked = selectedSet.contains(s);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: checked,
                      onChanged: (v) => onToggle(s, v ?? false),
                      title: Text(
                        s,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 13 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.baseBlue,
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
