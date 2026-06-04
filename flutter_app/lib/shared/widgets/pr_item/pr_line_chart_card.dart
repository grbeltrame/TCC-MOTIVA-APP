import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class PrLineChartCard extends StatelessWidget {
  const PrLineChartCard({
    super.key,
    required this.title,
    required this.child,
    this.trailingDropdownDays,
    this.onChangedDays,
  });

  final String title;
  final Widget child;

  /// 7/30/90 ou null para esconder o dropdown
  final int? trailingDropdownDays;
  final ValueChanged<int>? onChangedDays;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 16 * scale,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              if (trailingDropdownDays != null && onChangedDays != null)
                DropdownButton<int>(
                  value: trailingDropdownDays,
                  underline: const SizedBox.shrink(),
                  iconEnabledColor: AppColors.darkText,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    color: AppColors.darkText,
                    fontWeight: FontWeight.bold,
                  ),
                  items: const [
                    DropdownMenuItem(value: 7, child: Text('7 dias')),
                    DropdownMenuItem(value: 30, child: Text('30 dias')),
                    DropdownMenuItem(value: 90, child: Text('90 dias')),
                  ],
                  onChanged: (v) {
                    if (v != null) onChangedDays!(v);
                  },
                ),
            ],
          ),
          SizedBox(height: 8 * scale),
          SizedBox(height: 220 * scale, child: child),
        ],
      ),
    );
  }
}
