import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/coach_service.dart';
import 'package:flutter_app/core/services/workout_result_service.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/core/services/movement_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';

import 'package:flutter_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/app_dialog.dart';

import 'package:flutter_app/shared/widgets/register_result/section_results_readonly.dart';
import 'package:flutter_app/shared/widgets/register_result/section_adaptations.dart';
import 'package:flutter_app/shared/widgets/register_result/movements.dart';
import 'package:flutter_app/shared/widgets/register_result/section_effort.dart';

Future<void> showEffortOnlyBottomSheet(
  BuildContext context, {
  required String classId,
  required DateTime trainingDate,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => _EffortOnlyContent(classId: classId, trainingDate: trainingDate),
  );
}

class _EffortOnlyContent extends StatefulWidget {
  const _EffortOnlyContent({required this.classId, required this.trainingDate});
  final String classId;
  final DateTime trainingDate;

  @override
  State<_EffortOnlyContent> createState() => _EffortOnlyContentState();
}

class _EffortOnlyContentState extends State<_EffortOnlyContent> {
  final EffortService _effortService = EffortService();

  late Future<void> _future;

  // Results (read-only)
  String _coachName = '';
  CoachFilledResult? _coachResult;
  String _classLabel = '';

  // Adaptações (editável) — só se adapted == true
  final List<MovementRowData> _movementRows = [];
  bool _showAdaptations = false;

  // Esforço
  int _effortValue = 5;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    for (final r in _movementRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    // Coach
    final coach = await CoachService.fetchCoachForClass(widget.classId);
    _coachName = coach.name;

    // Result preenchido pelo coach
    _coachResult = await WorkoutResultService.fetchCoachFilledResult(
      classId: widget.classId,
      date: widget.trainingDate,
    );

    // Label da turma (busca pelas turmas do dia e casa pelo id)
    final classes = await WorkoutResultService.fetchClassesForDate(
      widget.trainingDate,
    );
    final cls = classes.where((c) => c.id == widget.classId).toList();
    _classLabel = cls.isNotEmpty ? cls.first.label24() : '—';

    // Adaptações: só se Adaptado == Sim
    _showAdaptations = _coachResult?.adapted == true;
    if (_showAdaptations) {
      final presets = await WorkoutResultService.fetchMovementsForClass(
        widget.classId,
      );
      _applyMovementPresets(presets);
    }
  }

  void _applyMovementPresets(List<MovementPreset> presets) {
    for (final r in _movementRows) r.dispose();
    _movementRows.clear();
    for (final p in presets) {
      _movementRows.add(MovementRowData.fromPreset(p));
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    String? suffixText,
    String? hintText,
  }) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      suffixText: suffixText,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 3 * scale,
        vertical: 4 * scale,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6 * scale),
        borderSide: BorderSide(
          color: AppColors.mediumGray.withValues(alpha: 0.6),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6 * scale),
        borderSide: BorderSide(
          color: AppColors.mediumGray.withValues(alpha: 0.6),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6 * scale),
        borderSide: BorderSide(
          color: AppColors.mediumGray.withValues(alpha: 0.9),
          width: 1,
        ),
      ),
    );
  }

  Future<void> _handleRegisterPressed(BuildContext sheetContext) async {
    // 1) Envia adaptações (apenas se a seção estiver visível)
    if (_showAdaptations) {
      final movements =
          _movementRows.map((r) {
            return MovementPreset(
              id: 'tmp', // TODO(back): id real se existir
              name: r.nameController.text,
              expectsQuantity: r.expectsQuantity,
              expectsLoadKg: r.expectsLoadKg,
              expectsTimeSec: r.expectsTimeSec,
              presetQuantity: int.tryParse(r.qtyController.text),
              presetLoadKg: double.tryParse(r.loadController?.text ?? ''),
              presetTimeSec: int.tryParse(r.timeController?.text ?? ''),
            );
          }).toList();

      await WorkoutResultService.submitAdaptationsForTraining(
        classId: widget.classId,
        date: widget.trainingDate,
        movements: movements,
      );
    }

    // 2) Envia esforço 1..10
    await _effortService.submitEffort(
      effort: _effortValue,
      classId: widget.classId,
      date: widget.trainingDate,
    );

    // 3) Fecha o bottom sheet
    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
    }

    // 4) Mostra o mesmo AppDialog do exemplo (Navigator raiz)
    await Future.microtask(() {});
    await showDialog(
      context: sheetContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AppDialog(
            icon: Icons.star_outline,
            title: 'Você está progredindo!',
            message:
                'Cada resultado registrado te deixa mais próximo do seus objetivos.\n\n'
                'Mantenha o foco!',
            primaryAction: TextButton(
              onPressed:
                  () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
              child: const Text('OK'),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final contentPad = EdgeInsets.fromLTRB(
      16 * scale,
      10 * scale,
      16 * scale,
      16 * scale,
    );

    return FutureBuilder<void>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: EdgeInsets.all(24 * scale),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        // segurança
        if (_coachResult == null) {
          return Padding(
            padding: EdgeInsets.all(24 * scale),
            child: Text(
              'Não foi possível carregar os dados do treino.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          );
        }

        return AppBottomSheet(
          child: Padding(
            padding: contentPad,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle
                Center(
                  child: Container(
                    width: 40 * scale,
                    height: 4 * scale,
                    decoration: BoxDecoration(
                      color: AppColors.mediumGray.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2 * scale),
                    ),
                  ),
                ),
                SizedBox(height: 12 * scale),

                // Results (read-only) — mesma organização de linhas
                SectionResultsReadonly(
                  coachName: _coachName,
                  result: _coachResult!,
                  classLabel: _classLabel,
                ),

                SizedBox(height: 10 * scale),

                // Divider antes do próximo bloco (independente de adaptações)
                const Divider(height: 24),

                // Adaptações — só se Adaptado == Sim
                if (_showAdaptations) ...[
                  SectionAdaptations(
                    visible: true,
                    movementRows: _movementRows,
                    inputDecorationBuilder: _inputDecoration,
                  ),
                  SizedBox(height: 10 * scale),
                  const Divider(height: 24),
                ],

                // Esforço sempre
                SectionEffort(
                  classId: widget.classId,
                  onEffortChanged: (val) => _effortValue = val,
                ),

                SizedBox(height: 14 * scale),

                // Botões simples (substitua pelos seus, se já tiver)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24 * scale),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: AppTheme.secondaryButtonStyle(
                          AppColors.darkBlue,
                          AppColors.baseBlue,
                        ),
                        onPressed: () => _handleRegisterPressed(context),

                        child: const Text('Registrar'),
                      ),

                      OutlinedButton(
                        style: AppTheme.tertiaryButtonStyle(
                          AppColors.baseMagenta,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fechar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
