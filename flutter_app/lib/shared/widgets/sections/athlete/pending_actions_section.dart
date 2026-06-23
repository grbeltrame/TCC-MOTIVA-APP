// lib/shared/widgets/sections/athlete/pending_actions_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/core/services/pending_actions_service.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/today_records_bottom_sheet.dart';

/// Banner de resultado/pendência do treino.
///
/// Estado 1 — sem registros → card magenta com CTA "Registrar agora"
/// Estado 2 — tem registros → card azul "X treinos cadastrados hoje" + ver tudo
class PendingActionsSection extends StatefulWidget {
  final double? bottomSpacing;

  const PendingActionsSection({Key? key, this.bottomSpacing}) : super(key: key);

  @override
  State<PendingActionsSection> createState() => _PendingActionsSectionState();
}

class _PendingActionsSectionState extends State<PendingActionsSection> {
  late Future<_SectionData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SectionData> _load() async {
    final results = await Future.wait([
      PendingActionsService.fetchTopPendingForToday(),
      EffortService.fetchAllRecordsForDate(DateTime.now()),
    ]);
    return _SectionData(
      pending: results[0] as PendingAction?,
      records: results[1] as List<TodayRecord>,
    );
  }

  void _reload() {
    final newFuture = _load();
    setState(() {
      _future = newFuture;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final spacing = widget.bottomSpacing ?? 16 * scale;

    return FutureBuilder<_SectionData>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        final data = snap.data;
        if (data == null) return const SizedBox.shrink();

        // ── Estado 2: tem registros ─────────────────────────────────────────
        if (data.records.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RegisteredCard(
                records: data.records,
                scale: scale,
                onViewAll: () async {
                  await showTodayRecordsBottomSheet(
                    context,
                    initialRecords: data.records,
                    onChanged: () {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _reload();
                      });
                    },
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _reload();
                  });
                },
                onRegisterNew: () async {
                  await showRegisterResultBottomSheet(
                    context,
                    hasExistingRecords: true,
                    parentContext: context,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _reload();
                  });
                },
              ),
              SizedBox(height: spacing),
            ],
          );
        }

        // ── Estado 1: sem registros ─────────────────────────────────────────
        if (data.pending != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PendingCard(
                action: data.pending!,
                scale: scale,
                // Abre o sheet usando o context estável do State (não do card),
                // e aguarda TODO o fluxo (incluindo dialogs subsequentes) antes
                // de recarregar — evita desmontar o card enquanto dialogs estão abertos.
                onTapCta: () async {
                  await showRegisterResultBottomSheet(
                    context,
                    hasExistingRecords: false,
                    parentContext: context,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _reload();
                  });
                },
              ),
              SizedBox(height: spacing),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// =============================================================================
// Modelo interno
// =============================================================================

class _SectionData {
  final PendingAction? pending;
  final List<TodayRecord> records;
  const _SectionData({this.pending, required this.records});
}

// =============================================================================
// Card — Estado 1: pendente (magenta)
// =============================================================================

class _PendingCard extends StatelessWidget {
  final PendingAction action;
  final double scale;
  final VoidCallback onTapCta;

  const _PendingCard({
    required this.action,
    required this.scale,
    required this.onTapCta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 10 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightMagenta.withAlpha(50),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: AppColors.baseMagenta, width: 1 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            action.message,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.regular,
              fontSize: 12 * scale,
              color: AppColors.darkText,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6 * scale),
          TextButton.icon(
            onPressed: onTapCta,
            icon: Icon(
              action.ctaIcon,
              color: AppColors.baseBlue,
              size: 16 * scale,
            ),
            label: Text(
              action.ctaLabel,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                fontSize: 12 * scale,
                color: AppColors.baseBlue,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Card — Estado 2: tem registros (azul)
// =============================================================================

class _RegisteredCard extends StatelessWidget {
  final List<TodayRecord> records;
  final double scale;
  final VoidCallback onViewAll;
  final VoidCallback onRegisterNew;

  const _RegisteredCard({
    required this.records,
    required this.scale,
    required this.onViewAll,
    required this.onRegisterNew,
  });

  @override
  Widget build(BuildContext context) {
    const kBlue = Color(0xFF224DFF);
    final count = records.length;
    final isRestOnly = records.length == 1 && records.first.isRest;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12 * scale,
        10 * scale,
        12 * scale,
        12 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: kBlue, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kBlue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            'Atividades de hoje',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 11 * scale,
              fontWeight: AppFontWeight.bold,
              color: AppColors.mediumGray,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6 * scale),

          // Texto principal
          Row(
            children: [
              if (isRestOnly) ...[
                Icon(
                  Icons.bedtime_outlined,
                  size: 16 * scale,
                  color: AppColors.darkText,
                ),
                SizedBox(width: 6 * scale),
              ],
              Text(
                isRestOnly
                    ? 'Dia de descanso'
                    : 'Você tem $count registro${count > 1 ? 's' : ''} hoje',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 15 * scale,
                  color: AppColors.darkText,
                ),
              ),
            ],
          ),

          SizedBox(height: 8 * scale),
          Divider(color: AppColors.mediumGray.withValues(alpha: 0.15), height: 1),
          SizedBox(height: 6 * scale),

          // Botões de ação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onRegisterNew,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 12 * scale, color: AppColors.baseBlue),
                    SizedBox(width: 3 * scale),
                    Text(
                      'Registrar novo',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 11 * scale,
                        color: AppColors.baseBlue,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onViewAll,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver registros',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 11 * scale,
                        color: AppColors.baseBlue,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 3 * scale),
                    Icon(
                      Icons.chevron_right,
                      size: 14 * scale,
                      color: AppColors.baseBlue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
