import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';
import 'package:flutter_app/core/services/workout/movement_service.dart';

/// ===== Model/Controllers da linha (público p/ orquestrador e seções) =====
class MovementRowData {
  final TextEditingController qtyController;
  final TextEditingController nameController;
  final TextEditingController? loadController;
  final TextEditingController? timeController;
  final bool expectsQuantity;
  final bool expectsLoadKg;
  final bool expectsTimeSec;

  MovementRowData({
    required this.qtyController,
    required this.nameController,
    required this.loadController,
    required this.timeController,
    required this.expectsQuantity,
    required this.expectsLoadKg,
    required this.expectsTimeSec,
  });

  factory MovementRowData.fromPreset(MovementPreset p) {
    return MovementRowData(
      qtyController: TextEditingController(
        text: p.presetQuantity != null ? p.presetQuantity.toString() : '',
      ),
      nameController: TextEditingController(text: p.name),
      loadController:
          p.expectsLoadKg
              ? TextEditingController(
                text: p.presetLoadKg != null ? p.presetLoadKg!.toString() : '',
              )
              : null,
      timeController:
          p.expectsTimeSec
              ? TextEditingController(
                text:
                    p.presetTimeSec != null ? p.presetTimeSec!.toString() : '',
              )
              : null,
      expectsQuantity: p.expectsQuantity,
      expectsLoadKg: p.expectsLoadKg,
      expectsTimeSec: p.expectsTimeSec,
    );
  }
  factory MovementRowData.empty({
    bool expectsQuantity = true,
    bool expectsLoadKg = false,
    bool expectsTimeSec = false,
  }) {
    return MovementRowData(
      qtyController: TextEditingController(),
      nameController: TextEditingController(),
      loadController: expectsLoadKg ? TextEditingController() : null,
      timeController: expectsTimeSec ? TextEditingController() : null,
      expectsQuantity: expectsQuantity,
      expectsLoadKg: expectsLoadKg,
      expectsTimeSec: expectsTimeSec,
    );
  }

  // getters de conveniência (só leitura)
  String get movement => nameController.text.trim();
  int? get qty =>
      expectsQuantity ? int.tryParse(qtyController.text.trim()) : null;
  num? get loadKg =>
      expectsLoadKg ? num.tryParse((loadController?.text ?? '').trim()) : null;
  int? get timeSec =>
      expectsTimeSec ? int.tryParse((timeController?.text ?? '').trim()) : null;

  void dispose() {
    qtyController.dispose();
    nameController.dispose();
    loadController?.dispose();
    timeController?.dispose();
  }
}

/// ===== Campo com Autocomplete (TODO back preenche sugestões) =====
class MovementAutocompleteField extends StatelessWidget {
  const MovementAutocompleteField({
    super.key,
    required this.controller,
    required this.inputDecorationBuilder,
  });

  final TextEditingController controller;
  final InputDecoration Function(
    BuildContext context, {
    String? suffixText,
    String? hintText,
  })
  inputDecorationBuilder;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue value) async {
        // TODO(back): retornar catálogo real baseado em value.text
        if (value.text.trim().isEmpty) return const Iterable<String>.empty();
        final results = await WorkoutResultService.searchMovementSuggestions(
          value.text.trim(),
        );
        return results;
      },
      fieldViewBuilder: (ctx, textController, focusNode, onFieldSubmitted) {
        // sincroniza com o controller externo
        textController.text = controller.text;
        textController.selection = controller.selection;
        textController.addListener(() {
          controller.value = textController.value;
        });

        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: inputDecorationBuilder(ctx, hintText: ''),
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 14 * scale,
            color: AppColors.darkText,
          ),
        );
      },
      onSelected: (value) => controller.text = value,
      optionsViewBuilder: (ctx, onSelected, options) {
        final opts = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8 * scale),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 200 * scale,
                minWidth: 200 * scale,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: opts.length,
                itemBuilder: (context, index) {
                  final opt = opts[index];
                  return InkWell(
                    onTap: () => onSelected(opt),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * scale,
                        vertical: 10 * scale,
                      ),
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 14 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ===== Linha de movimento: [kg*] [s*] [Qtd] [Movimento] =====
class MovementRow extends StatelessWidget {
  const MovementRow({
    super.key,
    required this.data,
    required this.inputDecorationBuilder,
  });

  final MovementRowData data;
  final InputDecoration Function(
    BuildContext context, {
    String? suffixText,
    String? hintText,
  })
  inputDecorationBuilder;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    const decimalReg = r'[0-9.]';

    final qtyWidth = 40.0 * scale;
    final loadWidth = 55.0 * scale;
    final timeWidth = 40.0 * scale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1) Peso (kg) primeiro, se aplicável
        if (data.expectsLoadKg) ...[
          SizedBox(
            width: loadWidth,
            child: TextField(
              controller: data.loadController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(decimalReg)),
              ],
              decoration: inputDecorationBuilder(context, suffixText: 'kg'),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
        ],

        // 2) Tempo (s) em seguida, se aplicável
        if (data.expectsTimeSec) ...[
          SizedBox(
            width: timeWidth,
            child: TextField(
              controller: data.timeController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: inputDecorationBuilder(context, suffixText: 's'),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
        ],

        // 3) Quantidade
        if (data.expectsQuantity) ...[
          SizedBox(
            width: qtyWidth,
            child: TextField(
              controller: data.qtyController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: inputDecorationBuilder(context, hintText: ''),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
        ],

        // 4) Movimento (ocupa o restante)
        Expanded(
          child: MovementAutocompleteField(
            controller: data.nameController,
            inputDecorationBuilder: inputDecorationBuilder,
          ),
        ),
      ],
    );
  }
}
