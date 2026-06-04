import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/models/championship.dart';

class ConcludedChampListItem extends StatelessWidget {
  const ConcludedChampListItem({
    super.key,
    required this.champ,
    required this.onTapRegister,
  });

  final Championship champ;
  final VoidCallback onTapRegister;

  bool get _isPast => DateTime.now().isAfter(
    DateTime(
      champ.endDate.year,
      champ.endDate.month,
      champ.endDate.day,
      23,
      59,
      59,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    // lado direito: ranking se existir; se não e já passou, botão Registrar
    Widget right;
    if (champ.userRanking != null) {
      right = _RankingPill(
        rank: champ.userRanking!,
        total: champ.totalParticipants,
      );
    } else if (_isPast) {
      right = TextButton(
        onPressed: onTapRegister,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Registrar resultado',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.medium,
                fontSize: 12 * scale,
                color: AppColors.baseBlue,
              ),
            ),
            SizedBox(width: 4 * scale),
            Icon(Icons.edit, size: 16 * scale, color: AppColors.baseBlue),
          ],
        ),
      );
    } else {
      right = const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 10 * scale,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _TitleAndDate(name: champ.name, date: champ.endDate)),
          right,
        ],
      ),
    );
  }
}

class _TitleAndDate extends StatelessWidget {
  const _TitleAndDate({required this.name, required this.date});
  final String name;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final fmt = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.bold,
            fontSize: 14 * scale,
            color: AppColors.darkText,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          fmt.format(date),
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.medium,
            fontSize: 11 * scale,
            color: AppColors.mediumGray,
          ),
        ),
      ],
    );
  }
}

class _RankingPill extends StatelessWidget {
  const _RankingPill({required this.rank, this.total});
  final int rank;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final text = total != null ? 'Ranking $rank/$total' : '$rankº';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.baseBlue),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.medium,
          fontSize: 12 * scale,
          color: AppColors.darkText,
        ),
      ),
    );
  }
}
