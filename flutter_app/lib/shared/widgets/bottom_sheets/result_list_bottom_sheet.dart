// lib/shared/widgets/bottom_sheets/result_list_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/other_activity_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
import 'package:intl/intl.dart';

/// Abre o sheet com a lista de treinos registrados pelo atleta.
/// Lista cronológica desc, agrupada por mês, com botão de "Registrar treino"
/// no topo e ações editar/apagar por item.
Future<void> showResultListBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) =>
          _ResultListSheet(scrollController: scrollCtrl),
    ),
  );
}

class _ResultListSheet extends StatefulWidget {
  final ScrollController scrollController;
  const _ResultListSheet({required this.scrollController});

  @override
  State<_ResultListSheet> createState() => _ResultListSheetState();
}

class _ResultListSheetState extends State<_ResultListSheet> {
  late Future<List<TodayRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = EffortService.fetchAllRecords();
  }

  void _reload() {
    setState(() {
      _future = EffortService.fetchAllRecords();
    });
  }

  Future<void> _openNew() async {
    await showRegisterResultBottomSheet(context);
    if (!mounted) return;
    _reload();
  }

  Future<void> _openEdit(TodayRecord rec) async {
    if (rec.isOtherActivity) {
      final dateStr = rec.raw['date']?.toString() ?? '';
      DateTime date;
      try {
        date = DateTime.parse(dateStr);
      } catch (_) {
        date = DateTime.now();
      }
      await showOtherActivityBottomSheet(
        context,
        date: date,
        existingDocId: rec.docId,
        existingData: rec.raw,
      );
    } else if (rec.isWod) {
      final athleteRec = rec.toAthleteResultRecord();
      if (athleteRec == null) return;
      await showRegisterResultBottomSheet(
        context,
        existingRecord: athleteRec,
      );
    }
    if (!mounted) return;
    _reload();
  }

  Future<void> _confirmAndDelete(TodayRecord rec) async {
    final dateLabel = _fmtDate(rec.raw['date']?.toString() ?? '');
    final title = rec.displayName;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Apagar registro?'),
        content: Text(
          'Esta ação não pode ser desfeita.\n\n'
          '$title — $dateLabel',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.baseMagenta,
            ),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await EffortService.deleteRecord(rec.docId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao apagar registro: $e')),
      );
      return;
    }
    if (!mounted) return;
    _reload();
  }

  static String _fmtDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (_) {
      return iso;
    }
  }

  static String _monthLabel(DateTime d) {
    final fmt = DateFormat("MMMM 'de' yyyy", 'pt_BR');
    final s = fmt.format(d);
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ── Handle + Cabeçalho + botão "Registrar treino" ──────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              16 * scale, 10 * scale, 16 * scale, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40 * scale,
                    height: 4 * scale,
                    decoration: BoxDecoration(
                      color: AppColors.mediumGray.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(2 * scale),
                    ),
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  'Meus Treinos',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 20 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  'Toque em editar para corrigir um registro antigo, ou apague o que estiver errado.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
                SizedBox(height: 12 * scale),
                _RegisterButton(scale: scale, onTap: _openNew),
                SizedBox(height: 12 * scale),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<TodayRecord>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                if (all.isEmpty) {
                  return _EmptyMessage(
                    message: 'Você ainda não registrou nenhum treino.',
                    scale: scale,
                  );
                }

                return _buildList(all, scale);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<TodayRecord> all, double scale) {
    // Agrupa por mês (YYYY-MM) preservando ordem desc.
    final List<_ListEntry> entries = [];
    String? currentMonth;
    for (final rec in all) {
      final dateStr = rec.raw['date']?.toString();
      if (dateStr == null || dateStr.length < 7) continue;
      DateTime? d;
      try {
        d = DateTime.parse(dateStr);
      } catch (_) {
        continue;
      }
      final monthKey = '${d.year}-${d.month.toString().padLeft(2, '0')}';
      if (monthKey != currentMonth) {
        currentMonth = monthKey;
        entries.add(_ListEntry.header(_monthLabel(d)));
      }
      entries.add(_ListEntry.tile(rec, d));
    }

    return ListView.separated(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        16 * scale, 0, 16 * scale, 16 * scale,
      ),
      itemCount: entries.length,
      separatorBuilder: (_, i) {
        final next = i + 1 < entries.length ? entries[i + 1] : null;
        // Sem espaçamento antes de header (header já tem padding interno)
        if (next?.isHeader ?? false) return SizedBox(height: 14 * scale);
        return SizedBox(height: 8 * scale);
      },
      itemBuilder: (_, i) {
        final e = entries[i];
        if (e.isHeader) {
          return Padding(
            padding: EdgeInsets.only(top: 6 * scale, bottom: 4 * scale),
            child: Text(
              e.headerText!,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 11 * scale,
                color: AppColors.darkBlue,
                letterSpacing: 0.6,
              ),
            ),
          );
        }
        return _ResultTile(
          rec: e.rec!,
          date: e.date!,
          scale: scale,
          onEdit: e.rec!.isRest ? null : () => _openEdit(e.rec!),
          onDelete: () => _confirmAndDelete(e.rec!),
        );
      },
    );
  }
}

class _ListEntry {
  final bool isHeader;
  final String? headerText;
  final TodayRecord? rec;
  final DateTime? date;

  _ListEntry.header(this.headerText)
      : isHeader = true,
        rec = null,
        date = null;
  _ListEntry.tile(this.rec, this.date)
      : isHeader = false,
        headerText = null;
}

// =============================================================================
// Tiles e botões
// =============================================================================

class _RegisterButton extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;

  const _RegisterButton({required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale, vertical: 10 * scale,
        ),
        decoration: BoxDecoration(
          color: AppColors.baseBlue,
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 16 * scale, color: Colors.white),
            SizedBox(width: 6 * scale),
            Text(
              'Registrar treino',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.w600,
                fontSize: 13 * scale,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final TodayRecord rec;
  final DateTime date;
  final double scale;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _ResultTile({
    required this.rec,
    required this.date,
    required this.scale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    final isRest = rec.isRest;
    final isOther = rec.isOtherActivity;

    final IconData icon;
    final Color tint;
    if (isRest) {
      icon = Icons.bedtime_outlined;
      tint = AppColors.mediumGray;
    } else if (isOther) {
      icon = Icons.directions_run;
      tint = AppColors.lightBlue;
    } else {
      icon = Icons.fitness_center;
      tint = AppColors.baseBlue;
    }

    final subtitle = isRest
        ? 'Dia de descanso'
        : (isOther
            ? (rec.raw['activity']?.toString() ?? 'Outra atividade')
            : (rec.raw['wodType']?.toString() ?? 'Treino'));

    final effort = rec.effort;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.06),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18 * scale, color: tint),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rec.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.w600,
                    fontSize: 13 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  '${fmt.format(date)} · $subtitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 11 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          if (!isRest)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 7 * scale,
                vertical: 3 * scale,
              ),
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Text(
                'RPE $effort',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: FontWeight.bold,
                  fontSize: 11 * scale,
                  color: Colors.white,
                ),
              ),
            ),
          SizedBox(width: 4 * scale),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit_outlined,
                size: 18 * scale,
                color: AppColors.darkBlue,
              ),
              tooltip: 'Editar',
              constraints: BoxConstraints(
                minWidth: 32 * scale,
                minHeight: 32 * scale,
              ),
              padding: EdgeInsets.all(4 * scale),
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline,
              size: 18 * scale,
              color: AppColors.baseMagenta,
            ),
            tooltip: 'Apagar',
            constraints: BoxConstraints(
              minWidth: 32 * scale,
              minHeight: 32 * scale,
            ),
            padding: EdgeInsets.all(4 * scale),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;
  final double scale;
  const _EmptyMessage({required this.message, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * scale),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 13 * scale,
            color: AppColors.mediumGray,
          ),
        ),
      ),
    );
  }
}
