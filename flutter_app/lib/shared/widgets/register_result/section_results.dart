import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout_result_service.dart';
import 'package:flutter/services.dart';

class SectionResults extends StatelessWidget {
  const SectionResults({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onChangedCategory,
    required this.selectedAdapted,
    required this.onChangedAdapted,
    required this.selectedCompleted,
    required this.onChangedCompleted,
    required this.classes,
    required this.selectedClassId,
    required this.onChangedClass,
    required this.wodTypes,
    required this.selectedWodType,
    required this.onChangedWodType,

    this.amrapRounds,
    this.amrapReps,
    this.onChangedAmrapRounds,
    this.onChangedAmrapReps,
    this.forTimeSeconds,
    this.onChangedForTime,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onChangedCategory;

  final String? selectedAdapted;
  final ValueChanged<String?> onChangedAdapted;

  final String? selectedCompleted;
  final ValueChanged<String?> onChangedCompleted;

  final List<ClassSlot> classes;
  final String? selectedClassId;
  final ValueChanged<String?> onChangedClass;

  final List<String> wodTypes;
  final String? selectedWodType;
  final ValueChanged<String?> onChangedWodType;

  final int? amrapRounds;
  final int? amrapReps;
  final ValueChanged<int?>? onChangedAmrapRounds;
  final ValueChanged<int?>? onChangedAmrapReps;

  /// total em segundos; pode ser 0 (permitido)
  final int? forTimeSeconds;
  final ValueChanged<int?>? onChangedForTime;

  // mesma borda/estética dos inputs da section Adaptações
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

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Linha 1: Categoria + Adaptado
        Wrap(
          spacing: 12 * scale,
          runSpacing: 10 * scale,
          children: [
            _LabeledDropdown<String>(
              label: 'Categoria:',
              value: selectedCategory,
              items: categories,
              onChanged: onChangedCategory,
            ),
            _LabeledDropdown<String>(
              label: 'Adaptado?:',
              value: selectedAdapted,
              items: const ['Sim', 'Não'],
              onChanged: onChangedAdapted,
            ),
          ],
        ),
        SizedBox(height: 4 * scale),

        // Linha 2: Concluiu + Turma
        Wrap(
          spacing: 12 * scale,
          runSpacing: 10 * scale,
          children: [
            _LabeledDropdown<String>(
              label: 'Concluiu?:',
              value: selectedCompleted,
              items: const ['Sim', 'Não'],
              onChanged: onChangedCompleted,
            ),
            _LabeledDropdown<String>(
              label: 'Turma:',
              value: selectedClassId,
              items: classes.map((c) => c.id).toList(),
              itemBuilderText:
                  (id) => classes.firstWhere((c) => c.id == id).label24(),
              onChanged: onChangedClass,
            ),
          ],
        ),
        SizedBox(height: 4 * scale),

        // Linha 3: Tipo (sozinho)
        _LabeledDropdown<String>(
          label: 'Tipo:',
          value: selectedWodType,
          items: wodTypes,
          onChanged: onChangedWodType,
        ),

        // ===== Campos condicionais pelo tipo =====
        if (selectedWodType == 'AMRAP') ...[
          SizedBox(height: 10 * scale),
          // Rounds + Reps (mesma linha, mesma estética de label + caixinha com borda)
          Wrap(
            spacing: 12 * scale,
            runSpacing: 10 * scale,
            children: [
              _LabeledInputInt(
                label: 'Rounds:',
                value: amrapRounds,
                onChanged: onChangedAmrapRounds,
                decorationBuilder: _inputDecoration,
              ),
              _LabeledInputInt(
                label: 'Reps:',
                value: amrapReps,
                onChanged: onChangedAmrapReps,
                decorationBuilder: _inputDecoration,
              ),
            ],
          ),
        ],

        if (selectedWodType == 'For time') ...[
          SizedBox(height: 10 * scale),
          _LabeledDuration(
            label: 'Tempo?:',
            seconds: forTimeSeconds,
            onChangedSeconds: onChangedForTime,
            decorationBuilder: _inputDecoration,
          ),
        ],
      ],
    );
  }
}

class _LabeledDropdown<T> extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.itemBuilderText,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T item)? itemBuilderText;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 4 * scale,
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
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 3 * scale,
              vertical: 2 * scale,
            ),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(6 * scale),
              border: Border.all(color: AppColors.mediumGray.withOpacity(.6)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isDense: true,
                isExpanded: false,
                icon: const SizedBox.shrink(),
                items:
                    items.map((it) {
                      final text =
                          itemBuilderText != null
                              ? itemBuilderText!(it)
                              : it.toString();
                      return DropdownMenuItem<T>(
                        value: it,
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.regular,
                            fontSize: 14 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Input inteiro com chip de label + TextField (borda igual à Adaptações)
class _LabeledInputInt extends StatelessWidget {
  const _LabeledInputInt({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.decorationBuilder,
  });

  final String label;
  final int? value;
  final ValueChanged<int?>? onChanged;
  final InputDecoration Function(
    BuildContext context, {
    String? suffixText,
    String? hintText,
  })
  decorationBuilder;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final controller = TextEditingController(text: value?.toString() ?? '');

    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // chip
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
                color: AppColors.darkBlue,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),

          SizedBox(
            width: 64 * scale,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: decorationBuilder(context),
              onChanged:
                  (txt) => onChanged?.call(txt.isEmpty ? null : int.parse(txt)),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de duração (mm:ss) com chip que abre CupertinoTimerPicker
class _LabeledDuration extends StatelessWidget {
  const _LabeledDuration({
    required this.label,
    required this.seconds,
    required this.onChangedSeconds,
    required this.decorationBuilder,
  });

  final String label;
  final int? seconds; // pode ser 0
  final ValueChanged<int?>? onChangedSeconds;
  final InputDecoration Function(
    BuildContext context, {
    String? suffixText,
    String? hintText,
  })
  decorationBuilder;

  String _formatMmSs(int total) {
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _pickDuration(BuildContext context) async {
    final current = Duration(seconds: seconds ?? 0);
    Duration temp = current;

    await showModalBottomSheet(
      context: context,
      showDragHandle: false,
      isScrollControlled: false,
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
                      onChangedSeconds?.call(temp.inSeconds);
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
    final display = seconds == null ? '' : _formatMmSs(seconds!);
    final controller = TextEditingController(text: display);

    return Padding(
      padding: EdgeInsets.only(bottom: 10 * scale),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // chip
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
              onTap: () => _pickDuration(context),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
