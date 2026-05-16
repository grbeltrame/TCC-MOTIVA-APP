// lib/shared/widgets/register_result/register_result_bottom_sheet.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/constants/app_box.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/shared/widgets/register_result/section_adaptations.dart';
import 'package:flutter_app/shared/widgets/register_result/section_effort.dart';
import 'package:flutter_app/shared/widgets/register_result/movements.dart';
import 'package:flutter_app/shared/widgets/dialogs/activity_status_dialogs.dart';
import 'package:intl/intl.dart';

// =============================================================================
// Função pública de abertura
// =============================================================================

Future<void> showRegisterResultBottomSheet(
  BuildContext context, {
  AthleteResultRecord? existingRecord,
  DateTime? initialDate,
  bool hasExistingRecords = false,
  BuildContext? parentContext,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (sheetCtx) => _RegisterResultSheetContent(
          existingRecord: existingRecord,
          initialDate: initialDate,
          hasExistingRecords: hasExistingRecords,
          parentContext: parentContext ?? context,
        ),
  );
}

// =============================================================================
// Partes de suporte ignoradas na detecção do tipo principal
// =============================================================================

const _kSupportParts = {
  'WARM UP',
  'WARMUP',
  'EXTRA TRAINING',
  'EXTRA',
  'MOBILIDADE',
  'MOBILITY',
  'SKILL',
};

// =============================================================================
// Etapas do sheet
// =============================================================================

enum _SheetStep { selectTraining, fillForm }

// =============================================================================
// Widget principal
// =============================================================================

class _RegisterResultSheetContent extends StatefulWidget {
  const _RegisterResultSheetContent({
    Key? key,
    this.existingRecord,
    this.initialDate,
    this.hasExistingRecords = false,
    this.parentContext,
  }) : super(key: key);

  final AthleteResultRecord? existingRecord;

  /// Data pré-selecionada ao abrir o sheet (ex: data do seletor da tela).
  /// Se null, usa DateTime.now().
  final DateTime? initialDate;

  /// Indica se já existem registros hoje (esconde "Não treinei" se true).
  final bool hasExistingRecords;

  /// Contexto da tela pai — usado para abrir dialogs fora do sheet.
  final BuildContext? parentContext;

  @override
  State<_RegisterResultSheetContent> createState() =>
      _RegisterResultSheetContentState();
}

class _RegisterResultSheetContentState
    extends State<_RegisterResultSheetContent> {
  // ── Etapa atual ─────────────────────────────────────────────────────────────
  _SheetStep _step = _SheetStep.selectTraining;

  // ── Data selecionada — usa initialDate se fornecido, senão hoje ─────────────
  late DateTime _selectedDate;

  // ── Treinos disponíveis para a data ──────────────────────────────────────────
  bool _loadingTrainings = false;
  List<Training> _trainings = [];

  // ── Treino selecionado ───────────────────────────────────────────────────────
  String? _wodType;
  String? _wodName;
  String? _modalidade;
  List<String> _keyMetrics = [];
  String? _trainingDocId;
  String? _dayOfWeek;

  // ── Campos do formulário ─────────────────────────────────────────────────────
  String? _selectedCategory;
  String? _selectedAdapted;
  String? _selectedCompleted;
  TimeOfDay? _trainingTime;

  // Resultado condicional
  int? _forTimeSeconds;
  int? _maxForTimeSeconds;
  int? _amrapRounds;
  int? _amrapReps;
  bool _emomCompleted = true;
  int? _emomCompletedRounds;

  // Esforço
  int _effortValue = 5;

  // Adaptações
  final List<MovementRowData> _movementRows = [];
  List<String> _categories = ['Iniciante', 'Scale', 'Intermediário', 'RX'];

  @override
  void initState() {
    super.initState();
    // Inicializa a data — usa initialDate se fornecido, senão hoje
    _selectedDate = widget.initialDate ?? DateTime.now();

    final rec = widget.existingRecord;
    if (rec != null) {
      // ── Modo edição: pré-popula todos os campos e vai direto ao formulário
      _step = _SheetStep.fillForm;
      _wodType = rec.wodType;
      _wodName = rec.wodName;
      _modalidade = rec.modalidade;
      _keyMetrics = rec.keyMetrics;
      _trainingDocId = rec.trainingDocId;
      _dayOfWeek = rec.dayOfWeek;
      _selectedCategory = rec.category;
      _selectedAdapted = rec.adapted ? 'Sim' : 'Não';
      _selectedCompleted = rec.completed ? 'Sim' : 'Não';
      _effortValue = rec.effort;
      _forTimeSeconds = rec.forTimeSec;
      _amrapRounds = rec.amrapRounds;
      _amrapReps = rec.amrapReps;
      _emomCompleted = rec.emomCompletedRounds == null;
      _emomCompletedRounds = rec.emomCompletedRounds;

      // Parseia trainingTime "06:30" → TimeOfDay
      if (rec.trainingTime.isNotEmpty && rec.trainingTime.contains(':')) {
        final parts = rec.trainingTime.split(':');
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null) {
          _trainingTime = TimeOfDay(hour: h, minute: m);
        }
      }

      // Parseia a data do registro
      try {
        _selectedDate = DateTime.parse(rec.date);
      } catch (_) {}
    }
    // Adia os loads para após o primeiro build — evita setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTrainings();
        _loadCategories();
      }
    });
  }

  @override
  void dispose() {
    for (final r in _movementRows) r.dispose();
    super.dispose();
  }

  // ── Carregamentos ────────────────────────────────────────────────────────────

  Future<void> _loadTrainings() async {
    _loadingTrainings = true;
    try {
      final list = await TrainingService.fetchTrainingsListForDate(
        boxId: AppBox.id,
        date: _selectedDate,
      );
      if (mounted) setState(() => _trainings = list);
    } finally {
      if (mounted) setState(() => _loadingTrainings = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await WorkoutResultService.fetchUserCategories();
      // Só sobrescreve a categoria se não estiver em modo edição
      final defCat =
          _selectedCategory ??
          await WorkoutResultService.fetchDefaultUserCategory();
      if (mounted) {
        setState(() {
          _categories = cats;
          _selectedCategory = defCat;
        });
      }
    } catch (_) {}
  }

  // ── Seleção de data ──────────────────────────────────────────────────────────

  Future<void> _pickOtherDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked == null) return;
    setState(() {
      _selectedDate = picked;
      _trainings = [];
    });
    await _loadTrainings();
  }

  // ── Seleção de treino ────────────────────────────────────────────────────────

  String _detectType(Map<String, dynamic> partes) {
    final keys = partes.keys.map((k) => k.toUpperCase()).toSet();
    if (keys.contains('LPO')) return 'LPO';
    if (keys.any((k) => k.contains('GINASTIC') || k.contains('GYMNAST'))) {
      return 'Ginástica';
    }
    if (keys.any(
      (k) => k.contains('ENDUR') || k.contains('RUNNING') || k.contains('RUN'),
    )) {
      return 'Endurance';
    }
    if (keys.contains('WOD')) return 'WOD';
    final main = partes.keys.firstWhere(
      (k) => !_kSupportParts.contains(k.toUpperCase()),
      orElse: () => partes.keys.first,
    );
    return main.toUpperCase();
  }

  void _onTrainingSelected(Training training) {
    final type = _detectType(training.partes);

    // Encontra a parte principal
    final mainKey = training.partes.keys.firstWhere(
      (k) => !_kSupportParts.contains(k.toUpperCase()),
      orElse: () => training.partes.keys.first,
    );
    final mainPart = training.partes[mainKey] as Map<String, dynamic>?;

    final wodName = mainPart?['nomeWod']?.toString().trim();
    final modalidade = mainPart?['modalidade']?.toString().trim().toUpperCase();
    final duracaoMinutos = mainPart?['duracaoMinutos'] as int?;

    setState(() {
      _wodType = type;
      _wodName = (wodName != null && wodName.isNotEmpty) ? wodName : null;
      _modalidade = modalidade;
      _maxForTimeSeconds = duracaoMinutos != null ? duracaoMinutos * 60 : null;
      _keyMetrics = training.analysis?.keyMetrics ?? [];
      _trainingDocId = training.id;
      _dayOfWeek = null; // será preenchido abaixo se disponível

      // Reset campos condicionais ao trocar de treino
      _forTimeSeconds = null;
      _amrapRounds = null;
      _amrapReps = null;
      _emomCompleted = true;
      _emomCompletedRounds = null;

      _step = _SheetStep.fillForm;
    });
  }

  // ── Seleção de horário ───────────────────────────────────────────────────────

  Future<void> _pickTrainingTime() async {
    final initial = _trainingTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      initialEntryMode: TimePickerEntryMode.input,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _trainingTime = picked);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  // ── Monta lista de categorias garantindo que o valor atual está presente ──────
  // Evita crash do DropdownButton quando _selectedCategory não está em _categories
  List<String> _buildCategoryItems() {
    final base =
        _categories.isNotEmpty
            ? _categories
            : ['Iniciante', 'Scale', 'Intermediário', 'RX'];
    if (_selectedCategory != null && !base.contains(_selectedCategory)) {
      return [...base, _selectedCategory!];
    }
    return base;
  }

  // ── InputDecoration padrão ───────────────────────────────────────────────────

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

  // ── Submissão ────────────────────────────────────────────────────────────────

  Future<void> _handleRegisterPressed(BuildContext sheetContext) async {
    // Validação mínima
    if (_trainingTime == null) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Informe o horário que você treinou')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        sheetContext,
      ).showSnackBar(const SnackBar(content: Text('Selecione sua categoria')));
      return;
    }

    // Adaptações
    final adaptations =
        _selectedAdapted == 'Sim'
            ? _movementRows
                .map(
                  (r) => {
                    'movement': r.movement,
                    'qty': r.qty,
                    'loadKg': r.loadKg,
                    'timeSec': r.timeSec,
                  },
                )
                .toList()
            : <Map<String, dynamic>>[];

    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final record = AthleteResultRecord(
      date: dateKey,
      wodType: _wodType ?? 'WOD',
      wodName: _wodName,
      modalidade: _modalidade,
      keyMetrics: _keyMetrics,
      trainingDocId: _trainingDocId,
      trainingTime: _formatTime(_trainingTime!),
      category: _selectedCategory!,
      adapted: _selectedAdapted == 'Sim',
      completed: _selectedCompleted == 'Sim',
      forTimeSec: _modalidade == 'FOR TIME' ? _forTimeSeconds : null,
      amrapRounds: _modalidade == 'AMRAP' ? _amrapRounds : null,
      amrapReps: _modalidade == 'AMRAP' ? _amrapReps : null,
      emomCompletedRounds:
          (_modalidade == 'EMOM' && !_emomCompleted)
              ? _emomCompletedRounds
              : null,
      effort: _effortValue,
      adaptations: adaptations,
      dayOfWeek: _dayOfWeek,
    );

    try {
      await EffortService.submitResult(record);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          sheetContext,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
      return;
    }

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

  // ── BUILD ────────────────────────────────────────────────────────────────────

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

            // Conteúdo por etapa
            if (_step == _SheetStep.selectTraining)
              _buildSelectTrainingStep(scale)
            else
              _buildFillFormStep(scale),
          ],
        ),
      ),
    );
  }

  // ── ETAPA 1: Selecionar treino ───────────────────────────────────────────────

  Widget _buildSelectTrainingStep(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Vamos registrar seu resultado?',
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
            fontSize: 20 * scale,
            color: AppColors.darkText,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          DateFormat("d 'de' MMMM", 'pt_BR').format(_selectedDate),
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 12 * scale,
            color: AppColors.mediumGray,
          ),
        ),
        SizedBox(height: 24 * scale),

        // Lista de treinos ou skeleton
        if (_loadingTrainings)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32 * scale),
              child: const CircularProgressIndicator(),
            ),
          )
        else if (_trainings.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32 * scale),
              child: Text(
                'Nenhum treino encontrado para esta data',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 14 * scale,
                  color: AppColors.mediumGray,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._trainings.map((t) {
            final type = _detectType(t.partes);
            final mainKey = t.partes.keys.firstWhere(
              (k) => !_kSupportParts.contains(k.toUpperCase()),
              orElse: () => t.partes.keys.first,
            );
            final mainPart = t.partes[mainKey] as Map<String, dynamic>?;
            final name = mainPart?['nomeWod']?.toString().trim() ?? '';
            final label = name.isNotEmpty ? '$type — $name' : type;

            return Padding(
              padding: EdgeInsets.only(bottom: 10 * scale),
              child: OutlinedButton(
                onPressed: () => _onTrainingSelected(t),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48 * scale),
                  side: BorderSide(color: AppColors.baseBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  backgroundColor: AppColors.baseBlue.withOpacity(0.05),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 15 * scale,
                    color: AppColors.baseBlue,
                  ),
                ),
              ),
            );
          }),

        // Link "Outro dia"
        Center(
          child: TextButton.icon(
            onPressed: _pickOtherDate,
            icon: Icon(
              Icons.calendar_today,
              size: 14 * scale,
              color: AppColors.mediumGray,
            ),
            label: Text(
              'Registrar treino de outro dia',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ),
        ),

        Divider(color: AppColors.mediumGray.withValues(alpha: 0.2), height: 1),
        SizedBox(height: 12 * scale),

        // Botões: Não treinei (só se não há registros) + Outra atividade
        Row(
          children: [
            if (!widget.hasExistingRecords) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ctx = widget.parentContext ?? context;
                    Navigator.of(context).pop();
                    await showDidNotTrainDialog(ctx, date: _selectedDate);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.lightMagenta.withAlpha(50),
                    side: BorderSide(color: AppColors.baseMagenta),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8 * scale),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Não treinei hoje',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      color: AppColors.baseMagenta,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
            ],
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final ctx = widget.parentContext ?? context;
                  Navigator.of(context).pop();
                  await showOtherActivityDialog(ctx, date: _selectedDate);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppColors.baseBlue.withAlpha(50),
                  side: BorderSide(color: AppColors.baseBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 8 * scale),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Outra atividade',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    color: AppColors.baseBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * scale),
      ],
    );
  }

  // ── ETAPA 2: Preencher formulário ────────────────────────────────────────────

  Widget _buildFillFormStep(double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header com botão voltar
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _step = _SheetStep.selectTraining),
              child: Icon(
                Icons.arrow_back_ios,
                size: 16 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Text(
                _wodName != null
                    ? '$_wodType — $_wodName'
                    : (_wodType ?? 'Treino'),
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 18 * scale,
                  color: AppColors.darkText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),

        // Chip de modalidade (read-only)
        if (_modalidade != null) ...[
          _ModalidadeChip(label: _modalidade!, scale: scale),
          SizedBox(height: 12 * scale),
        ],

        // Linha 1: Categoria + Adaptado
        Wrap(
          spacing: 12 * scale,
          runSpacing: 6 * scale,
          children: [
            _LabeledDropdown(
              label: 'Categoria:',
              value: _selectedCategory,
              // Garante que o valor selecionado sempre está na lista —
              // evita crash quando categories ainda carregando mas
              // _selectedCategory já tem valor do registro salvo
              items: _buildCategoryItems(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              scale: scale,
            ),
            _LabeledDropdown(
              label: 'Adaptado?:',
              value: _selectedAdapted ?? 'Não',
              items: const ['Sim', 'Não'],
              onChanged: (v) => setState(() => _selectedAdapted = v),
              scale: scale,
            ),
          ],
        ),

        // Linha 2: Concluiu + resultado condicional
        _buildConditionalResultRow(scale),

        SizedBox(height: 6 * scale),

        // Horário do treino
        _buildTrainingTimePicker(scale),

        SizedBox(height: 10 * scale),

        // Adaptações
        SectionAdaptations(
          visible: _selectedAdapted == 'Sim',
          movementRows: _movementRows,
          inputDecorationBuilder: _inputDecoration,
        ),

        const Divider(height: 24),

        // Esforço
        SectionEffort(
          classId: null,
          initialEffort: _effortValue,
          onEffortChanged: (val) => setState(() => _effortValue = val),
        ),

        SizedBox(height: 16 * scale),

        // Botão primário — largura total, ação principal
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: AppTheme.secondaryButtonStyle(
              AppColors.darkBlue,
              AppColors.baseBlue,
            ),
            onPressed: () => _handleRegisterPressed(context),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4 * scale),
              child: const Text('Registrar resultado'),
            ),
          ),
        ),

        // Botão secundário — link de texto, ação destrutiva menor
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Fechar',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ),
        ),

        SizedBox(height: 8 * scale),
      ],
    );
  }

  // ── Resultado condicional por modalidade ─────────────────────────────────────

  bool get _isForTimeLike =>
      _modalidade == 'FOR TIME' || _modalidade == 'ROUNDS FOR TIME';

  Widget _buildConditionalResultRow(double scale) {
    if (_isForTimeLike) {
      final didNotComplete = (_selectedCompleted ?? 'Sim') == 'Não';
      // When "não concluiu" and cap is known, time is locked to the cap.
      final timeLocked = didNotComplete && _maxForTimeSeconds != null;

      return Wrap(
        spacing: 12 * scale,
        runSpacing: 6 * scale,
        children: [
          _LabeledDropdown(
            label: 'Concluiu?:',
            value: _selectedCompleted ?? 'Sim',
            items: const ['Sim', 'Não'],
            onChanged: (v) {
              setState(() {
                _selectedCompleted = v;
                if (v == 'Não' && _maxForTimeSeconds != null) {
                  // Auto-fill cap time when athlete didn't finish
                  _forTimeSeconds = _maxForTimeSeconds;
                } else if (v == 'Sim' &&
                    _forTimeSeconds == _maxForTimeSeconds) {
                  // Clear the auto-filled cap so athlete enters their real time
                  _forTimeSeconds = null;
                }
              });
            },
            scale: scale,
          ),
          if (timeLocked)
            _CapTimeChip(
              label: 'Tempo (cap):',
              seconds: _maxForTimeSeconds!,
              scale: scale,
            )
          else
            _LabeledTimePicker(
              label: 'Seu tempo:',
              seconds: _forTimeSeconds,
              maxSeconds: _maxForTimeSeconds,
              onChanged: (v) => setState(() => _forTimeSeconds = v),
              scale: scale,
            ),
        ],
      );
    }

    if (_modalidade == 'AMRAP') {
      return Wrap(
        spacing: 12 * scale,
        runSpacing: 6 * scale,
        children: [
          _LabeledInputInt(
            label: 'Rounds:',
            value: _amrapRounds,
            onChanged: (v) => setState(() => _amrapRounds = v),
            scale: scale,
            inputDecoration: _inputDecoration,
          ),
          _LabeledInputInt(
            label: 'Reps:',
            value: _amrapReps,
            onChanged: (v) => setState(() => _amrapReps = v),
            scale: scale,
            inputDecoration: _inputDecoration,
          ),
        ],
      );
    }

    if (_modalidade == 'EMOM') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabeledDropdown(
            label: 'Completou todos os rounds?:',
            value: _emomCompleted ? 'Sim' : 'Não',
            items: const ['Sim', 'Não'],
            onChanged: (v) => setState(() => _emomCompleted = v == 'Sim'),
            scale: scale,
          ),
          if (!_emomCompleted) ...[
            SizedBox(height: 6 * scale),
            _LabeledInputInt(
              label: 'Quantos minutos completou?:',
              value: _emomCompletedRounds,
              onChanged: (v) => setState(() => _emomCompletedRounds = v),
              scale: scale,
              inputDecoration: _inputDecoration,
            ),
          ],
        ],
      );
    }

    // Modalidade desconhecida ou nula — mostra só Concluiu
    return _LabeledDropdown(
      label: 'Concluiu?:',
      value: _selectedCompleted ?? 'Sim',
      items: const ['Sim', 'Não'],
      onChanged: (v) => setState(() => _selectedCompleted = v),
      scale: scale,
    );
  }

  // ── Time picker de horário do treino ─────────────────────────────────────────

  Widget _buildTrainingTimePicker(double scale) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Que horas treinou?:',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          SizedBox(width: 8 * scale),
          GestureDetector(
            onTap: _pickTrainingTime,
            child: Container(
              clipBehavior: Clip.antiAlias,
              padding: EdgeInsets.symmetric(
                horizontal: 8 * scale,
                vertical: 6 * scale,
              ),
              decoration: BoxDecoration(
                color: AppColors.baseBlue.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6 * scale),
                border: Border.all(
                  color: AppColors.baseBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _trainingTime != null ? _formatTime(_trainingTime!) : '--:--',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 13 * scale,
                  fontWeight: AppFontWeight.medium,
                  color:
                      _trainingTime != null
                          ? AppColors.darkText
                          : AppColors.mediumGray,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Widgets auxiliares internos
// =============================================================================

class _ModalidadeChip extends StatelessWidget {
  final String label;
  final double scale;
  const _ModalidadeChip({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 4 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.baseBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: AppColors.baseBlue.withOpacity(0.25),
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

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final double scale;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label à esquerda
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          SizedBox(width: 8 * scale),
          // Dropdown à direita com cara de botão
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.baseBlue.withOpacity(0.04),
              borderRadius: BorderRadius.circular(6 * scale),
              border: Border.all(
                color: AppColors.baseBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isDense: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.baseBlue,
                  size: 16 * scale,
                ),
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 13 * scale,
                  color: AppColors.darkText,
                  fontWeight: AppFontWeight.medium,
                ),
                underline: const SizedBox.shrink(),
                selectedItemBuilder:
                    (context) =>
                        items
                            .map(
                              (it) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8 * scale,
                                  vertical: 4 * scale,
                                ),
                                child: Text(
                                  it,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontSize: 13 * scale,
                                    color: AppColors.darkText,
                                    fontWeight: AppFontWeight.medium,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                items:
                    items
                        .map(
                          (it) => DropdownMenuItem(
                            value: it,
                            child: Text(
                              it,
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: 13 * scale,
                                color: AppColors.darkText,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: onChanged,
                borderRadius: BorderRadius.circular(6 * scale),
                dropdownColor: Colors.white,
                menuMaxHeight: 200 * scale,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledInputInt extends StatefulWidget {
  final String label;
  final int? value;
  final ValueChanged<int?>? onChanged;
  final double scale;
  final InputDecoration Function(
    BuildContext, {
    String? suffixText,
    String? hintText,
  })
  inputDecoration;

  const _LabeledInputInt({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.scale,
    required this.inputDecoration,
  });

  @override
  State<_LabeledInputInt> createState() => _LabeledInputIntState();
}

class _LabeledInputIntState extends State<_LabeledInputInt> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value?.toString() ?? '');
  }

  @override
  void didUpdateWidget(covariant _LabeledInputInt oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = widget.value?.toString() ?? '';
    if (_controller.text == nextText) return;

    _controller.value = _controller.value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * widget.scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Label à esquerda — igual ao _LabeledDropdown
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * widget.scale,
              color: AppColors.mediumGray,
            ),
          ),
          SizedBox(width: 8 * widget.scale),
          // Campo com largura fixa — sem isso expande e sobrepõe tudo no Wrap
          SizedBox(
            width: 72 * widget.scale,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.baseBlue.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6 * widget.scale),
                border: Border.all(
                  color: AppColors.baseBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8 * widget.scale),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  filled: false,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged:
                    (t) =>
                        widget.onChanged?.call(t.isEmpty ? null : int.parse(t)),
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 13 * widget.scale,
                  fontWeight: AppFontWeight.medium,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only chip showing the cap time when the athlete didn't complete.
class _CapTimeChip extends StatelessWidget {
  final String label;
  final int seconds;
  final double scale;

  const _CapTimeChip({
    required this.label,
    required this.seconds,
    required this.scale,
  });

  String _fmt(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          SizedBox(width: 8 * scale),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.mediumGray.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6 * scale),
              border: Border.all(
                color: AppColors.mediumGray.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8 * scale,
                vertical: 4 * scale,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _fmt(seconds),
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 13 * scale,
                      fontWeight: AppFontWeight.medium,
                      color: AppColors.mediumGray,
                    ),
                  ),
                  SizedBox(width: 4 * scale),
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledTimePicker extends StatelessWidget {
  final String label;
  final int? seconds;
  final int? maxSeconds; // cap opcional — vem de duracaoMinutos do WOD
  final ValueChanged<int?> onChanged;
  final double scale;

  const _LabeledTimePicker({
    required this.label,
    required this.seconds,
    this.maxSeconds,
    required this.onChanged,
    required this.scale,
  });

  String _fmt(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _pick(BuildContext context) async {
    final currentSec = seconds ?? 0;
    final maxMin = maxSeconds != null ? maxSeconds! ~/ 60 : 99;
    int tempMin = (currentSec ~/ 60).clamp(0, maxMin);
    int tempSec = currentSec % 60;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final s = MediaQuery.of(ctx).size.width / 375.0;
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: SizedBox(
                height: 280 * s,
                child: Column(
                  children: [
                    SizedBox(height: 8 * s),
                    Text(
                      maxSeconds != null
                          ? 'Seu tempo (máx. ${_fmt(maxSeconds!)})'
                          : 'Seu tempo',
                      style: TextStyle(
                        fontFamily: AppFonts.montserrat,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 16 * s,
                        color: AppColors.darkText,
                      ),
                    ),
                    SizedBox(height: 8 * s),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Minutos — limitado ao cap
                          SizedBox(
                            width: 80 * s,
                            child: CupertinoPicker(
                              scrollController: FixedExtentScrollController(
                                initialItem: tempMin,
                              ),
                              itemExtent: 40 * s,
                              onSelectedItemChanged: (i) {
                                setModalState(() {
                                  tempMin = i;
                                  // Se chegou no minuto máximo,
                                  // zera os segundos automaticamente
                                  if (maxSeconds != null && tempMin == maxMin) {
                                    tempSec = 0;
                                  }
                                });
                              },
                              children: List.generate(
                                maxMin + 1,
                                (i) => Center(
                                  child: Text(
                                    i.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
                                      fontSize: 22 * s,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            ':',
                            style: TextStyle(
                              fontSize: 24 * s,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkText,
                            ),
                          ),
                          // Segundos — 00 a 59, ou só 00 se minuto = maxMin
                          SizedBox(
                            width: 80 * s,
                            child: CupertinoPicker(
                              key: ValueKey(tempMin == maxMin),
                              scrollController: FixedExtentScrollController(
                                initialItem:
                                    (maxSeconds != null && tempMin == maxMin)
                                        ? 0
                                        : tempSec,
                              ),
                              itemExtent: 40 * s,
                              onSelectedItemChanged: (i) {
                                setModalState(() => tempSec = i);
                              },
                              children: List.generate(
                                // Se minuto no cap: só mostra 00
                                (maxSeconds != null && tempMin == maxMin)
                                    ? 1
                                    : 60,
                                (i) => Center(
                                  child: Text(
                                    i.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
                                      fontSize: 22 * s,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 10 * s),
                      child: CupertinoButton.filled(
                        onPressed: () {
                          onChanged(tempMin * 60 + tempSec);
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Confirmar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          SizedBox(width: 8 * scale),
          GestureDetector(
            onTap: () => _pick(context),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.baseBlue.withOpacity(0.04),
                borderRadius: BorderRadius.circular(6 * scale),
                border: Border.all(
                  color: AppColors.baseBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      seconds != null ? _fmt(seconds!) : '--:--',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 13 * scale,
                        fontWeight: AppFontWeight.medium,
                        color:
                            seconds != null
                                ? AppColors.darkText
                                : AppColors.mediumGray,
                      ),
                    ),
                    SizedBox(width: 4 * scale),
                    Icon(
                      Icons.access_time_rounded,
                      size: 14 * scale,
                      color: AppColors.baseBlue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
