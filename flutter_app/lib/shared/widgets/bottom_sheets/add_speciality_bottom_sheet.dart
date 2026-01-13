// lib/features/user/coach/edit_profile/bottom_sheets/add_specialty_bottom_sheet.dart
import 'package:flutter/material.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/users/profile_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/models/coach_profile.dart'
    hide CoachProfileService;
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';

Future<CoachProfileEditable?> showAddSpecialtyBottomSheet(
  BuildContext context, {
  required CoachProfileEditable profile,
}) {
  return showAppBottomSheet<CoachProfileEditable>(
    context,
    _AddSpecialtySheet(profile: profile),
  );
}

class _AddSpecialtySheet extends StatefulWidget {
  const _AddSpecialtySheet({Key? key, required this.profile}) : super(key: key);

  final CoachProfileEditable profile;

  @override
  State<_AddSpecialtySheet> createState() => _AddSpecialtySheetState();
}

class _AddSpecialtySheetState extends State<_AddSpecialtySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  late final List<String> _categories;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _categories = widget.profile.specialtiesByCategory.keys.toList();
    _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
  }

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

  bool _existsIgnoreCase(List<String> list, String value) {
    final v = value.trim().toLowerCase();
    return list.any((e) => e.trim().toLowerCase() == v);
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final category = _selectedCategory;
    if (category == null || category.trim().isEmpty) return;

    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    // evita duplicar globalmente
    if (_existsIgnoreCase(widget.profile.specialties, newName)) {
      Navigator.of(context).pop(widget.profile);
      return;
    }

    setState(() => _saving = true);

    try {
      final currentMap = <String, List<String>>{
        ...widget.profile.specialtiesByCategory,
      };

      final list = <String>[...(currentMap[category] ?? <String>[])];

      // evita duplicar dentro da categoria
      if (!_existsIgnoreCase(list, newName)) {
        list.add(newName);
      }
      currentMap[category] = list;

      // ✅ já entra marcado automaticamente (vai pra specialties)
      final updated = CoachProfileEditable(
        name: widget.profile.name,
        photoUrl: widget.profile.photoUrl,
        localPhotoPath: widget.profile.localPhotoPath,
        cref: widget.profile.cref,
        birthday: widget.profile.birthday,
        certifications: <String>[...widget.profile.certifications],
        specialties: <String>[...widget.profile.specialties, newName],
        availableCertifications: <String>[
          ...widget.profile.availableCertifications,
        ],
        specialtiesByCategory: currentMap,
      );

      // ✅ “envia pro banco” (mock agora, real depois)
      await CoachProfileService.instance.updateCoachProfileEditable(updated);

      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao adicionar especialidade.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                'Destaque suas especialidades e aumente sua autoridade',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 18 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 14 * scale),

              // Categoria (subcategorias)
              Text(
                'Categoria',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 12 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 6 * scale),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items:
                    _categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                onChanged:
                    _saving
                        ? null
                        : (v) => setState(() => _selectedCategory = v),
                decoration: _decoration(context),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Selecione uma categoria';
                  }
                  return null;
                },
              ),

              SizedBox(height: 12 * scale),

              // Nome da especialidade
              Text(
                'Nome da especialidade',
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
                  hint: 'Ex.: Estratégia de Pacing',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o nome da especialidade';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _saving ? null : _submit(),
              ),

              SizedBox(height: 18 * scale),

              // Botão único
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppTheme.secondaryButtonStyle(
                    AppColors.darkBlue,
                    AppColors.baseBlue,
                  ),
                  onPressed: _saving ? null : _submit,
                  child:
                      _saving
                          ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Confirmar'),
                ),
              ),
              SizedBox(height: 32 * scale),
            ],
          ),
        ),
      ),
    );
  }
}
