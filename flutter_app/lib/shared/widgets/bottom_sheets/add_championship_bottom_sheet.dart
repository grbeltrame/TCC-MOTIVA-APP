import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';

/// DTO simples retornado pelo bottom sheet (UI pura)
class NewChampionshipInput {
  final String name;
  final DateTime date;
  const NewChampionshipInput({required this.name, required this.date});
}

/// Abre o sheet e RETORNA os dados digitados (ou null se cancelar).
Future<NewChampionshipInput?> showAddChampionshipBottomSheet(
  BuildContext context,
) {
  return showModalBottomSheet<NewChampionshipInput?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _AddChampionshipSheet(),
  );
}

class _AddChampionshipSheet extends StatefulWidget {
  const _AddChampionshipSheet({Key? key}) : super(key: key);

  @override
  State<_AddChampionshipSheet> createState() => _AddChampionshipSheetState();
}

class _AddChampionshipSheetState extends State<_AddChampionshipSheet> {
  final _nameCtrl = TextEditingController();
  DateTime? _date;
  final _formKey = GlobalKey<FormState>();
  final _dateFmt = DateFormat('dd/MM/yyyy');

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
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDate: _date ?? now,
      helpText: 'Selecione a data do campeonato',
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  void _submit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _date == null) return;
    Navigator.of(
      context,
    ).pop(NewChampionshipInput(name: _nameCtrl.text.trim(), date: _date!));
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final dateLabel =
        _date == null ? 'Selecionar data' : _dateFmt.format(_date!);

    return AppBottomSheet(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20 * scale,
          16 * scale,
          20 * scale,
          (16 * scale) + bottomInset,
        ),
        child: Form(
          key: _formKey,
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
                'Competição em vista? É hora de se preparar',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 18 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 14 * scale),

              // Nome do campeonato
              Text(
                'Nome do campeonato',
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
                textInputAction: TextInputAction.next,
                decoration: _decoration(context, hint: 'Ex.: Open da Cidade'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o nome do campeonato';
                  }
                  return null;
                },
              ),

              SizedBox(height: 12 * scale),

              // Data do campeonato
              Text(
                'Data do campeonato',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 12 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 6 * scale),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8 * scale),
                child: InputDecorator(
                  decoration: _decoration(context, hint: 'Selecionar data'),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 18 * scale,
                        color: AppColors.mediumGray,
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 14 * scale,
                            color:
                                _date == null
                                    ? AppColors.mediumGray
                                    : AppColors.darkText,
                          ),
                        ),
                      ),
                      if (_date != null)
                        TextButton(
                          onPressed: () => setState(() => _date = null),
                          child: Text(
                            'Limpar',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: AppFontWeight.bold,
                              fontSize: 12 * scale,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 18 * scale),

              // Botão "Registrar"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppTheme.secondaryButtonStyle(
                    AppColors.darkBlue,
                    AppColors.baseBlue,
                  ),
                  onPressed: _submit,
                  child: const Text('Registrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
