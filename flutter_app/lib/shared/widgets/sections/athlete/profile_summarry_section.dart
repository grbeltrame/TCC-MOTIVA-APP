import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_prs_service.dart';
import 'package:flutter_app/core/services/users/profile_summary_service.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/result_list_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/register_pr/pr_list_bottom_sheet.dart';
import 'package:intl/intl.dart';

class ProfileSummarySection extends StatefulWidget {
  const ProfileSummarySection({Key? key}) : super(key: key);

  @override
  State<ProfileSummarySection> createState() => _ProfileSummarySectionState();
}

class _ProfileSummarySectionState extends State<ProfileSummarySection> {
  late Future<_SummaryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SummaryData> _load() async {
    final prsFut = AthletePrsService.fetchUserPrs();
    final countsFut = ProfileSummaryService.fetchCounts();
    final prs = await prsFut;
    final counts = await countsFut;
    return _SummaryData(
      totalPrs: prs.length,
      totalWorkouts: counts.totalWorkouts,
      lastPr: prs.isNotEmpty ? prs.first : null,
    );
  }

  Future<void> _openTrainings() async {
    await showResultListBottomSheet(context);
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Future<void> _openList() async {
    await showPrListBottomSheet(context);
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 3 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12 * scale, 10 * scale, 12 * scale, 11 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'RESUMO DE ATIVIDADE',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 10 * scale,
                color: AppColors.darkBlue,
                letterSpacing: 0.7,
              ),
            ),
            SizedBox(height: 8 * scale),

            FutureBuilder<_SummaryData>(
              future: _future,
              builder: (ctx, snap) {
                final loading =
                    snap.connectionState != ConnectionState.done;
                final data = snap.data;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 2 blocos: PRs / Treinos ───────────────────────────
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _StatBlock(
                              title: 'PRs Registrados',
                              subtitle: 'no total',
                              icon: Icons.emoji_events_outlined,
                              color: AppColors.baseBlue,
                              scale: scale,
                              value: loading
                                  ? '…'
                                  : '${data?.totalPrs ?? 0} '
                                      '${(data?.totalPrs ?? 0) == 1 ? 'PR' : 'PRs'}',
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Expanded(
                            child: _StatBlock(
                              title: 'Treinos',
                              subtitle: 'registrados',
                              icon: Icons.calendar_month_outlined,
                              color: AppColors.darkBlue,
                              scale: scale,
                              value: loading
                                  ? '…'
                                  : '${data?.totalWorkouts ?? 0} '
                                      '${(data?.totalWorkouts ?? 0) == 1 ? 'treino' : 'treinos'}',
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10 * scale),

                    // ── Último PR ─────────────────────────────────────────
                    _LastPrBlock(
                      loading: loading,
                      lastPr: data?.lastPr,
                      scale: scale,
                    ),

                    SizedBox(height: 10 * scale),

                    // ── Ações ─────────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            label: 'Lista de Treinos',
                            icon: Icons.fitness_center,
                            filled: true,
                            scale: scale,
                            onTap: _openTrainings,
                          ),
                        ),
                        SizedBox(width: 8 * scale),
                        Expanded(
                          child: _ActionButton(
                            label: 'Lista de PRs',
                            icon: Icons.list_alt_outlined,
                            filled: false,
                            scale: scale,
                            onTap: _openList,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Dados agregados
// =============================================================================

class _SummaryData {
  final int totalPrs;
  final int totalWorkouts;
  final AthletePr? lastPr;

  _SummaryData({
    required this.totalPrs,
    required this.totalWorkouts,
    required this.lastPr,
  });
}

// =============================================================================
// Blocos visuais
// =============================================================================

class _StatBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final double scale;
  final String value;

  const _StatBlock({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.scale,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        9 * scale, 8 * scale, 9 * scale, 9 * scale,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(11 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 13 * scale, color: color),
              SizedBox(width: 5 * scale),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 10 * scale,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * scale),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.montserrat,
              fontWeight: FontWeight.bold,
              fontSize: 22 * scale,
              color: AppColors.darkText,
              height: 1,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 3 * scale),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 10 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LastPrBlock extends StatelessWidget {
  final bool loading;
  final AthletePr? lastPr;
  final double scale;

  const _LastPrBlock({
    required this.loading,
    required this.lastPr,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final hasPr = lastPr != null;
    final valStr = hasPr
        ? (lastPr!.value % 1 == 0
            ? lastPr!.value.toInt().toString()
            : lastPr!.value.toStringAsFixed(1))
        : '';

    return Container(
      padding: EdgeInsets.fromLTRB(
        10 * scale, 8 * scale, 10 * scale, 9 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.06),
        border: Border.all(
          color: AppColors.lightBlue.withValues(alpha: 0.28),
        ),
        borderRadius: BorderRadius.circular(11 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_outline,
                size: 13 * scale,
                color: AppColors.lightBlue,
              ),
              SizedBox(width: 5 * scale),
              Text(
                'ÚLTIMO PR',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.bold,
                  fontSize: 10 * scale,
                  color: AppColors.lightBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * scale),
          if (loading)
            Text(
              '…',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: FontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            )
          else if (!hasPr)
            Text(
              'Você ainda não registrou PRs.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            )
          else ...[
            Text(
              '$valStr ${lastPr!.unit} · ${lastPr!.movementName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
                color: AppColors.darkText,
                height: 1.1,
              ),
            ),
            SizedBox(height: 2 * scale),
            Text(
              fmt.format(lastPr!.date),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 10.5 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final double scale;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : AppColors.darkBlue;
    final bg = filled ? AppColors.baseBlue : Colors.transparent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * scale,
          vertical: 9 * scale,
        ),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: AppColors.baseBlue),
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14 * scale, color: fg),
            SizedBox(width: 6 * scale),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.w600,
                  fontSize: 12 * scale,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
