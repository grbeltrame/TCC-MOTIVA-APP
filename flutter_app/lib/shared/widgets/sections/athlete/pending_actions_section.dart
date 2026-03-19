// lib/shared/widgets/sections/athlete/pending_actions_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/core/services/pending_actions_service.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';

/// Banner de resultado/pendência do treino.
///
/// Estado 1 — não registrou → card magenta com CTA "Registrar agora"
/// Estado 2 — já registrou  → card azul mostrando resumo do esforço
class PendingActionsSection extends StatefulWidget {
  final double? bottomSpacing;

  const PendingActionsSection({Key? key, this.bottomSpacing}) : super(key: key);

  @override
  State<PendingActionsSection> createState() => _PendingActionsSectionState();
}

class _PendingActionsSectionState extends State<PendingActionsSection> {
  // Carrega as duas fontes em paralelo
  late Future<_SectionData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_SectionData> _load() async {
    final results = await Future.wait([
      PendingActionsService.fetchTopPendingForToday(),
      EffortService.fetchTodayResult(wodType: 'WOD'),
    ]);
    return _SectionData(
      pending: results[0] as PendingAction?,
      record: results[1] as AthleteResultRecord?,
    );
  }

  /// Recarrega após o atleta registrar — chamado pelo CTA
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

        // ── Estado 2: já registrou ──────────────────────────────────────────
        if (data.record != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RegisteredCard(
                record: data.record!,
                scale: scale,
                onEdit: () async {
                  await showRegisterResultBottomSheet(
                    context,
                    existingRecord: data.record,
                  );
                  // Adia o reload para fora do contexto de build atual
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _reload();
                  });
                },
              ),
              SizedBox(height: spacing),
            ],
          );
        }

        // ── Estado 1: não registrou ─────────────────────────────────────────
        if (data.pending != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PendingCard(
                action: data.pending!,
                scale: scale,
                onRegistered: _reload,
              ),
              SizedBox(height: spacing),
            ],
          );
        }

        // Nenhum treino hoje — some
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
  final AthleteResultRecord? record;
  const _SectionData({this.pending, this.record});
}

// =============================================================================
// Card — Estado 1: pendente (magenta)
// =============================================================================

class _PendingCard extends StatelessWidget {
  final PendingAction action;
  final double scale;
  final VoidCallback onRegistered;

  const _PendingCard({
    required this.action,
    required this.scale,
    required this.onRegistered,
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
            onPressed: () async {
              if (action.onTap != null) {
                await action.onTap!(context);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (onRegistered is Function) onRegistered();
                });
              } else if (action.route.isNotEmpty) {
                Navigator.of(context).pushNamed(action.route);
              }
            },
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
// Card — Estado 2: registrado (azul)
// =============================================================================

class _RegisteredCard extends StatelessWidget {
  final AthleteResultRecord record;
  final double scale;
  final VoidCallback onEdit;

  const _RegisteredCard({
    required this.record,
    required this.scale,
    required this.onEdit,
  });

  // Formata mm:ss a partir de segundos
  String _fmtTime(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Linha de resultado condicional por modalidade
  String? _resultLine() {
    if (record.modalidade == 'FOR TIME' && record.forTimeSec != null) {
      return 'Tempo: ${_fmtTime(record.forTimeSec!)}';
    }
    if (record.modalidade == 'AMRAP') {
      final r = record.amrapRounds;
      final rp = record.amrapReps;
      if (r != null && rp != null) return '$r rounds + $rp reps';
      if (r != null) return '$r rounds';
    }
    if (record.modalidade == 'EMOM') {
      final completed = record.emomCompletedRounds == null;
      return completed
          ? 'Completou todos os rounds'
          : '${record.emomCompletedRounds} min completados';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final kBlue = const Color(0xFF224DFF);
    final resultLine = _resultLine();

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
            color: kBlue.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label "Seu esforço de hoje"
          Text(
            'Seu esforço de hoje',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 11 * scale,
              fontWeight: AppFontWeight.bold,
              color: AppColors.mediumGray,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6 * scale),

          // Nome do WOD + categoria + horário
          Row(
            children: [
              Expanded(
                child: Text(
                  record.wodName ?? record.wodType,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 15 * scale,
                    color: AppColors.darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                record.trainingTime,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 12 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),

          // Categoria + resultado
          SizedBox(height: 4 * scale),
          Wrap(
            spacing: 6 * scale,
            children: [
              _SmallChip(label: record.category, scale: scale),
              if (record.adapted) _SmallChip(label: 'Adaptado', scale: scale),
              if (resultLine != null)
                _SmallChip(label: resultLine, scale: scale),
            ],
          ),

          SizedBox(height: 10 * scale),

          // Barra de esforço
          _EffortBar(effort: record.effort, scale: scale),

          SizedBox(height: 8 * scale),
          Divider(color: AppColors.mediumGray.withOpacity(0.15), height: 1),
          SizedBox(height: 6 * scale),

          // Botão editar — alinhado à direita, padrão dos outros CTAs
          GestureDetector(
            onTap: onEdit,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Editar registro',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 11 * scale,
                    color: AppColors.baseBlue,
                    fontWeight: AppFontWeight.bold,
                  ),
                ),
                SizedBox(width: 3 * scale),
                Icon(
                  Icons.edit_outlined,
                  size: 12 * scale,
                  color: AppColors.baseBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Barra de esforço visual
// =============================================================================

class _EffortBar extends StatelessWidget {
  final int effort; // 1-10
  final double scale;

  const _EffortBar({required this.effort, required this.scale});

  Color get _color {
    if (effort < 5) return const Color(0xFF224DFF);
    if (effort == 5) return AppColors.mediumGray;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4 * scale),
            child: LinearProgressIndicator(
              value: effort / 10,
              minHeight: 6 * scale,
              backgroundColor: AppColors.mediumGray.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
        ),
        SizedBox(width: 8 * scale),
        Text(
          '$effort/10',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.bold,
            fontSize: 12 * scale,
            color: _color,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Chip pequeno de info
// =============================================================================

class _SmallChip extends StatelessWidget {
  final String label;
  final double scale;

  const _SmallChip({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: AppColors.baseBlue.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: AppColors.baseBlue.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 11 * scale,
          color: AppColors.baseBlue,
          fontWeight: AppFontWeight.medium,
        ),
      ),
    );
  }
}
