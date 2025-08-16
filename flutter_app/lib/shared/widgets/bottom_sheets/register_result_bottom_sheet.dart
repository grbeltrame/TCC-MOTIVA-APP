// lib/shared/widgets/register_result/register_result_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/movement_service.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';

// sections & helpers
import 'package:flutter_app/shared/widgets/register_result/section_results.dart';
import 'package:flutter_app/shared/widgets/register_result/section_adaptations.dart';
import 'package:flutter_app/shared/widgets/register_result/movements.dart';
import 'package:flutter_app/shared/widgets/register_result/section_effort.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';

Future<void> showRegisterResultBottomSheet(BuildContext context) {
  // Abre o sheet imediatamente — conteúdo carrega por dentro.
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _RegisterResultSheetContent(),
  );
}

class _RegisterResultSheetContent extends StatefulWidget {
  const _RegisterResultSheetContent({Key? key}) : super(key: key);

  @override
  State<_RegisterResultSheetContent> createState() =>
      _RegisterResultSheetContentState();
}

class _RegisterResultSheetContentState
    extends State<_RegisterResultSheetContent> {
  // --- loading / dados ---
  bool _loading = true;
  _FormData? _data;

  // --- estado de formulário ---
  String? _selectedCategory;
  String? _selectedAdapted; // 'Sim' | 'Não'
  String? _selectedCompleted; // 'Sim' | 'Não'
  String? _selectedClassId;
  String? _selectedWodType;

  int? _amrapRounds;
  int? _amrapReps;
  int? _forTimeSeconds;

  final EffortService _effortService = EffortService();
  int _effortValue = 5; // 1..10, atualizado pela SectionEffort

  String? _movementsForClassId;
  final List<MovementRowData> _movementRows = [];

  @override
  void initState() {
    super.initState();
    _startLoad(); // dispara o carregamento sem bloquear a abertura do sheet
  }

  @override
  void dispose() {
    for (final r in _movementRows) r.dispose();
    super.dispose();
  }

  Future<void> _startLoad() async {
    // carrega tudo em paralelo
    final catsF = WorkoutResultService.fetchUserCategories();
    final defCatF = WorkoutResultService.fetchDefaultUserCategory();
    final classesF = WorkoutResultService.fetchClassesForDate(DateTime.now());
    final wodTypesF = WorkoutResultService.fetchWorkoutTypes();

    final cats = await catsF;
    final defCat = await defCatF;
    final classes = await classesF;
    final wodTypes = await wodTypesF;

    // estados iniciais
    _selectedCategory = defCat;
    _selectedAdapted = 'Não';
    _selectedCompleted = 'Sim';
    _selectedClassId = classes.isNotEmpty ? classes.first.id : null;
    _selectedWodType = wodTypes.isNotEmpty ? wodTypes.first : null;

    // Pré-carrega movimentos da turma default (se houver)
    final presets =
        _selectedClassId != null
            ? await WorkoutResultService.fetchMovementsForClass(
              _selectedClassId!,
            )
            : <MovementPreset>[];
    _applyMovementPresets(_selectedClassId, presets);

    _data = _FormData(
      categories: cats,
      defaultCategory: defCat,
      classes: classes,
      wodTypes: wodTypes,
    );

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _applyMovementPresets(String? classId, List<MovementPreset> presets) {
    for (final r in _movementRows) r.dispose();
    _movementRows.clear();
    _movementsForClassId = classId;
    for (final p in presets) {
      _movementRows.add(MovementRowData.fromPreset(p));
    }
  }

  Future<void> _reloadMovementsForClass(String classId) async {
    final presets = await WorkoutResultService.fetchMovementsForClass(classId);
    if (!mounted) return;
    setState(() => _applyMovementPresets(classId, presets));
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
      suffixText: suffixText, // 'kg' e 's' permanecem visíveis
      contentPadding: EdgeInsets.symmetric(
        horizontal: 3 * scale,
        vertical: 4 * scale,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6 * scale),
        borderSide: BorderSide(color: AppColors.mediumGray.withOpacity(.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6 * scale),
        borderSide: BorderSide(color: AppColors.mediumGray.withOpacity(.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6 * scale),
        borderSide: BorderSide(
          color: AppColors.mediumGray.withOpacity(.9),
          width: 1,
        ),
      ),
    );
  }

  Future<void> _handleRegisterPressed(BuildContext sheetContext) async {
    await _effortService.submitEffort(
      effort: _effortValue,
      classId: _selectedClassId,
      date: DateTime.now(),
    );

    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
    }
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

    return AppBottomSheet(
      child: Padding(
        padding: contentPad,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
            Text(
              'Vamos registrar seu resultado?',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 20 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 10 * scale),

            // === Section: resultados (ou skeleton enquanto carrega)
            if (_loading)
              _ResultsSkeleton(scale: scale)
            else
              SectionResults(
                categories: _data!.categories,
                selectedCategory: _selectedCategory,
                onChangedCategory: (v) => setState(() => _selectedCategory = v),

                selectedAdapted: _selectedAdapted,
                onChangedAdapted: (v) => setState(() => _selectedAdapted = v),

                selectedCompleted: _selectedCompleted,
                onChangedCompleted:
                    (v) => setState(() => _selectedCompleted = v),

                classes: _data!.classes,
                selectedClassId: _selectedClassId,
                onChangedClass: (v) async {
                  setState(() => _selectedClassId = v);
                  if (v != null) await _reloadMovementsForClass(v);
                },

                wodTypes: _data!.wodTypes,
                selectedWodType: _selectedWodType,
                onChangedWodType: (v) => setState(() => _selectedWodType = v),

                amrapRounds: _amrapRounds,
                amrapReps: _amrapReps,
                onChangedAmrapRounds:
                    (val) => setState(() => _amrapRounds = val),
                onChangedAmrapReps: (val) => setState(() => _amrapReps = val),

                forTimeSeconds: _forTimeSeconds,
                onChangedForTime:
                    (val) => setState(() => _forTimeSeconds = val),
              ),

            SizedBox(height: 10 * scale),

            // === Section: adaptações (ou skeleton)
            if (_loading)
              _AdaptationsSkeleton(scale: scale)
            else
              SectionAdaptations(
                visible: _selectedAdapted == 'Sim',
                movementRows: _movementRows,
                inputDecorationBuilder: _inputDecoration,
              ),

            SizedBox(height: 8 * scale),

            const Divider(height: 24),

            // === Section: Esforço (pode abrir já visível; não depende do load)
            SectionEffort(
              classId: _selectedClassId,
              onEffortChanged: (val) => _effortValue = val,
            ),

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

class _FormData {
  final List<String> categories;
  final String defaultCategory;
  final List<ClassSlot> classes;
  final List<String> wodTypes;

  _FormData({
    required this.categories,
    required this.defaultCategory,
    required this.classes,
    required this.wodTypes,
  });
}

/// Skeletons simples (cinza) para abrir o sheet instantaneamente, sem flicker.
class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton({required this.scale});
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
        _bar(36),
        SizedBox(height: 8 * scale),
        _bar(36),
        SizedBox(height: 8 * scale),
        _bar(36),
        SizedBox(height: 8 * scale),
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
