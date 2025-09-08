import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/models/coach.dart';

class CoachSummaryCard extends StatelessWidget {
  const CoachSummaryCard({super.key, required this.summary});
  final CoachProfileSummary summary;

  Color get _chipBg => AppColors.baseBlue.withAlpha(50);
  Color get _chipText => AppColors.darkBlue;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // topo: avatar + nome + CREF
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Avatar(
                photoUrl: summary.photoUrl,
                name: summary.name,
                size: 46 * scale,
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.name,
                      style: TextStyle(
                        fontFamily: AppFonts.montserrat,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 18 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                    SizedBox(height: 6 * scale),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8 * scale,
                            vertical: 4 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: _chipBg,
                            borderRadius: BorderRadius.circular(10 * scale),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_outline,
                                size: 16 * scale,
                                color: _chipText,
                              ),
                              SizedBox(width: 4 * scale),
                              Text(
                                'CREF:',
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: 12 * scale,
                                  color: _chipText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6 * scale),
                        Text(
                          summary.cref,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.medium,
                            fontSize: 13 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 10 * scale),

          // duas colunas: especialidades | certificações
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledListChip(
                  label: 'Especialidades:',
                  icon: Icons.search_rounded,
                  items: summary.specialties,
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _LabeledListChip(
                  label: 'Certificações:',
                  icon: Icons.workspace_premium_rounded,
                  items: summary.certifications,
                ),
              ),
            ],
          ),

          SizedBox(height: 10 * scale),

          // rodapé: 2 "botões" informativos
          Row(
            children: [
              Expanded(
                child: _InfoCounterPill(
                  title: 'Treinos aplicados',
                  value: summary.appliedTrainingsCount,
                  icon: Icons.groups_rounded,
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _InfoCounterPill(
                  title: 'Treinos cadastrados',
                  value: summary.createdTrainingsCount,
                  icon: Icons.assignment_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.photoUrl,
    required this.name,
    required this.size,
  });
  final String? photoUrl;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        color: AppColors.lightBlue.withAlpha(80),
        child:
            photoUrl == null
                ? Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight: AppFontWeight.bold,
                      fontSize: size * .45,
                      color: AppColors.baseBlue,
                    ),
                  ),
                )
                : Image.network(photoUrl!, fit: BoxFit.cover),
      ),
    );
  }
}

class _LabeledListChip extends StatelessWidget {
  const _LabeledListChip({
    required this.label,
    required this.icon,
    required this.items,
  });

  final String label;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final chipBg = AppColors.baseBlue.withAlpha(50);
    final chipText = AppColors.darkBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * scale,
            vertical: 3 * scale,
          ),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(10 * scale),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14 * scale, color: chipText),
              SizedBox(width: 4 * scale),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 11 * scale,
                  color: chipText,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6 * scale),
        for (final t in items)
          Padding(
            padding: EdgeInsets.only(bottom: 2 * scale),
            child: Text(
              t,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoCounterPill extends StatelessWidget {
  const _InfoCounterPill({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 10 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.baseBlue.withAlpha(50),
        border: Border.all(color: AppColors.baseBlue),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1ª linha: ícone + título centralizados
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16 * scale, color: AppColors.darkText),
                SizedBox(width: 4 * scale),
                // sem Expanded — senão “puxa” pra esquerda
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 12 * scale,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6 * scale),

          // 2ª linha: informação
          Text(
            '$value treinos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.regular,
              fontSize: 14 * scale,
              color: AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
