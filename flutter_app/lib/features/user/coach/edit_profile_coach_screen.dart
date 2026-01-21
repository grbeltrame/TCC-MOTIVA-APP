// lib/features/user/coach/edit_profile_coach_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/coach_profile.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/add_certification_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/add_speciality_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_certifications_section.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_specialities_section.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class EditProfileCoachScreen extends StatefulWidget {
  static const routeName = '/edit_profile_coach';

  const EditProfileCoachScreen({super.key});

  @override
  State<EditProfileCoachScreen> createState() => _EditProfileCoachScreenState();
}

class _EditProfileCoachScreenState extends State<EditProfileCoachScreen> {
  final _nameCtrl = TextEditingController();
  final _crefCtrl = TextEditingController();

  final _picker = ImagePicker();
  final _dateFmt = DateFormat('dd/MM/yyyy');

  late Future<CoachProfileEditable> _future;
  CoachProfileEditable? _editable;

  DateTime? _birthday;
  String? _localPhotoPath;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = CoachProfileService.instance.fetchCoachProfileEditable();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _crefCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI helpers
  // ───────────────────────────────────────────────────────────────────────────

  InputDecoration _inputDec({
    required String label,
    Widget? suffixIcon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.mediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.mediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColors.baseBlue, width: 1),
      ),
    );
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _birthday ?? DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 90),
      lastDate: now,
      initialDate: initial,
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione seu aniversário',
    );

    if (picked != null) {
      setState(() {
        _birthday = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _pickAndCropPhoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 95,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cortar foto',
          toolbarColor: Colors.white,
          toolbarWidgetColor: AppColors.darkText,
          activeControlsWidgetColor: AppColors.baseBlue,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
        ),
        IOSUiSettings(title: 'Cortar foto', aspectRatioLockEnabled: true),
      ],
    );

    if (cropped == null) return;

    setState(() {
      _localPhotoPath = cropped.path;
      if (_editable != null) {
        _editable = _editable!.copyWith(localPhotoPath: _localPhotoPath);
      }
    });
  }

  Future<void> _saveAndClose() async {
    if (_editable == null) return;

    setState(() => _saving = true);

    try {
      final updated = _editable!.copyWith(
        name: _nameCtrl.text.trim(),
        cref: _crefCtrl.text.trim().isEmpty ? null : _crefCtrl.text.trim(),
        birthday: _birthday,
        localPhotoPath: _localPhotoPath,
      );

      await CoachProfileService.instance.updateCoachProfileEditable(updated);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar perfil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),
      body: SafeArea(
        child: FutureBuilder<CoachProfileEditable>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData) {
              return const Center(child: Text('Falha ao carregar perfil.'));
            }

            _editable ??= snap.data!;
            final editable = _editable!;

            // bootstrap controllers uma vez
            if (_nameCtrl.text.isEmpty) _nameCtrl.text = editable.name;
            if (_crefCtrl.text.isEmpty) _crefCtrl.text = (editable.cref ?? '');
            _birthday ??= editable.birthday;
            _localPhotoPath ??= editable.localPhotoPath;

            final birthdayLabel =
                (_birthday == null) ? '' : _dateFmt.format(_birthday!);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                14 * scale,
                10 * scale,
                14 * scale,
                18 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ Linha: Back (esquerda) + Atualizar Perfil (direita)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const AppBackButton(),
                      OutlinedButton(
                        onPressed: _saving ? null : _saveAndClose,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.baseBlue, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scale,
                            vertical: 8 * scale,
                          ),
                          foregroundColor: AppColors.baseBlue,
                        ),
                        child:
                            _saving
                                ? SizedBox(
                                  width: 16 * scale,
                                  height: 16 * scale,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(
                                  'Atualizar Perfil',
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: 12 * scale,
                                  ),
                                ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10 * scale),

                  // ✅ Texto LGPD abaixo (igual a imagem)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 14 * scale,
                        color: AppColors.mediumGray,
                      ),
                      SizedBox(width: 6 * scale),
                      Expanded(
                        child: Text(
                          'Seus dados são 100% privados\n'
                          'As informações inseridas aqui são confidenciais e não são exibidas publicamente. '
                          'Elas servem apenas para personalizar sua experiência no app com segurança e responsabilidade.',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 10.5 * scale,
                            color: AppColors.mediumGray,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 18 * scale),

                  // ✅ Título "Dados Pessoais"
                  Center(
                    child: Text(
                      'Dados Pessoais',
                      style: TextStyle(
                        fontFamily: AppFonts.montserrat,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 16 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),

                  SizedBox(height: 12 * scale),

                  // ✅ Linha: Foto (esq) + Nome/Aniversário (dir)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92 * scale,
                        child: _PhotoPicker(
                          scale: scale,
                          photoUrl: editable.photoUrl,
                          localPath: _localPhotoPath,
                          onPick: _pickAndCropPhoto, // ✅ funcionando
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: _inputDec(
                                label: 'Nome',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    _nameCtrl.clear();
                                    setState(() {});
                                  },
                                  icon: Icon(
                                    Icons.close,
                                    size: 18 * scale,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _editable = editable.copyWith(
                                    name: _nameCtrl.text,
                                  );
                                });
                              },
                            ),
                            SizedBox(height: 10 * scale),

                            InkWell(
                              onTap: _pickBirthday,
                              borderRadius: BorderRadius.circular(10),
                              child: IgnorePointer(
                                child: TextFormField(
                                  controller: TextEditingController(
                                    text: birthdayLabel,
                                  ),
                                  decoration: _inputDec(
                                    label: 'Aniversário',
                                    suffixIcon: Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18 * scale,
                                      color: AppColors.mediumGray,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12 * scale),

                  // ✅ Linha de baixo: CREF
                  TextFormField(
                    controller: _crefCtrl,
                    decoration: _inputDec(
                      label: 'CREF',
                      suffixIcon: Icon(
                        Icons.check,
                        size: 18 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _editable = editable.copyWith(cref: _crefCtrl.text);
                      });
                    },
                  ),

                  SizedBox(height: 18 * scale),

                  // ─────────────────────────────────────────────────────────
                  // Certificações (CHAMANDO A SECTION QUE JÁ EXISTE)
                  // ─────────────────────────────────────────────────────────
                  CertificationsSection(
                    scale: scale,
                    selected:
                        editable
                            .certifications, // ✅ só as que já estão no perfil
                    allItems:
                        editable
                            .availableCertifications, // ✅ lista total vinda do "banco" (mock)
                    onToggle: (item, checked) {
                      setState(() {
                        final current = _editable!;
                        final nextSelected = [...current.certifications];

                        if (checked) {
                          if (!nextSelected.contains(item))
                            nextSelected.add(item);
                        } else {
                          nextSelected.remove(item);
                        }

                        _editable = current.copyWith(
                          certifications: nextSelected,
                        );
                      });
                    },
                    onAddNew: () async {
                      // ✅ chama o bottom sheet que vocês já têm
                      final res = await showAddCertificationBottomSheet(
                        context,
                        profile: editable,
                      );
                      if (res == null) return;

                      setState(() {
                        final current = _editable!;
                        final certName = res.name.trim();
                        if (certName.isEmpty) return;

                        // adiciona na lista total (mock do "banco") se não existir
                        final all = [...current.availableCertifications];
                        if (!all.contains(certName)) all.add(certName);

                        // entra marcada automaticamente
                        final selected = [...current.certifications];
                        if (!selected.contains(certName))
                          selected.add(certName);

                        _editable = current.copyWith(
                          availableCertifications: all,
                          certifications: selected,
                        );
                      });
                    },
                  ),

                  SizedBox(height: 18 * scale),
                  // ─────────────────────────────────────────────────────────
                  // Especialidades (CHAMANDO A SECTION QUE JÁ EXISTE)
                  // ─────────────────────────────────────────────────────────
                  SpecialtiesSection(
                    scale: scale,
                    categories:
                        editable
                            .specialtiesByCategory, // ✅ categorias + itens (mock "banco")
                    selected:
                        editable.specialties, // ✅ só as que já estão no perfil
                    onToggle: (item, checked) {
                      setState(() {
                        final current = _editable!;
                        final nextSelected = [...current.specialties];

                        if (checked) {
                          if (!nextSelected.contains(item))
                            nextSelected.add(item);
                        } else {
                          nextSelected.remove(item);
                        }

                        _editable = current.copyWith(specialties: nextSelected);
                      });
                    },
                    onAddNew: () async {
                      final updatedProfile = await showAddSpecialtyBottomSheet(
                        context,
                        profile:
                            _editable!, // usa o estado atual (não o "editable" capturado)
                      );
                      if (updatedProfile == null) return;

                      setState(() {
                        _editable =
                            updatedProfile; // ✅ pronto: já vem com a nova especialidade
                      });
                    },
                  ),

                  SizedBox(height: 18 * scale),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Foto com ícone de editar (clicável)
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.scale,
    required this.photoUrl,
    required this.localPath,
    required this.onPick,
  });

  final double scale;
  final String? photoUrl;
  final String? localPath;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    ImageProvider? img;

    if (localPath != null && localPath!.isNotEmpty) {
      img = FileImage(File(localPath!));
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      img = NetworkImage(photoUrl!);
    }

    return Stack(
      children: [
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(999),
          child: CircleAvatar(
            radius: 40 * scale,
            backgroundColor: AppColors.lightGray,
            backgroundImage: img,
            child:
                img == null
                    ? Icon(
                      Icons.person,
                      size: 34 * scale,
                      color: AppColors.mediumGray,
                    )
                    : null,
          ),
        ),
        Positioned(
          bottom: 2 * scale,
          right: 2 * scale,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              onTap: onPick,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(6 * scale),
                child: Icon(
                  Icons.edit,
                  size: 16 * scale,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
