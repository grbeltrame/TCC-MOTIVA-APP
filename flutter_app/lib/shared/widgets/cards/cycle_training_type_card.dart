import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class CycleTrainingTypeCard extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const CycleTrainingTypeCard({
    super.key,
    required this.label,
    required this.count,
    required this.onTap,
  });

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
          color: AppColors.baseBlue.withAlpha(40),
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(color: AppColors.baseBlue, width: 1.2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label (${count.toString()})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 14 * scale,
                  color: AppColors.darkText,
                ),
              ),
            ),
            InkWell(
              onTap: onTap,
              child: Icon(
                Icons.add,
                size: 18 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
