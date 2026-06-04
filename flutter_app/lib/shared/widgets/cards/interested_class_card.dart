import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class InterestedClassCard extends StatelessWidget {
  const InterestedClassCard({
    super.key,
    required this.timeLabel,
    required this.category,
    required this.coachName,
    required this.onChangeTime,
    required this.onRegisterResult,
    required this.onRateCoach,
  });

  final String timeLabel;
  final String category;
  final String coachName;
  final VoidCallback onChangeTime;
  final VoidCallback onRegisterResult;
  final VoidCallback onRateCoach;

  Color _chipColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'wod':
        return AppColors.baseBlue;
      case 'lpo':
        return AppColors.baseMagenta;
      case 'ginastica':
        return AppColors.darkBlue;
      case 'endurance':
        return AppColors.lightBlue;
      default:
        return AppColors.mediumGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final catColor = _chipColor(category);

    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // título
          Text(
            'Você demonstrou interesse nesta aula:',
            style: TextStyle(
              fontFamily: AppFonts.montserrat,
              fontWeight: AppFontWeight.bold,
              fontSize: 16 * scale,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 8 * scale),

          // linha de info
          Row(
            children: [
              // horário
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 2 * scale,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8 * scale),
                  border: Border.all(color: AppColors.mediumGray),
                ),
                child: Text(
                  timeLabel,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 12 * scale,
                  ),
                ),
              ),
              SizedBox(width: 8 * scale),
              // categoria chip
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 2 * scale,
                ),
                decoration: BoxDecoration(
                  color: catColor.withOpacity(.1),
                  borderRadius: BorderRadius.circular(8 * scale),
                  border: Border.all(color: catColor),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 11 * scale,
                    color: catColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * scale),
          Text(
            'Professor: $coachName',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 13 * scale,
              color: AppColors.darkText,
            ),
          ),

          SizedBox(height: 10 * scale),
          const Divider(height: 24),

          // botões
          Wrap(
            spacing: 8 * scale,
            runSpacing: 8 * scale,
            children: [
              OutlinedButton(
                onPressed: onChangeTime,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.mediumGray),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 8 * scale,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Trocar horário'),
              ),
              ElevatedButton(
                onPressed: onRegisterResult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.baseBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 8 * scale,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Registrar resultado'),
              ),
              OutlinedButton(
                onPressed: onRateCoach,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.baseMagenta),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 8 * scale,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Avaliar professor',
                  style: TextStyle(color: AppColors.baseMagenta),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
