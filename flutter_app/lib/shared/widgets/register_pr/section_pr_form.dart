// lib/shared/widgets/register_pr/section_pr_form.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/pr_service.dart';
// MovementPreset
import 'package:flutter_app/shared/widgets/register_result/movements.dart';
import 'package:flutter_app/shared/widgets/register_result/section_adaptations.dart';

class PrFormValue {
  final PrCategory category;
  final DateTime date;
  final String? movement;
  final double? weightKg;
  final int? reps;
  final PrBenchmark? benchmark;
  final bool adapted;
  final PrWodType? wodType;
  final int? timeSeconds;
  final int? amrapRounds;
  final int? amrapReps;
  final List<AdaptedMovement> adaptations;

  const PrFormValue({
    required this.category,
    required this.date,
    this.movement,
    this.weightKg,
    this.reps,
    this.benchmark,
    required this.adapted,
    this.wodType,
    this.timeSeconds,
    this.amrapRounds,
    this.amrapReps,
    this.adaptations = const [],
  });
}

class SectionPrForm extends StatefulWidget {
  const SectionPrForm({super.key});

  @override
  State<SectionPrForm> createState() => SectionPrFormState();
}

class SectionPrFormState extends State<SectionPrForm> {
  // ====== State principal ======
  PrCategory? _category;
  DateTime _date = DateTime.now();

  // LPO / Ginástica / Endurance
  List<String> _lpo = const [];
  List<String> _gym = const [];
  List<String> _end = const [];

  String? _movement;
  final TextEditingController _weightKgCtrl = TextEditingController();
  final TextEditingController _repsCtrl = TextEditingController();

  // WOD
  List<PrBenchmark> _benchmarks = const [];
  PrBenchmark? _benchmark;
  PrWodType? _wodType;
  bool _adapted = false;

  int? _timeSeconds; // for time
  final TextEditingController _amrapRoundsCtrl = TextEditingController();
  final TextEditingController _amrapRepsCtrl = TextEditingController();

  // Movimentos do WOD para adaptações
  final List<MovementRowData> _adaptRows = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _weightKgCtrl.dispose();
    _repsCtrl.dispose();
    _amrapRoundsCtrl.dispose();
    _amrapRepsCtrl.dispose();
    for (final r in _adaptRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final bmk = await PRService.fetchBenchmarks();
    final lpo = await PRService.fetchMovements(PrCategory.lpo);
    final gym = await PRService.fetchMovements(PrCategory.gym);
    final end = await PRService.fetchMovements(PrCategory.endurance);

    if (!mounted) return;
    setState(() {
      _benchmarks = bmk;
      _lpo = lpo;
      _gym = gym;
      _end = end;
    });
  }

  // ===== Helpers de UI =====

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
        horizontal: 10 * scale,
        vertical: 10 * scale,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * scale),
        borderSide: BorderSide(color: AppColors.mediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * scale),
        borderSide: BorderSide(color: AppColors.mediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * scale),
        borderSide: BorderSide(color: AppColors.baseBlue, width: 1.4),
      ),
    );
  }

  Future<void> _reloadBenchmarkMovements() async {
    if (_category != PrCategory.wod || !_adapted || _benchmark == null) {
      for (final r in _adaptRows) r.dispose();
      _adaptRows.clear();
      if (mounted) setState(() {});
      return;
    }

    final presets = await PRService.fetchBenchmarkMovements(_benchmark!);
    for (final r in _adaptRows) r.dispose();
    _adaptRows
      ..clear()
      ..addAll(presets.map((p) => MovementRowData.fromPreset(p)));
    if (mounted) setState(() {});
  }

  // ===== Validação e value =====
  String? validate() {
    if (_category == null) return 'Escolha a categoria do PR.';

    switch (_category!) {
      case PrCategory.lpo:
        if (_movement == null || _movement!.isEmpty) {
          return 'Escolha o movimento de LPO.';
        }
        final w = double.tryParse(_weightKgCtrl.text.replaceAll(',', '.'));
        if (w == null || w <= 0) return 'Informe o peso (kg).';
        return null;

      case PrCategory.gym:
        if (_movement == null || _movement!.isEmpty) {
          return 'Escolha o movimento de Ginástica.';
        }
        final r = int.tryParse(_repsCtrl.text);
        if (r == null || r <= 0) return 'Informe as repetições.';
        return null;

      case PrCategory.endurance:
        if (_movement == null || _movement!.isEmpty) {
          return 'Escolha o movimento de Endurance.';
        }
        final r2 = int.tryParse(_repsCtrl.text);
        if (r2 == null || r2 <= 0) return 'Informe a quantidade.';
        return null;

      case PrCategory.wod:
        if (_benchmark == null) return 'Escolha o benchmark do WOD.';
        if (!_adapted) {
          if (_wodType == PrWodType.forTime) {
            if (_timeSeconds == null || _timeSeconds! <= 0) {
              return 'Informe o tempo do WOD.';
            }
          } else if (_wodType == PrWodType.amrap) {
            final rd = int.tryParse(_amrapRoundsCtrl.text);
            final rp = int.tryParse(_amrapRepsCtrl.text);
            if (rd == null || rd < 0) return 'Rounds inválidos.';
            if (rp == null || rp < 0) return 'Reps inválidas.';
          }
        }
        return null;
    }
  }

  PrFormValue get value {
    List<AdaptedMovement> adp = [];
    if (_category == PrCategory.wod && _adapted) {
      adp =
          _adaptRows.map((row) {
            final qty = int.tryParse(row.qtyController.text);
            final load = double.tryParse(row.loadController?.text ?? '');
            final time = int.tryParse(row.timeController?.text ?? '');
            return AdaptedMovement(
              name: row.nameController.text,
              quantity: qty,
              loadKg: load,
              timeSec: time,
            );
          }).toList();
    }

    return PrFormValue(
      category: _category!,
      date: _date,
      movement: _movement,
      weightKg: double.tryParse(_weightKgCtrl.text.replaceAll(',', '.')),
      reps: int.tryParse(_repsCtrl.text),
      benchmark: _benchmark,
      adapted: _adapted,
      wodType: _wodType,
      timeSeconds: _timeSeconds,
      amrapRounds: int.tryParse(_amrapRoundsCtrl.text),
      amrapReps: int.tryParse(_amrapRepsCtrl.text),
      adaptations: adp,
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha: Categoria (borderless) + Benchmark (só quando WOD)
        Row(
          children: [
            Expanded(
              child: _BorderlessDropdown<PrCategory>(
                value: _category,
                hint: 'Escolha a categoria do PR',
                items: const [
                  DropdownMenuItem(value: PrCategory.lpo, child: Text('LPO')),
                  DropdownMenuItem(
                    value: PrCategory.gym,
                    child: Text('Ginástica'),
                  ),
                  DropdownMenuItem(
                    value: PrCategory.endurance,
                    child: Text('Endurance'),
                  ),
                  DropdownMenuItem(value: PrCategory.wod, child: Text('WOD')),
                ],
                onChanged: (v) async {
                  setState(() {
                    _category = v;

                    _movement = null;
                    _weightKgCtrl.clear();
                    _repsCtrl.clear();

                    _benchmark = null;
                    _wodType = null;
                    _adapted = false;
                    _timeSeconds = null;
                    _amrapRoundsCtrl.clear();
                    _amrapRepsCtrl.clear();

                    for (final r in _adaptRows) r.dispose();
                    _adaptRows.clear();
                  });

                  if (v == PrCategory.wod && _benchmarks.isNotEmpty) {
                    setState(() {
                      _benchmark = _benchmarks.first;
                      _wodType = _benchmark!.type;
                    });
                  }
                },
              ),
            ),
            if (_category == PrCategory.wod) ...[
              SizedBox(width: 10 * scale),
              Expanded(
                child: _PlainDropdown<PrBenchmark>(
                  value: _benchmark,
                  hintText: 'Benchmark',
                  items:
                      _benchmarks
                          .map(
                            (b) =>
                                DropdownMenuItem(value: b, child: Text(b.name)),
                          )
                          .toList(),
                  onChanged: (v) async {
                    setState(() {
                      _benchmark = v;
                      _wodType = v?.type;
                      _timeSeconds = null;
                      _amrapRoundsCtrl.clear();
                      _amrapRepsCtrl.clear();
                    });
                    await _reloadBenchmarkMovements();
                  },
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 10 * scale),

        // Bloco específico por categoria
        if (_category == PrCategory.lpo) ...[
          Row(
            children: [
              SizedBox(
                width: 80 * scale,
                child: TextField(
                  controller: _weightKgCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: _inputDecoration(context, suffixText: 'kg'),
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14 * scale,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _PlainDropdown<String>(
                  value: _movement,
                  hintText: 'Movimento',
                  items:
                      _lpo
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _movement = v),
                ),
              ),
            ],
          ),
        ] else if (_category == PrCategory.gym) ...[
          Row(
            children: [
              SizedBox(
                width: 80 * scale,
                child: TextField(
                  controller: _repsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(context, suffixText: 'reps'),
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14 * scale,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _PlainDropdown<String>(
                  value: _movement,
                  hintText: 'Movimento',
                  items:
                      _gym
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _movement = v),
                ),
              ),
            ],
          ),
        ] else if (_category == PrCategory.endurance) ...[
          Row(
            children: [
              SizedBox(
                width: 80 * scale,
                child: TextField(
                  controller: _repsCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(context, hintText: ''),
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14 * scale,
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: _PlainDropdown<String>(
                  value: _movement,
                  hintText: 'Movimento',
                  items:
                      _end
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _movement = v),
                ),
              ),
            ],
          ),
        ] else if (_category == PrCategory.wod) ...[
          // Tipo do WOD (informativo; vem do benchmark)
          if (_wodType != null) ...[
            SizedBox(height: 6 * scale),
            Row(
              children: [
                _ChipLabel(text: 'Tipo:'),
                SizedBox(width: 8 * scale),
                Text(
                  _wodType == PrWodType.forTime ? 'For time' : 'AMRAP',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * scale,
                    color: AppColors.darkText,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: 10 * scale),

          // Se NÃO adaptado → campos de resultado simples
          if (!_adapted) ...[
            if (_wodType == PrWodType.forTime)
              _PrDurationField(
                label: 'Tempo',
                seconds: _timeSeconds,
                onChanged: (s) => setState(() => _timeSeconds = s),
                decorationBuilder: _inputDecoration,
              )
            else if (_wodType == PrWodType.amrap)
              Row(
                children: [
                  SizedBox(
                    width: 96 * scale,
                    child: TextField(
                      controller: _amrapRoundsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(
                        context,
                        suffixText: 'rounds',
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 14 * scale,
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  SizedBox(
                    width: 96 * scale,
                    child: TextField(
                      controller: _amrapRepsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _inputDecoration(context, suffixText: 'reps'),
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 14 * scale,
                      ),
                    ),
                  ),
                ],
              ),
          ],

          // Toggle de Adaptações
          SizedBox(height: 10 * scale),
          Align(
            alignment: Alignment.centerLeft,
            child: ChoiceChip(
              label: Text(
                'Adaptações',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 12 * scale,
                  color: _adapted ? AppColors.baseBlue : AppColors.darkBlue,
                ),
              ),
              selected: _adapted,
              selectedColor: AppColors.baseBlue.withValues(alpha: .12),
              shape: const StadiumBorder(
                side: BorderSide(color: Colors.transparent, width: 0),
              ),
              side: BorderSide(color: AppColors.baseBlue),
              onSelected: (sel) async {
                setState(() => _adapted = sel);
                await _reloadBenchmarkMovements();
              },
            ),
          ),

          if (_adapted) ...[
            SizedBox(height: 12 * scale),
            SectionAdaptations(
              visible: true,
              movementRows: _adaptRows,
              inputDecorationBuilder: _inputDecoration,
            ),
          ],
        ],
      ],
    );
  }
}

// ====== Helpers visuais ======

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withAlpha(50),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.bold,
          fontSize: 12 * scale,
          color: AppColors.baseBlue,
        ),
      ),
    );
  }
}

/// Dropdown “sem borda” (texto e seta pretos), igual ao de categoria das metas
class _BorderlessDropdown<T> extends StatelessWidget {
  const _BorderlessDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: Colors.black,
          size: 22 * scale,
        ),
        style: TextStyle(
          color: Colors.black,
          fontFamily: AppFonts.roboto,
          fontSize: 14 * scale,
          fontWeight: FontWeight.bold,
        ),
        hint:
            hint != null
                ? Text(
                  hint!,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: AppFonts.roboto,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                )
                : null,
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

/// Dropdown com borda leve (mesmo look das outras telas)
class _PlainDropdown<T> extends StatelessWidget {
  const _PlainDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.hintText,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: AppColors.mediumGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 20 * scale,
            color: AppColors.darkText,
          ),
          hint:
              hintText != null
                  ? Text(
                    hintText!,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 14 * scale,
                      color: AppColors.mediumGray,
                    ),
                  )
                  : null,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Campo de duração (mm:ss) com picker iOS-like
class _PrDurationField extends StatelessWidget {
  const _PrDurationField({
    required this.label,
    required this.seconds,
    required this.onChanged,
    required this.decorationBuilder,
  });

  final String label;
  final int? seconds;
  final ValueChanged<int?> onChanged;
  final InputDecoration Function(
    BuildContext context, {
    String? suffixText,
    String? hintText,
  })
  decorationBuilder;

  String _fmt(int? s) {
    final total = s ?? 0;
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final ss = (total % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  Future<void> _pick(BuildContext context) async {
    final current = Duration(seconds: seconds ?? 0);
    Duration temp = current;

    await showModalBottomSheet(
      context: context,
      showDragHandle: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final scale = MediaQuery.of(ctx).size.width / 375.0;
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 260 * scale,
            child: Column(
              children: [
                SizedBox(height: 8 * scale),
                Text(
                  'Selecione o tempo',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 16 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.ms,
                    initialTimerDuration: current,
                    onTimerDurationChanged: (d) => temp = d,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 10 * scale),
                  child: CupertinoButton.filled(
                    onPressed: () {
                      onChanged(temp.inSeconds);
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Concluir'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final controller = TextEditingController(
      text: seconds == null ? '' : _fmt(seconds),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * scale,
            vertical: 3 * scale,
          ),
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withAlpha(50),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * scale,
              color: AppColors.baseBlue,
            ),
          ),
        ),
        SizedBox(width: 8 * scale),
        SizedBox(
          width: 96 * scale,
          child: TextField(
            controller: controller,
            readOnly: true,
            decoration: decorationBuilder(context, hintText: '00:00'),
            onTap: () => _pick(context),
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 14 * scale,
              color: AppColors.darkText,
            ),
          ),
        ),
      ],
    );
  }
}
