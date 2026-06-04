// lib/shared/widgets/bottom_sheets/today_records_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/other_activity_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';

Future<void> showTodayRecordsBottomSheet(
  BuildContext context, {
  required List<TodayRecord> initialRecords,
  required VoidCallback onChanged,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _TodayRecordsSheet(
      initialRecords: initialRecords,
      onChanged: onChanged,
    ),
  );
}

class _TodayRecordsSheet extends StatefulWidget {
  const _TodayRecordsSheet({
    required this.initialRecords,
    required this.onChanged,
  });

  final List<TodayRecord> initialRecords;
  final VoidCallback onChanged;

  @override
  State<_TodayRecordsSheet> createState() => _TodayRecordsSheetState();
}

class _TodayRecordsSheetState extends State<_TodayRecordsSheet> {
  late List<TodayRecord> _records;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _records = List.from(widget.initialRecords);
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final fresh = await EffortService.fetchAllRecordsForDate(DateTime.now());
    if (!mounted) return;
    if (fresh.isEmpty) {
      widget.onChanged();
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _records = fresh;
      _loading = false;
    });
    widget.onChanged();
  }

  Future<void> _confirmDelete(TodayRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AppDialog(
            icon: Icons.delete_outline,
            iconColor: Colors.red,
            title: 'Apagar registro?',
            message:
                'O registro "${record.displayName}" será removido permanentemente.',
            primaryAction: TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Apagar',
                style: TextStyle(color: Colors.red),
              ),
            ),
            secondaryAction: TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
          ),
    );
    if (confirmed != true) return;
    try {
      await EffortService.deleteRecord(record.docId);
      await _reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao apagar: $e')));
      }
    }
  }

  Future<void> _editRecord(TodayRecord record) async {
    if (record.isWod) {
      await showRegisterResultBottomSheet(
        context,
        existingRecord: record.toAthleteResultRecord(),
      );
    } else if (record.isOtherActivity) {
      await showOtherActivityBottomSheet(
        context,
        date: DateTime.now(),
        existingDocId: record.docId,
        existingData: record.raw,
      );
    }
    // REST: sem edição
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return AppBottomSheet(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          10 * scale,
          16 * scale,
          20 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40 * scale,
                height: 4 * scale,
                decoration: BoxDecoration(
                  color: AppColors.mediumGray.withOpacity(.6),
                  borderRadius: BorderRadius.circular(2 * scale),
                ),
              ),
            ),
            SizedBox(height: 12 * scale),

            // Título
            Text(
              'Treinos de hoje (${_records.length})',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 16 * scale),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _records.length,
                separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
                itemBuilder: (ctx, i) {
                  final r = _records[i];
                  return _RecordTile(
                    record: r,
                    scale: scale,
                    onEdit: r.isRest ? null : () => _editRecord(r),
                    onDelete: () => _confirmDelete(r),
                  );
                },
              ),

            SizedBox(height: 16 * scale),

            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.mediumGray.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
              ),
              child: Text(
                'Fechar',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 13 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Tile individual de registro
// =============================================================================

class _RecordTile extends StatelessWidget {
  const _RecordTile({
    required this.record,
    required this.scale,
    required this.onDelete,
    this.onEdit,
  });

  final TodayRecord record;
  final double scale;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  Color get _effortColor {
    if (record.effort < 5) return const Color(0xFF224DFF);
    if (record.effort == 5) return AppColors.mediumGray;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 10 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.mediumGray.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Row(
        children: [
          // Ícone do tipo
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: AppColors.baseBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: Icon(
              record.isRest
                  ? Icons.bedtime_outlined
                  : record.isOtherActivity
                  ? Icons.directions_run
                  : Icons.fitness_center,
              size: 18 * scale,
              color: AppColors.baseBlue,
            ),
          ),
          SizedBox(width: 10 * scale),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.displayName,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 13 * scale,
                    color: AppColors.darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (record.trainingTime.isNotEmpty) ...[
                  SizedBox(height: 2 * scale),
                  Text(
                    record.trainingTime,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 11 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
                if (!record.isRest) ...[
                  SizedBox(height: 4 * scale),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4 * scale),
                          child: LinearProgressIndicator(
                            value: record.effort / 10,
                            minHeight: 4 * scale,
                            backgroundColor:
                                AppColors.mediumGray.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _effortColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Text(
                        '${record.effort}/10',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 10 * scale,
                          fontWeight: AppFontWeight.bold,
                          color: _effortColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: 8 * scale),

          // Botões ação
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onEdit != null)
                _ActionBtn(
                  icon: Icons.edit_outlined,
                  color: AppColors.baseBlue,
                  scale: scale,
                  onTap: onEdit!,
                ),
              SizedBox(height: 4 * scale),
              _ActionBtn(
                icon: Icons.delete_outline,
                color: Colors.red,
                scale: scale,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.scale,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(5 * scale),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6 * scale),
        ),
        child: Icon(icon, size: 16 * scale, color: color),
      ),
    );
  }
}
