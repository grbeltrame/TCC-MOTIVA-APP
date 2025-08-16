import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class PrItemHeaderWod extends StatelessWidget {
  const PrItemHeaderWod({
    super.key,
    required this.wodName,
    required this.lines,
    required this.onRegister,
    required this.onSeeSimilarProfiles,
  });

  final String wodName;
  final List<String> lines;
  final VoidCallback onRegister;
  final VoidCallback onSeeSimilarProfiles;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'WOD “$wodName”',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 16 * scale,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 6 * scale),
          ...lines.map(
            (line) => Padding(
              padding: EdgeInsets.only(bottom: 2 * scale),
              child: Text(
                line,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 12 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ),
          ),
          SizedBox(height: 16 * scale),

          // linha 1 — apenas 1 botão
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onSeeSimilarProfiles,
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Resultados de perfis semelhantes ao seu'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.baseBlue,
                ),
              ),
            ],
          ),

          Divider(color: AppColors.lightGray),

          // linha 2 — registrar resultado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Registrar resultado'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.baseBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
