import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/shared/widgets/create_goal/create_goal_types.dart';
import 'package:flutter_app/shared/widgets/create_goal/section_dates.dart';
import 'package:flutter_app/shared/widgets/create_goal/section_preset.dart';

/// Abre o bottom sheet de cadastro de meta.
Future<void> showCreateGoalBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _CreateGoalBottomSheet(),
  );
}

class _CreateGoalBottomSheet extends StatefulWidget {
  const _CreateGoalBottomSheet({super.key});

  @override
  State<_CreateGoalBottomSheet> createState() => _CreateGoalBottomSheetState();
}

class _CreateGoalBottomSheetState extends State<_CreateGoalBottomSheet> {
  // ------ DATAS --------
  DateTime? _startDate; // Início
  DateTime? _endDate; // Fim
  bool _noDeadline = false; // “Sem prazo”
  String? _errorText; // mensagem de erro (ex.: Fim < Início)

  // ---- NOME DA META (CATEGORIA) ----
  GoalPresetCategory? _selectedPreset; // Frequência | PR

  // Frequência
  String _freqAction = 'Treinar'; // Treinar | Registrar Resultado
  int _freqQty = 1; // mínimo 1
  String _freqPeriod = 'semana'; // semana | mês

  // PR
  String? _prDiscipline; // LPO | Ginástica | Endurance
  String? _prMovement; // depende da disciplina
  final TextEditingController _prTargetCtrl = TextEditingController(); // valor

  // catálogos
  List<String> _lpoMoves = const [];
  List<String> _ginasticaMoves = const [];
  List<String> _enduranceMoves = const [];

  @override
  @override
  void initState() {
    super.initState();
    _bootstrapPrLists();
    _prTargetCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _prTargetCtrl.removeListener(() {});
    _prTargetCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrapPrLists() async {
    final lpo = await GoalService.fetchPrMovements('LPO');
    final gin = await GoalService.fetchPrMovements('Ginástica');
    final end = await GoalService.fetchPrMovements('Endurance');

    List<String> clean(List<String> xs) =>
        xs.map((e) => e.trim()).toSet().toList();

    if (!mounted) return;
    setState(() {
      _lpoMoves = clean(lpo);
      _ginasticaMoves = clean(gin);
      _enduranceMoves = clean(end);
    });
  }

  // ==== Actions ====

  DateTime get _todayNoTime {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickStartDate(BuildContext context) async {
    final firstDate = _todayNoTime; // não pode passado
    final lastDate = DateTime(
      _todayNoTime.year + 5,
      _todayNoTime.month,
      _todayNoTime.day,
    );
    final initial = _startDate ?? _todayNoTime;

    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Selecione a data de início',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && picked.isAfter(_endDate!)) {
          _endDate = null;
          _errorText = 'Atualize a data de fim: ela precisa ser após o início.';
        } else {
          _errorText = null;
        }
      });
    }
  }

  Future<void> _pickEndDate(BuildContext context) async {
    if (_noDeadline) return;
    final firstDate = _startDate ?? _todayNoTime;
    final lastDate = DateTime(
      _todayNoTime.year + 5,
      _todayNoTime.month,
      _todayNoTime.day,
    );
    final initial = _endDate ?? firstDate;

    final picked = await showDatePicker(
      context: context,
      locale: const Locale('pt', 'BR'),
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Selecione a data de fim',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );

    if (picked != null) {
      if (_startDate != null && picked.isBefore(_startDate!)) {
        setState(() => _errorText = 'Fim não pode ser antes do início.');
        return;
      }
      setState(() {
        _endDate = picked;
        _errorText = null;
      });
    }
  }

  String _previewTitle() {
    if (_selectedPreset == null) return '';
    if (_selectedPreset == GoalPresetCategory.frequency) {
      final qty = _freqQty < 1 ? 1 : _freqQty;
      final per = _freqPeriod == 'mês' ? 'por mês' : 'por semana';
      return '$_freqAction $qty $per';
    }
    final d = _prDiscipline?.trim();
    final m = _prMovement?.trim();
    final t = _prTargetCtrl.text.trim();
    if (d == null || d.isEmpty || m == null || m.isEmpty || t.isEmpty)
      return 'PR';
    switch (d) {
      case 'LPO':
        return 'Aumentar o PR de $m em ${t}kg';
      case 'Ginástica':
        return 'Aumentar o volume de $m para $t reps unbroken';
      case 'Endurance':
        return 'Atingir $t $m por minuto';
      default:
        return 'PR $d $m $t';
    }
  }

  Future<void> _handleCreateGoal(BuildContext sheetContext) async {
    // validações
    if (_startDate == null) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Selecione a data de início.')),
      );
      return;
    }
    if (!_noDeadline && _endDate == null) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(
          content: Text('Selecione a data de fim ou ative "Sem prazo".'),
        ),
      );
      return;
    }
    if (_selectedPreset == null) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(
          content: Text('Escolha a categoria da meta (Frequência ou PR).'),
        ),
      );
      return;
    }

    // título + meta
    String title;
    final Map<String, dynamic> meta = {
      'preset': _selectedPreset!.name,
      'noDeadline': _noDeadline,
    };

    if (_selectedPreset == GoalPresetCategory.frequency) {
      final qty = _freqQty < 1 ? 1 : _freqQty;
      title =
          '$_freqAction $qty ${_freqPeriod == 'mês' ? 'por mês' : 'por semana'}';
      meta.addAll({
        'action': _freqAction,
        'quantity': qty,
        'period': _freqPeriod,
      });
    } else {
      final d = _prDiscipline?.trim();
      final m = _prMovement?.trim();
      final t = _prTargetCtrl.text.trim();
      if (d == null || d.isEmpty || m == null || m.isEmpty || t.isEmpty) {
        ScaffoldMessenger.of(sheetContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Finalize a configuração do PR (categoria, movimento e alvo).',
            ),
          ),
        );
        return;
      }
      title = GoalService.generatePrTitle(
        discipline: d,
        movement: m,
        targetValue: t,
        unit: '',
      );
      meta.addAll({'discipline': d, 'movement': m, 'target': t});
    }

    final req = CreateGoalRequest(
      startDate: _startDate!,
      endDate: _noDeadline ? null : _endDate,
      noDeadline: _noDeadline,
      title: title,
      metadata: meta,
    );

    String createdId;
    try {
      createdId = await GoalService.createGoal(req);
    } catch (_) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível cadastrar a meta. Tente novamente.'),
        ),
      );
      return;
    }

    // fecha o sheet e mostra dialog
    if (Navigator.of(sheetContext).canPop()) Navigator.of(sheetContext).pop();
    await Future.microtask(() {});

    await showDialog(
      context: sheetContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AppDialog(
            icon: Icons.check_rounded,
            title: 'Sua meta foi cadastrada.',
            message: 'Agora é hora de agir com foco total e alegria!',
            secondaryAction: TextButton(
              onPressed: () {
                Navigator.of(dialogCtx, rootNavigator: true).pop();
                Navigator.of(dialogCtx, rootNavigator: true).pushNamed(
                  AppRoutes.athleteAllGoals,
                  arguments: {'highlightGoalId': createdId},
                );
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.baseBlue),
              child: const Text('Ver meta'),
            ),
            primaryAction: TextButton(
              onPressed:
                  () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.baseBlue),
              child: const Text('OK'),
            ),
          ),
    );
  }

  // ==== UI ====

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

            // Título fixo
            Text(
              'Você quer cadastrar uma nova meta? Que ótimo!!',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 20 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 12 * scale),

            // ===== Section: Datas
            SectionGoalDates(
              startDate: _startDate,
              endDate: _endDate,
              noDeadline: _noDeadline,
              errorText: _errorText,
              onTapStartDate: () => _pickStartDate(context),
              onTapEndDate: () => _pickEndDate(context),
              onToggleNoDeadline: (sel) {
                setState(() {
                  _noDeadline = sel;
                  _errorText = null;
                  if (_noDeadline) _endDate = null;
                });
              },
            ),

            SizedBox(height: 24 * scale),

            // ===== Section: Preset
            SectionGoalPreset(
              selectedPreset: _selectedPreset,
              onChangedPreset: (v) {
                setState(() {
                  _selectedPreset = v;
                  if (v == GoalPresetCategory.frequency) {
                    _freqAction = 'Treinar';
                    _freqQty = 1;
                    _freqPeriod = 'semana';
                  } else {
                    _prDiscipline = null;
                    _prMovement = null;
                    _prTargetCtrl.clear();
                  }
                });
              },

              // Frequency
              freqAction: _freqAction,
              onChangedFreqAction: (v) => setState(() => _freqAction = v),
              freqQty: _freqQty,
              onChangedFreqQty:
                  (val) => setState(() => _freqQty = val < 1 ? 1 : val),
              freqPeriod: _freqPeriod,
              onChangedFreqPeriod: (v) => setState(() => _freqPeriod = v),

              // PR
              prDiscipline: _prDiscipline,
              onChangedDiscipline: (v) {
                setState(() {
                  _prDiscipline = v;
                  _prMovement = null;
                  _prTargetCtrl.clear();
                });
              },
              prMovement: _prMovement,
              onChangedMovement: (v) => setState(() => _prMovement = v),
              prTargetController: _prTargetCtrl,
              lpoMoves: _lpoMoves,
              gymMoves: _ginasticaMoves,
              enduranceMoves: _enduranceMoves,

              // Preview
              previewTitle: _previewTitle(),
            ),

            // --- Botões no rodapé ---
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
                    onPressed: () => _handleCreateGoal(context),
                    child: const Text('Cadastrar Meta'),
                  ),
                  OutlinedButton(
                    style: AppTheme.tertiaryButtonStyle(AppColors.baseMagenta),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32 * scale),
          ],
        ),
      ),
    );
  }
}
