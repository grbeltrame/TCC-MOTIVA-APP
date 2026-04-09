// lib/shared/widgets/cards/week_stimuli_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';

/// Card de estímulos da semana — chips com contagem, ordenados do maior.
class WeekStimuliCard extends StatelessWidget {
  final AthleteStatsSummary summary;

  const WeekStimuliCard({Key? key, required this.summary}) : super(key: key);

  static const _chipColors = [
    AppColors.baseBlue,
    AppColors.baseMagenta,
    AppColors.darkBlue,
    AppColors.lightBlue,
    AppColors.darkMagenta,
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final stimuli = summary.stimuliSorted;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16 * scale, 14 * scale, 16 * scale, 16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'ESTÍMULOS DA SEMANA',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 11 * scale,
                color: AppColors.darkBlue,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 12 * scale),

            if (stimuli.isEmpty)
              Text(
                'Nenhum estímulo registrado esta semana.',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 13 * scale,
                  color: AppColors.mediumGray,
                ),
              )
            else
              Wrap(
                spacing: 8 * scale,
                runSpacing: 8 * scale,
                children: stimuli.asMap().entries.map((entry) {
                  final color = _chipColors[entry.key % _chipColors.length];
                  return _StimulusChip(
                    label: entry.value.key,
                    count: entry.value.value,
                    color: color,
                    scale: scale,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip individual
// ─────────────────────────────────────────────────────────────────────────────

class _StimulusChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final double scale;

  const _StimulusChip({
    required this.label,
    required this.count,
    required this.color,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 6 * scale),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 5 * scale,
              vertical: 1 * scale,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            child: Text(
              '${count}x',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 10 * scale,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
