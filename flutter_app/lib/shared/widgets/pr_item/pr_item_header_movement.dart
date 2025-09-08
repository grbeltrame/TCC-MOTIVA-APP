import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class PrItemHeaderMovement extends StatelessWidget {
  const PrItemHeaderMovement({
    super.key,
    required this.movementName,
    required this.description,
    required this.onRegister,
  });

  final String movementName;
  final String description;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            movementName,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 16 * scale,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            description,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          SizedBox(height: 12 * scale),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRegister,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Registrar resultado'),
              style: TextButton.styleFrom(foregroundColor: AppColors.baseBlue),
            ),
          ),
        ],
      ),
    );
  }
}
