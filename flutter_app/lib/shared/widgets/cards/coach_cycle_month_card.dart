import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class CycleMonthCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const CycleMonthCard({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8 * scale),
      child: Container(
        height: 44 * scale,
        padding: EdgeInsets.symmetric(horizontal: 12 * scale),
        decoration: BoxDecoration(
          color: AppColors.baseBlue.withAlpha(50),
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(color: AppColors.darkBlue, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 16 * scale,
                  color: AppColors.darkText,
                ),
              ),
            ),
            InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: EdgeInsets.all(6 * scale),
                child: Icon(
                  Icons.add,
                  color: AppColors.darkText,
                  size: 18 * scale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
