// lib/shared/widgets/register_result/effort_only_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/users/coach/coach_service.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/core/services/workout/movement_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';

import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';

import 'package:flutter_app/shared/widgets/register_result/section_results_readonly.dart';
import 'package:flutter_app/shared/widgets/register_result/section_adaptations.dart';
import 'package:flutter_app/shared/widgets/register_result/movements.dart';
import 'package:flutter_app/shared/widgets/register_result/section_effort.dart';

Future<void> showEffortOnlyBottomSheet(
  BuildContext context, {
  required String classId,
  required DateTime trainingDate,
}) {
  // Abre na hora; conteúdo carrega por dentro com skeletons
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

  // loading state
  bool _loading = true;

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
    _startLoad(); // carrega sem bloquear a abertura do sheet
  }

  @override
  void dispose() {
    for (final r in _movementRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _startLoad() async {
    try {
      // Carrega em paralelo o que dá
      final coachF = CoachService.fetchCoachForClass(widget.classId);
      final filledF = WorkoutResultService.fetchCoachFilledResult(
        classId: widget.classId,
        date: widget.trainingDate,
      );
      final classesF = WorkoutResultService.fetchClassesForDate(
        widget.trainingDate,
      );

      final coach = await coachF;
      final filled = await filledF;
      final classes = await classesF;

      _coachName = coach.name;
      _coachResult = filled;

      final cls = classes.where((c) => c.id == widget.classId).toList();
      _classLabel = cls.isNotEmpty ? cls.first.label24() : '—';

      // Se o coach marcou "adaptado", pre-carrega presets
      _showAdaptations = _coachResult?.adapted == true;
      if (_showAdaptations) {
        final presets = await WorkoutResultService.fetchMovementsForClass(
          widget.classId,
        );
        _applyMovementPresets(presets);
      }
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
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

    // 4) AppDialog no Navigator raiz
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
                'Cada resultado registrado te deixa mais próximo dos seus objetivos.\n\n'
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

            // Results (read-only)
            if (_loading)
              _ResultsReadonlySkeleton(scale: scale)
            else if (_coachResult != null)
              SectionResultsReadonly(
                coachName: _coachName,
                result: _coachResult!,
                classLabel: _classLabel,
              )
            else
              Padding(
                padding: EdgeInsets.only(bottom: 8 * scale),
                child: Text(
                  'Não foi possível carregar os dados do treino.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14 * scale,
                    color: AppColors.darkText,
                  ),
                ),
              ),

            SizedBox(height: 10 * scale),

            const Divider(height: 24),

            // Adaptações — só se Adaptado == Sim
            if (_showAdaptations)
              (_loading
                  ? _AdaptationsSkeleton(scale: scale)
                  : Column(
                    children: [
                      SectionAdaptations(
                        visible: true,
                        movementRows: _movementRows,
                        inputDecorationBuilder: _inputDecoration,
                      ),
                      SizedBox(height: 10 * scale),
                      const Divider(height: 24),
                    ],
                  )),

            // Esforço sempre
            SectionEffort(
              classId: widget.classId,
              onEffortChanged: (val) => _effortValue = val,
            ),

            SizedBox(height: 14 * scale),

            // Botões
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
                    style: AppTheme.tertiaryButtonStyle(AppColors.baseMagenta),
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
  }
}

/// Skeletons para abrir sem travar o sheet
class _ResultsReadonlySkeleton extends StatelessWidget {
  const _ResultsReadonlySkeleton({required this.scale});
  final double scale;

  Widget _bar(double h) => Container(
    height: h * scale,
    decoration: BoxDecoration(
      color: AppColors.lightGray,
      borderRadius: BorderRadius.circular(6 * scale),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _bar(16),
        SizedBox(height: 6 * scale),
        _bar(36),
        SizedBox(height: 6 * scale),
        _bar(36),
      ],
    );
  }
}

class _AdaptationsSkeleton extends StatelessWidget {
  const _AdaptationsSkeleton({required this.scale});
  final double scale;

  Widget _row() => Container(
    height: 40 * scale,
    decoration: BoxDecoration(
      color: AppColors.lightGray,
      borderRadius: BorderRadius.circular(6 * scale),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(children: [_row(), SizedBox(height: 6 * scale), _row()]);
  }
}
