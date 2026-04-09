// lib/shared/widgets/cards/week_prs_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart';
import 'package:flutter_app/shared/widgets/carousels/text_carousel.dart';
import 'package:flutter_app/shared/widgets/register_pr/register_pr_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';

/// Card de PRs batidos na semana com botão "Registrar PR".
class WeekPRsCard extends StatefulWidget {
  const WeekPRsCard({Key? key}) : super(key: key);

  @override
  State<WeekPRsCard> createState() => _WeekPRsCardState();
}

class _WeekPRsCardState extends State<WeekPRsCard> {
  final _service = WeeklySummaryService();
  late Future<List<PRModel>> _prsFut;

  @override
  void initState() {
    super.initState();
    _prsFut = _service.fetchPRs();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          14 * scale,
          16 * scale,
          16 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + botão Registrar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PRs BATIDOS',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 11 * scale,
                    color: AppColors.darkBlue,
                    letterSpacing: 0.8,
                  ),
                ),
                Transform.scale(
                  scale: 0.85,
                  alignment: Alignment.centerRight,
                  child: TextActionButton(
                    icon: Icons.add,
                    text: 'Registrar PR',
                    onPressed: () async {
                      await showRegisterPrBottomSheet(context);
                      if (!mounted) return;
                      setState(() {
                        _prsFut = _service.fetchPRs();
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 10 * scale),

            // Lista de PRs ou estado vazio
            FutureBuilder<List<PRModel>>(
              future: _prsFut,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 20,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final prs = snap.data ?? [];
                if (prs.isEmpty) {
                  return Text(
                    'Nenhum PR registrado esta semana.',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 13 * scale,
                      color: AppColors.mediumGray,
                    ),
                  );
                }
                return TextCarousel(
                  items: prs.map((p) => p.label).toList(),
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.normal,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
