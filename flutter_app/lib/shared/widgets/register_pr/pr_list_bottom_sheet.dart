// lib/shared/widgets/register_pr/pr_list_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_prs_service.dart';
import 'package:flutter_app/shared/widgets/register_pr/register_pr_bottom_sheet.dart';
import 'package:intl/intl.dart';

/// Abre o sheet com a lista de PRs do atleta.
/// Primeiro nível: exercícios únicos que já têm PR.
/// Segundo nível (ao tocar no exercício): todos os PRs daquele movimento.
/// Ao tocar em um PR, abre o sheet de edição pré-preenchido.
Future<void> showPrListBottomSheet(BuildContext context) {
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
          _PrListSheet(scrollController: scrollCtrl),
    ),
  );
}

class _PrListSheet extends StatefulWidget {
  final ScrollController scrollController;
  const _PrListSheet({required this.scrollController});

  @override
  State<_PrListSheet> createState() => _PrListSheetState();
}

class _PrListSheetState extends State<_PrListSheet> {
  late Future<List<AthletePr>> _future;

  /// Quando não-nulo, estamos no segundo nível (detalhes de um movimento).
  String? _selectedMovementId;
  String? _selectedMovementName;

  @override
  void initState() {
    super.initState();
    _future = AthletePrsService.fetchUserPrs();
  }

  void _reload() {
    final next = AthletePrsService.fetchUserPrs();
    setState(() {
      _future = next;
    });
  }

  void _openMovement(String movementId, String movementName) {
    setState(() {
      _selectedMovementId = movementId;
      _selectedMovementName = movementName;
    });
  }

  void _backToList() {
    setState(() {
      _selectedMovementId = null;
      _selectedMovementName = null;
    });
  }

  Future<void> _openEdit(AthletePr pr) async {
    await showRegisterPrBottomSheet(context, existingPr: pr);
    if (!mounted) return;
    _reload();
  }

  Future<void> _confirmAndDelete(AthletePr pr) async {
    final valStr = pr.value % 1 == 0
        ? pr.value.toInt().toString()
        : pr.value.toStringAsFixed(1);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Apagar PR?'),
        content: Text(
          'Esta ação não pode ser desfeita.\n\n'
          '${pr.movementName} — $valStr ${pr.unit}',
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
      await AthletePrsService.deletePr(pr.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao apagar PR: $e')),
      );
      return;
    }
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final isDetail = _selectedMovementId != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ── Handle + Cabeçalho ──────────────────────────────────────────
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
                Row(
                  children: [
                    if (isDetail) ...[
                      GestureDetector(
                        onTap: _backToList,
                        child: Icon(
                          Icons.arrow_back,
                          size: 22 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                    ],
                    Expanded(
                      child: Text(
                        isDetail
                            ? (_selectedMovementName ?? 'PRs')
                            : 'Meus PRs',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.montserrat,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 20 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4 * scale),
                Text(
                  isDetail
                      ? 'Use os botões ao lado de cada registro para editar ou apagar.'
                      : 'Toque em um exercício para ver todos os PRs registrados.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
                SizedBox(height: 14 * scale),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<AthletePr>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                final all = snap.data ?? [];
                if (all.isEmpty) {
                  return _EmptyMessage(
                    message: 'Você ainda não registrou nenhum PR.',
                    scale: scale,
                  );
                }

                return isDetail
                    ? _buildDetailList(all, scale)
                    : _buildMovementsList(all, scale);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Nível 1: lista de movimentos únicos ───────────────────────────────
  Widget _buildMovementsList(List<AthletePr> all, double scale) {
    final Map<String, _MovementGroup> grouped = {};
    for (final pr in all) {
      final g = grouped.putIfAbsent(
        pr.movementId,
        () => _MovementGroup(id: pr.movementId, name: pr.movementName),
      );
      g.count++;
      if (g.latest == null || pr.date.isAfter(g.latest!.date)) {
        g.latest = pr;
      }
    }

    final list = grouped.values.toList()
      ..sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView.separated(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        16 * scale, 0, 16 * scale, 16 * scale,
      ),
      itemCount: list.length,
      separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
      itemBuilder: (_, i) {
        final g = list[i];
        return _MovementTile(
          name: g.name,
          prCount: g.count,
          scale: scale,
          onTap: () => _openMovement(g.id, g.name),
        );
      },
    );
  }

  // ── Nível 2: lista de PRs do movimento selecionado ────────────────────
  Widget _buildDetailList(List<AthletePr> all, double scale) {
    final fmt = DateFormat('dd/MM/yyyy');
    final prs = all
        .where((pr) => pr.movementId == _selectedMovementId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (prs.isEmpty) {
      return _EmptyMessage(
        message: 'Nenhum PR registrado para este exercício.',
        scale: scale,
      );
    }

    return ListView.separated(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(
        16 * scale, 0, 16 * scale, 16 * scale,
      ),
      itemCount: prs.length,
      separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
      itemBuilder: (_, i) {
        final pr = prs[i];
        final valStr = pr.value % 1 == 0
            ? pr.value.toInt().toString()
            : pr.value.toStringAsFixed(1);
        return _PrTile(
          valueLabel: '$valStr ${pr.unit}',
          dateLabel: fmt.format(pr.date),
          scale: scale,
          onEdit: () => _openEdit(pr),
          onDelete: () => _confirmAndDelete(pr),
        );
      },
    );
  }
}

class _MovementGroup {
  final String id;
  final String name;
  int count = 0;
  AthletePr? latest;
  _MovementGroup({required this.id, required this.name});
}

// =============================================================================
// Tiles
// =============================================================================

class _MovementTile extends StatelessWidget {
  final String name;
  final int prCount;
  final double scale;
  final VoidCallback onTap;

  const _MovementTile({
    required this.name,
    required this.prCount,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 11 * scale,
        ),
        decoration: BoxDecoration(
          color: AppColors.baseBlue.withValues(alpha: 0.05),
          border: Border.all(
            color: AppColors.baseBlue.withValues(alpha: 0.25),
          ),
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: Row(
          children: [
            Icon(
              Icons.fitness_center,
              size: 18 * scale,
              color: AppColors.baseBlue,
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.w600,
                  fontSize: 13 * scale,
                  color: AppColors.darkText,
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8 * scale,
                vertical: 3 * scale,
              ),
              decoration: BoxDecoration(
                color: AppColors.baseBlue,
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Text(
                '$prCount ${prCount == 1 ? 'PR' : 'PRs'}',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.bold,
                  fontSize: 11 * scale,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 6 * scale),
            Icon(
              Icons.chevron_right,
              size: 18 * scale,
              color: AppColors.mediumGray,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrTile extends StatelessWidget {
  final String valueLabel;
  final String dateLabel;
  final double scale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PrTile({
    required this.valueLabel,
    required this.dateLabel,
    required this.scale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 8 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.06),
        border: Border.all(
          color: AppColors.lightBlue.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 18 * scale,
            color: AppColors.lightBlue,
          ),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              dateLabel,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 4 * scale,
            ),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Text(
              valueLabel,
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: FontWeight.bold,
                fontSize: 12 * scale,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 4 * scale),
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
