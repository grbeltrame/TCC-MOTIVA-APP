// lib/shared/widgets/cards/week_prs_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_prs_service.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/shared/widgets/register_pr/register_pr_bottom_sheet.dart';

/// Card de PRs batidos na semana.
/// Um PR por vez em carrossel com setas de navegação.
class WeekPRsCard extends StatefulWidget {
  const WeekPRsCard({Key? key}) : super(key: key);

  @override
  State<WeekPRsCard> createState() => _WeekPRsCardState();
}

class _WeekPRsCardState extends State<WeekPRsCard> {
  late Future<List<AthletePr>> _prsFut;
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _prsFut = _fetchWeekPrs();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<List<AthletePr>> _fetchWeekPrs() {
    final range = WeeklySummaryService().fetchCurrentWeekRange();
    return AthletePrsService.fetchWeekPrs(
      weekStart: range.start,
      weekEnd: range.end,
    );
  }

  void _reload() {
    setState(() {
      _prsFut = _fetchWeekPrs();
      _currentPage = 0;
    });
    // Volta para a primeira página após reload
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageCtrl.hasClients) {
        _pageCtrl.jumpToPage(0);
      }
    });
  }

  Future<void> _confirmDelete(AthletePr pr) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AppDialog(
        icon: Icons.delete_outline,
        iconColor: AppColors.baseMagenta,
        title: 'Apagar PR?',
        message: '${pr.movementName} — ${_fmtValue(pr)} será removido.',
        secondaryAction: TextButton(
          onPressed: () =>
              Navigator.of(dCtx, rootNavigator: true).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.mediumGray),
          child: const Text('Cancelar'),
        ),
        primaryAction: TextButton(
          onPressed: () =>
              Navigator.of(dCtx, rootNavigator: true).pop(true),
          style:
              TextButton.styleFrom(foregroundColor: AppColors.baseMagenta),
          child: const Text('Apagar'),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await AthletePrsService.deletePr(pr.id);
      _reload();
    }
  }

  String _fmtValue(AthletePr pr) {
    final val = pr.value % 1 == 0
        ? pr.value.toInt().toString()
        : pr.value.toStringAsFixed(1);
    return '$val ${pr.unit}';
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
          12 * scale,
          10 * scale,
          12 * scale,
          11 * scale,
        ),
        child: FutureBuilder<List<AthletePr>>(
          future: _prsFut,
          builder: (context, snap) {
            final loading = snap.connectionState == ConnectionState.waiting;
            final prs = snap.data ?? [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'PRs BATIDOS',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: FontWeight.bold,
                        fontSize: 10 * scale,
                        color: AppColors.darkBlue,
                        letterSpacing: 0.7,
                      ),
                    ),
                    SizedBox(width: 6 * scale),

                    // Badge com total
                    if (!loading)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * scale,
                          vertical: 1.5 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: prs.isNotEmpty
                              ? AppColors.baseBlue.withValues(alpha: .12)
                              : AppColors.lightGray,
                          borderRadius: BorderRadius.circular(18 * scale),
                        ),
                        child: Text(
                          '${prs.length}',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.bold,
                            fontSize: 10 * scale,
                            color: prs.isNotEmpty
                                ? AppColors.baseBlue
                                : AppColors.mediumGray,
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Botão registrar
                    GestureDetector(
                      onTap: () async {
                        await showRegisterPrBottomSheet(context);
                        if (mounted) _reload();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add,
                              size: 12 * scale, color: AppColors.baseBlue),
                          SizedBox(width: 2 * scale),
                          Text(
                            'Registrar PR',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: FontWeight.bold,
                              fontSize: 10 * scale,
                              color: AppColors.baseBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 6 * scale),

                // ── Número grande ──────────────────────────────────────────
                if (loading)
                  SizedBox(
                    height: 44 * scale,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${prs.length}',
                        style: TextStyle(
                          fontFamily: AppFonts.montserrat,
                          fontWeight: FontWeight.bold,
                          fontSize: 26 * scale,
                          color: prs.isNotEmpty
                              ? AppColors.darkBlue
                              : AppColors.lightGray,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: 4 * scale, left: 3 * scale),
                        child: Text(
                          prs.length == 1
                              ? 'PR esta semana'
                              : 'PRs esta semana',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 10.5 * scale,
                            color: AppColors.mediumGray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6 * scale),

                  if (prs.isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 2 * scale),
                      child: Text(
                        'Nenhum PR registrado esta semana.\nQue tal quebrar um recorde hoje?',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 10.5 * scale,
                          color: AppColors.mediumGray,
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    )
                  else ...[
                    Divider(
                      color: AppColors.mediumGray.withValues(alpha: .15),
                      height: 1,
                    ),
                    SizedBox(height: 6 * scale),

                    // ── Carrossel de PRs ───────────────────────────────────
                    _PrCarousel(
                      prs: prs,
                      pageCtrl: _pageCtrl,
                      currentPage: _currentPage,
                      scale: scale,
                      onPageChanged: (i) =>
                          setState(() => _currentPage = i),
                      onEdit: (pr) async {
                        await showRegisterPrBottomSheet(
                          context,
                          existingPr: pr,
                        );
                        if (mounted) _reload();
                      },
                      onDelete: _confirmDelete,
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// Carrossel — um PR por vez com setas e dots
// =============================================================================

class _PrCarousel extends StatelessWidget {
  final List<AthletePr> prs;
  final PageController pageCtrl;
  final int currentPage;
  final double scale;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<AthletePr> onEdit;
  final ValueChanged<AthletePr> onDelete;

  const _PrCarousel({
    required this.prs,
    required this.pageCtrl,
    required this.currentPage,
    required this.scale,
    required this.onPageChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final total = prs.length;
    final hasPrev = currentPage > 0;
    final hasNext = currentPage < total - 1;

    return Column(
      children: [
        // PR tile com setas laterais
        Row(
          children: [
            // Seta esquerda
            _NavArrow(
              icon: Icons.chevron_left,
              enabled: hasPrev,
              scale: scale,
              onTap: () => pageCtrl.previousPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              ),
            ),

            // PageView com altura fixa
            Expanded(
              child: SizedBox(
                height: 58 * scale,
                child: PageView.builder(
                  controller: pageCtrl,
                  onPageChanged: onPageChanged,
                  itemCount: total,
                  itemBuilder: (_, i) => _PrTile(
                    pr: prs[i],
                    scale: scale,
                    onEdit: () => onEdit(prs[i]),
                    onDelete: () => onDelete(prs[i]),
                  ),
                ),
              ),
            ),

            // Seta direita
            _NavArrow(
              icon: Icons.chevron_right,
              enabled: hasNext,
              scale: scale,
              onTap: () => pageCtrl.nextPage(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),

        // Dots indicadores (só quando tem mais de 1)
        if (total > 1) ...[
          SizedBox(height: 8 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 3 * scale),
                width: active ? 16 * scale : 6 * scale,
                height: 6 * scale,
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.baseBlue
                      : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(3 * scale),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Seta de navegação
// =============================================================================

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final double scale;
  final VoidCallback onTap;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 2 * scale),
        child: Icon(
          icon,
          size: 22 * scale,
          color: enabled
              ? AppColors.baseBlue
              : AppColors.lightGray,
        ),
      ),
    );
  }
}

// =============================================================================
// Tile de um PR
// =============================================================================

class _PrTile extends StatelessWidget {
  final AthletePr pr;
  final double scale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PrTile({
    required this.pr,
    required this.scale,
    required this.onEdit,
    required this.onDelete,
  });

  IconData _icon(PrType type) => switch (type) {
    PrType.weight   => Icons.fitness_center,
    PrType.reps     => Icons.repeat,
    PrType.time     => Icons.timer_outlined,
    PrType.distance => Icons.straighten,
  };

  Color _color(PrType type) => switch (type) {
    PrType.weight   => AppColors.darkBlue,
    PrType.reps     => AppColors.baseBlue,
    PrType.time     => AppColors.lightMagenta,
    PrType.distance => const Color(0xFF2E7D32),
  };

  String _fmtValue(AthletePr pr) {
    final val = pr.value % 1 == 0
        ? pr.value.toInt().toString()
        : pr.value.toStringAsFixed(1);
    return '$val ${pr.unit}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(pr.prType);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2 * scale),
      child: Row(
        children: [
          // Ícone com fundo colorido
          Container(
            width: 30 * scale,
            height: 30 * scale,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Icon(_icon(pr.prType), size: 15 * scale, color: color),
          ),
          SizedBox(width: 8 * scale),

          // Nome do movimento e data
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pr.movementName,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 1 * scale),
                Text(
                  _formatDate(pr.date),
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 9.5 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 4 * scale),

          // Valor em destaque
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * scale,
              vertical: 3 * scale,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(5 * scale),
              border: Border.all(color: color.withValues(alpha: .25)),
            ),
            child: Text(
              _fmtValue(pr),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 11 * scale,
                color: color,
              ),
            ),
          ),

          SizedBox(width: 4 * scale),

          // Botões editar / deletar
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionBtn(
                icon: Icons.edit_outlined,
                color: AppColors.baseBlue,
                scale: scale,
                onTap: onEdit,
              ),
              SizedBox(height: 3 * scale),
              _ActionBtn(
                icon: Icons.delete_outline,
                color: AppColors.baseMagenta,
                scale: scale,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]}';
  }
}

// =============================================================================
// Botão de ação pequeno (editar / deletar)
// =============================================================================

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double scale;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 20 * scale,
        height: 20 * scale,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(5 * scale),
        ),
        child: Icon(icon, size: 11 * scale, color: color),
      ),
    );
  }
}
