import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/movement_service.dart';
import 'package:flutter_app/core/services/workout_result_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/register_result/section_effort.dart';

// sections & helpers
import 'package:flutter_app/shared/widgets/register_result/section_results.dart';
import 'package:flutter_app/shared/widgets/register_result/section_adaptations.dart';
import 'package:flutter_app/shared/widgets/register_result/movements.dart';
import 'package:flutter_app/shared/widgets/register_result/section_effort.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/shared/widgets/app_dialog.dart';

Future<void> showRegisterResultBottomSheet(BuildContext context) {
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
  late Future<_FormData> _future;

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

  Future<void> handleRegisterPressed(BuildContext sheetContext) async {
    // 1) Envia pro service (1..10)
    await _effortService.submitEffort(
      effort: _effortValue,
      classId: _selectedClassId,
      date: DateTime.now(),
    );

    // 2) Fecha o bottom sheet (usa o contexto do sheet)
    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
    }

    // 3) Abre o dialog no Navigator raiz (evita confusão com o sheet)
    //    Microtask só pra garantir o próximo frame.
    await Future.microtask(() {});

    await showDialog(
      context: sheetContext, // pode ser o do sheet
      useRootNavigator: true, // <- joga no Navigator raiz
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
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    for (final r in _movementRows) r.dispose();
    super.dispose();
  }

  Future<_FormData> _load() async {
    final cats = await WorkoutResultService.fetchUserCategories();
    final defCat = await WorkoutResultService.fetchDefaultUserCategory();
    final classes = await WorkoutResultService.fetchClassesForDate(
      DateTime.now(),
    );
    final wodTypes = await WorkoutResultService.fetchWorkoutTypes();

    _selectedCategory = defCat;
    _selectedAdapted = 'Não';
    _selectedCompleted = 'Sim';
    _selectedClassId = classes.isNotEmpty ? classes.first.id : null;
    _selectedWodType = wodTypes.isNotEmpty ? wodTypes.first : null;

    // Pré-carrega movimentos conforme a turma (sem o aluno enviar nada).
    final presets =
        _selectedClassId != null
            ? await WorkoutResultService.fetchMovementsForClass(
              _selectedClassId!,
            )
            : <MovementPreset>[];
    _applyMovementPresets(_selectedClassId, presets);

    return _FormData(
      categories: cats,
      defaultCategory: defCat,
      classes: classes,
      wodTypes: wodTypes,
    );
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

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final contentPad = EdgeInsets.fromLTRB(
      16 * scale,
      10 * scale,
      16 * scale,
      16 * scale,
    );

    return FutureBuilder<_FormData>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: EdgeInsets.all(24 * scale),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data!;

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

                // === Section: resultados (labels/dropdowns)
                SectionResults(
                  categories: data.categories,
                  selectedCategory: _selectedCategory,
                  onChangedCategory:
                      (v) => setState(() => _selectedCategory = v),

                  selectedAdapted: _selectedAdapted,
                  onChangedAdapted: (v) => setState(() => _selectedAdapted = v),

                  selectedCompleted: _selectedCompleted,
                  onChangedCompleted:
                      (v) => setState(() => _selectedCompleted = v),

                  classes: data.classes,
                  selectedClassId: _selectedClassId,
                  onChangedClass: (v) async {
                    setState(() => _selectedClassId = v);
                    if (v != null) await _reloadMovementsForClass(v);
                  },

                  wodTypes: data.wodTypes,
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

                // === Section: adaptações (condicional)
                SectionAdaptations(
                  visible: _selectedAdapted == 'Sim',
                  movementRows: _movementRows,
                  inputDecorationBuilder: _inputDecoration,
                ),

                SizedBox(height: 8 * scale),

                // ===== Divisor (sempre visível) =====
                const Divider(height: 24),

                // ===== Section: Esforço =====
                SectionEffort(
                  classId: _selectedClassId,
                  onEffortChanged: (val) => _effortValue = val,
                ),

                //===== Botões no rodapé =====
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
                        onPressed: () => handleRegisterPressed(context),

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
