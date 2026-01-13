// lib/features/user/coach/edit_profile/bottom_sheets/add_certification_bottom_sheet.dart
import 'package:flutter/material.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/users/profile_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/models/coach_profile.dart'
    hide CoachProfileService;
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';

Future<CoachProfileEditable?> showAddCertificationBottomSheet(
  BuildContext context, {
  required CoachProfileEditable profile,
}) {
  return showAppBottomSheet<CoachProfileEditable>(
    context,
    _AddCertificationSheet(profile: profile),
  );
}

class _AddCertificationSheet extends StatefulWidget {
  const _AddCertificationSheet({Key? key, required this.profile})
    : super(key: key);

  final CoachProfileEditable profile;

  @override
  State<_AddCertificationSheet> createState() => _AddCertificationSheetState();
}

class _AddCertificationSheetState extends State<_AddCertificationSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _saving = false;

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

    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) return;

    // evita duplicar
    if (_existsIgnoreCase(widget.profile.availableCertifications, newName) ||
        _existsIgnoreCase(widget.profile.certifications, newName)) {
      Navigator.of(context).pop(widget.profile);
      return;
    }

    setState(() => _saving = true);

    try {
      // ✅ adiciona na lista de disponíveis + já marca (entra em certifications)
      final updated = CoachProfileEditable(
        name: widget.profile.name,
        photoUrl: widget.profile.photoUrl,
        localPhotoPath: widget.profile.localPhotoPath,
        cref: widget.profile.cref,
        birthday: widget.profile.birthday,
        certifications: <String>[...widget.profile.certifications, newName],
        specialties: <String>[...widget.profile.specialties],
        availableCertifications: <String>[
          ...widget.profile.availableCertifications,
          newName,
        ],
        specialtiesByCategory: <String, List<String>>{
          ...widget.profile.specialtiesByCategory,
        },
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
          content: Text('Falha ao adicionar certificação.'),
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
                'Adicione uma certificação e valorize seu currículo',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 18 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 14 * scale),

              // Label
              Text(
                'Nome da certificação',
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
                decoration: _decoration(context, hint: 'Ex.: CrossFit L2'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o nome da certificação';
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
