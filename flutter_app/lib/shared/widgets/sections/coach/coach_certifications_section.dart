// lib/features/user/coach/edit_profile/widgets/certifications_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class CertificationsSection extends StatelessWidget {
  const CertificationsSection({
    super.key,
    required this.scale,
    required this.selected,
    required this.allItems,
    required this.onToggle,
    required this.onAddNew,
  });

  final double scale;
  final List<String> selected;
  final List<String> allItems;
  final void Function(String item, bool checked) onToggle;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    final selectedSet = selected.toSet();
    final items = [...allItems]..sort();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Certificações',
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
          ...items.map((c) {
            final checked = selectedSet.contains(c);
            return CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: checked,
              onChanged: (v) => onToggle(c, v ?? false),
              title: Text(
                c,
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
  }
}
