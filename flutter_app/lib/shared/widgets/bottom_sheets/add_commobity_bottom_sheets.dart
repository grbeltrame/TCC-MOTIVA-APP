// lib/shared/widgets/bottom_sheets/athlete/add_comorbidity_bottom_sheets.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';

/// DTO simples retornado pelo bottom sheet (UI pura)
class NewAthleteComorbidityInput {
  final String sectionKey; // ex: "respiratorias"
  final String label; // ex: "Asma"
  const NewAthleteComorbidityInput({
    required this.sectionKey,
    required this.label,
  });
}

/// Abre o sheet de "Adicionar nova" comorbidade e retorna o texto digitado.
/// - sectionKey: chave interna da seção (ex.: 'respiratorias')
/// - sectionTitle: título exibido no UI (ex.: 'Respiratórias')
Future<NewAthleteComorbidityInput?> showAddAthleteComorbidityBottomSheet(
  BuildContext context, {
  required String sectionKey,
  required String sectionTitle,
}) {
  return showModalBottomSheet<NewAthleteComorbidityInput?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => _AddAthleteComorbiditySheet(
          sectionKey: sectionKey,
          sectionTitle: sectionTitle,
        ),
  );
}

class _AddAthleteComorbiditySheet extends StatefulWidget {
  final String sectionKey;
  final String sectionTitle;

  const _AddAthleteComorbiditySheet({
    Key? key,
    required this.sectionKey,
    required this.sectionTitle,
  }) : super(key: key);

  @override
  State<_AddAthleteComorbiditySheet> createState() =>
      _AddAthleteComorbiditySheetState();
}

class _AddAthleteComorbiditySheetState
    extends State<_AddAthleteComorbiditySheet> {
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  InputDecoration _decoration(BuildContext context, {String? hint}) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return InputDecoration(
      isDense: true,
      hintText: hint,
      contentPadding: EdgeInsets.all(10 * scale),
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
        borderSide: BorderSide(
          color: AppColors.mediumGray.withOpacity(.9),
          width: 1,
        ),
      ),
      suffixIcon: IconButton(
        onPressed: () {
          _nameCtrl.clear();
          setState(() {});
        },
        icon: Icon(Icons.close, size: 18 * scale, color: AppColors.mediumGray),
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final label = _nameCtrl.text.trim();
    Navigator.of(context).pop(
      NewAthleteComorbidityInput(sectionKey: widget.sectionKey, label: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return AppBottomSheet(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20 * scale,
              16 * scale,
              20 * scale,
              16 * scale,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // handle
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
                  'Adicionar novo fator de atenção',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 18 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 6 * scale),

                SizedBox(height: 14 * scale),

                // Campo
                Text(
                  widget.sectionTitle,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 12 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 6 * scale),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: _decoration(
                    context,
                    hint: 'Digite uma opção (ex.: Asma)',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe uma opção';
                    }
                    if (v.trim().length < 2) {
                      return 'Muito curto';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _submit(),
                ),

                SizedBox(height: 18 * scale),

                // Botão
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: AppTheme.secondaryButtonStyle(
                      AppColors.darkBlue,
                      AppColors.baseBlue,
                    ),
                    onPressed: _submit,
                    child: const Text('Adicionar'),
                  ),
                ),

                SizedBox(height: 16 * scale),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
