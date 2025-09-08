import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/users/profile_summary_service.dart';
import 'package:flutter_app/shared/widgets/utils/icon_text_action_button.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileSummarySection extends StatelessWidget {
  const ProfileSummarySection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ───────────────────── Linha dos dois mini-cards ─────────────────────
        FutureBuilder<ProfileSummaryCounts>(
          future: ProfileSummaryService.fetchCounts(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 76,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final counts = snap.data!;

            return Row(
              children: [
                Expanded(
                  child: _SummaryMiniCard(
                    icon: SvgPicture.asset(
                      'assets/icons/exercise.svg',
                      width: 18 * scale,
                      height: 18 * scale,
                      color: AppColors.darkBlue,
                    ),
                    title: 'PRs Registrados',
                    value: '${counts.totalPrs} PRs',
                  ),
                ),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: _SummaryMiniCard(
                    icon: Icon(
                      Icons.calendar_month_outlined,
                      size: 18 * scale,
                      color: AppColors.darkBlue,
                    ),
                    title: 'Treinos Registrados',
                    value: '${counts.totalWorkouts} treinos',
                  ),
                ),
              ],
            );
          },
        ),

        SizedBox(height: 12 * scale),

        // ───────────────────── Card "Último PR" ─────────────────────
        FutureBuilder<String?>(
          future: ProfileSummaryService.fetchLastPrTitle(),
          builder: (context, snap) {
            final isLoading = snap.connectionState != ConnectionState.done;
            final lastPr = snap.data;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 10 * scale,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.mediumGray),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child:
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            lastPr != null && lastPr.isNotEmpty
                                ? 'Ultimo PR Registrado - $lastPr'
                                : 'Você ainda não registrou PRs',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: AppFontWeight.bold,
                              fontSize: 14 * scale,
                              color: AppColors.darkText,
                            ),
                          ),
                          SizedBox(height: 6 * scale),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconTextActionButton(
                                text: 'Registrar novo',
                                iconData: Icons.edit_outlined,
                                fontSize: 12 * scale,
                                onPressed: () {
                                  // TODO: abrir fluxo de registro de novo PR
                                },
                              ),
                              SizedBox(width: 8 * scale),
                              Text(
                                '+',
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: 14 * scale,
                                  color: AppColors.baseBlue,
                                ),
                              ),
                              SizedBox(width: 8 * scale),
                              IconTextActionButton(
                                text: 'Lista de PRs',
                                iconData: Icons.add,
                                fontSize: 12 * scale,
                                onPressed: () {
                                  // TODO: abrir lista de PRs
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
            );
          },
        ),

        SizedBox(height: 24 * scale),
      ],
    );
  }
}

/// Mini-card local da seção (mesma estética do MiniCardWidget),
/// com linha única: ícone + título na MESMA LINHA.
class _SummaryMiniCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String value;

  const _SummaryMiniCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withAlpha(70),
        border: Border.all(color: AppColors.baseBlue, width: 1 * scale),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ícone + Título na MESMA LINHA
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 18 * scale, child: Center(child: icon)),
              SizedBox(width: 6 * scale),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * scale,
                    color: AppColors.darkBlue,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4 * scale),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
