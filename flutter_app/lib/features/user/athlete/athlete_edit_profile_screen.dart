// lib/features/user/athlete/athlete_edit_profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/add_commobity_bottom_sheets.dart';
import 'package:flutter_app/shared/widgets/utils/brazilian_date_input_formatter.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

import 'package:flutter_app/shared/models/athlete_profile.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class EditProfileAthleteScreen extends StatefulWidget {
  static const routeName = '/edit_profile_athlete';

  const EditProfileAthleteScreen({super.key});

  static Widget fromArgs(RouteSettings settings) {
    return const EditProfileAthleteScreen();
  }

  @override
  State<EditProfileAthleteScreen> createState() =>
      _EditProfileAthleteScreenState();
}

class _EditProfileAthleteScreenState extends State<EditProfileAthleteScreen> {
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _picker = ImagePicker();

  late Future<AthleteProfileEditable> _future;
  AthleteProfileEditable? _editable;

  DateTime? _birthday;
  String? _localPhotoPath;

  bool _saving = false;
  bool _didBootstrapProfile = false;

  // radios
  String? _category; // Iniciante | Scaled | Intermediário | RX | Elite
  String? _gender; // Homem | Mulher | Outro

  // dropdown
  String? _practiceYears;

  // fatores (checkbox)
  late Map<String, List<String>> _factorOptions;
  late Map<String, Set<String>> _selectedFactors;

  @override
  void initState() {
    super.initState();
    _future = AthleteProfileService.instance.fetchAthleteProfileEditable();

    _factorOptions = {
      'respiratorias': ['Asma', 'Bronquite Crônica', 'Apneia do Sono'],
      'cardiovasculares': [
        'Hipertensão',
        'Histórico de Infarto',
        'Colesterol Alto',
        'Arritmia Cardíaca',
        'Hipotensão',
      ],
      'ortopedicas': [
        'Hérnia de disco',
        'Dor lombar crônica',
        'Problemas crônicos nos joelhos',
        'Cirurgia ortopédica recente',
        'Lesões recorrentes nos ombros',
      ],
      'neurologicas': [
        'Crise Convulsiva',
        'Histórico de AVC',
        'Parkinson',
        'Paralisia Cerebral',
      ],
      'metabolicas': [
        'Diabetes tipo 1',
        'Diabetes tipo 2',
        'Obesidade',
        'Hipotireoidismo',
        'Hipertireoidismo',
      ],
      'outros': [
        'Doenças Autoimunes',
        'Fibromialgia',
        'Endometriose',
        'Câncer em tratamento ou recente',
        'Cirurgia abdominal ou torácica importante recente',
      ],
      'habitos': [
        'Fumo ativo',
        'Consumo de álcool recorrente',
        'Sono irregular (menos de 5h por noite regularmente)',
        'Sedentarismo (sem prática física há mais de 6 meses)',
      ],
    };

    _selectedFactors = {
      'respiratorias': <String>{},
      'cardiovasculares': <String>{},
      'ortopedicas': <String>{},
      'neurologicas': <String>{},
      'metabolicas': <String>{},
      'outros': <String>{},
      'habitos': <String>{},
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _birthdayCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers (evita crash de dropdown quando o valor vem diferente do item)
  // ───────────────────────────────────────────────────────────────────────────

  String _norm(String s) {
    return s
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .replaceAll('anosdeprática', '')
        .replaceAll('anodeprática', '')
        .replaceAll('deprática', '')
        .trim();
  }

  String? _sanitizeDropdownValue(String? current, List<String> items) {
    if (current == null) return null;

    final trimmed = current.trim();
    if (trimmed.isEmpty) return null;

    if (items.contains(trimmed)) return trimmed;

    final target = _norm(trimmed);
    final matches = items.where((e) => _norm(e) == target).toList();

    if (matches.length == 1) return matches.first;

    return null;
  }

  List<String> _uniqueItems(List<String> items) {
    final seen = <String>{};
    final out = <String>[];
    for (final it in items) {
      final t = it.trim();
      if (t.isEmpty) continue;
      if (seen.add(t)) out.add(t);
    }
    return out;
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
    final typedBirthday = _parseBirthdayText(_birthdayCtrl.text);
    final initial =
        typedBirthday ??
        _birthday ??
        DateTime(now.year - 20, now.month, now.day);

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
        _birthdayCtrl.text = _dateFmt.format(_birthday!);
      });
    }
  }

  DateTime? _parseBirthdayText(String value) {
    final text = value.trim();
    if (text.isEmpty || text.length != 10) return null;

    try {
      final parsed = _dateFmt.parseStrict(text);
      final birthday = DateTime(parsed.year, parsed.month, parsed.day);
      final now = DateTime.now();
      final minDate = DateTime(now.year - 90, now.month, now.day);
      final maxDate = DateTime(now.year, now.month, now.day);

      if (birthday.isBefore(minDate) || birthday.isAfter(maxDate)) return null;
      return birthday;
    } catch (_) {
      return null;
    }
  }

  bool _syncBirthdayFromText({bool showError = false}) {
    final text = _birthdayCtrl.text.trim();
    if (text.isEmpty) {
      _birthday = null;
      return true;
    }

    final parsed = _parseBirthdayText(text);
    if (parsed == null) {
      if (showError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informe o aniversário no formato dd/mm/aaaa.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    _birthday = parsed;
    return true;
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
    });
  }

  void _toggleFactor(String key, String label, bool checked) {
    final set = _selectedFactors[key] ?? <String>{};
    final next = {...set};

    if (checked) {
      next.add(label);
    } else {
      next.remove(label);
    }

    setState(() {
      _selectedFactors[key] = next;
    });
  }

  // ✅ Agora usa o bottom sheet genérico
  Future<void> _openAddComorbiditySheet({
    required String sectionKey,
    required String sectionTitle,
  }) async {
    final res = await showAddAthleteComorbidityBottomSheet(
      context,
      sectionKey: sectionKey,
      sectionTitle: sectionTitle,
    );

    if (res == null) return;

    final cleaned = res.label.trim();
    if (cleaned.isEmpty) return;

    setState(() {
      final key = res.sectionKey;

      final list = _factorOptions[key] ?? <String>[];
      final nextList = [...list];
      if (!nextList.contains(cleaned)) nextList.add(cleaned);
      _factorOptions[key] = nextList;

      final sel = _selectedFactors[key] ?? <String>{};
      _selectedFactors[key] = {...sel, cleaned};
    });
  }

  Future<void> _saveAndClose() async {
    if (_editable == null) return;
    if (!_syncBirthdayFromText(showError: true)) return;

    setState(() => _saving = true);

    try {
      final updated = _editable!.copyWith(
        name: _nameCtrl.text.trim(),
        birthday: _birthday,
        localPhotoPath: _localPhotoPath,
        category: _category,
        gender: _gender,
        weight:
            _weightCtrl.text.trim().isEmpty ? null : _weightCtrl.text.trim(),
        practiceYears: _practiceYears,
        height:
            _heightCtrl.text.trim().isEmpty ? null : _heightCtrl.text.trim(),
        healthFactors: _selectedFactors.map((k, v) => MapEntry(k, v.toList())),
      );

      await AthleteProfileService.instance.updateAthleteProfileEditable(
        updated,
      );

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

    final practiceItems = _uniqueItems(const [
      'Menos de 1 ano',
      'Entre 1 e 3 anos',
      'Entre 3 e 5 anos',
      'Mais de 5 anos',
    ]);

    return Scaffold(
      appBar: const TopNavbar(),
      body: SafeArea(
        child: FutureBuilder<AthleteProfileEditable>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData) {
              return const Center(child: Text('Falha ao carregar perfil.'));
            }

            if (!_didBootstrapProfile) {
              _editable = snap.data!;
              final initialProfile = _editable!;

              _nameCtrl.text = initialProfile.name;
              _birthday = initialProfile.birthday;
              if (_birthday != null) {
                _birthdayCtrl.text = _dateFmt.format(_birthday!);
              }
              _category = initialProfile.category;
              _gender = initialProfile.gender;
              _practiceYears = initialProfile.practiceYears;
              _weightCtrl.text = initialProfile.weight ?? '';
              _heightCtrl.text = initialProfile.height ?? '';

              if (initialProfile.healthFactors.isNotEmpty) {
                for (final entry in initialProfile.healthFactors.entries) {
                  if (_selectedFactors.containsKey(entry.key)) {
                    _selectedFactors[entry.key] = entry.value.toSet();
                  }
                }
              }

              _didBootstrapProfile = true;
            }

            final profile = _editable!;

            final safePractice = _sanitizeDropdownValue(
              _practiceYears,
              practiceItems,
            );

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

                  Center(
                    child: Text(
                      'Dados pessoais',
                      style: TextStyle(
                        fontFamily: AppFonts.montserrat,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 16 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * scale),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92 * scale,
                        child: _PhotoPicker(
                          scale: scale,
                          photoUrl: profile.photoUrl,
                          localPath: _localPhotoPath,
                          onPick: _pickAndCropPhoto,
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
                              onChanged: (_) => setState(() {}),
                            ),
                            SizedBox(height: 10 * scale),
                            TextFormField(
                              controller: _birthdayCtrl,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              inputFormatters: const [
                                BrazilianDateInputFormatter(),
                              ],
                              decoration: _inputDec(
                                label: 'Aniversário',
                                hint: 'dd/mm/aaaa',
                                suffixIcon: IconButton(
                                  onPressed: _pickBirthday,
                                  icon: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 18 * scale,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _birthday =
                                      value.trim().isEmpty
                                          ? null
                                          : _parseBirthdayText(value);
                                });
                              },
                              onFieldSubmitted:
                                  (_) => _syncBirthdayFromText(showError: true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14 * scale),

                  Text(
                    'Categoria:',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 12 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Wrap(
                    spacing: 10 * scale,
                    runSpacing: 4 * scale,
                    children: [
                      _RadioChip(
                        label: 'Iniciante',
                        value: 'Iniciante',
                        groupValue: _category,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      _RadioChip(
                        label: 'Scaled',
                        value: 'Scaled',
                        groupValue: _category,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      _RadioChip(
                        label: 'Intermediário',
                        value: 'Intermediário',
                        groupValue: _category,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      _RadioChip(
                        label: 'RX',
                        value: 'RX',
                        groupValue: _category,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      _RadioChip(
                        label: 'Elite',
                        value: 'Elite',
                        groupValue: _category,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                    ],
                  ),

                  SizedBox(height: 18 * scale),

                  Text(
                    'Perfil Referência',
                    style: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 16 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                  SizedBox(height: 10 * scale),

                  Text(
                    'Gênero:',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 12 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                  SizedBox(height: 6 * scale),
                  Wrap(
                    spacing: 14 * scale,
                    runSpacing: 2 * scale,
                    children: [
                      _RadioChip(
                        label: 'Homem',
                        value: 'Homem',
                        groupValue: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      _RadioChip(
                        label: 'Mulher',
                        value: 'Mulher',
                        groupValue: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                      _RadioChip(
                        label: 'Outro',
                        value: 'Outro',
                        groupValue: _gender,
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ],
                  ),

                  SizedBox(height: 12 * scale),

                  TextFormField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDec(
                      label: 'Peso (kg)',
                      hint: 'Ex: 70',
                      suffixIcon:
                          _weightCtrl.text.isNotEmpty
                              ? IconButton(
                                onPressed:
                                    () => setState(() => _weightCtrl.clear()),
                                icon: Icon(
                                  Icons.close,
                                  size: 18 * scale,
                                  color: AppColors.mediumGray,
                                ),
                              )
                              : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 12 * scale),

                  TextFormField(
                    controller: _heightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _inputDec(
                      label: 'Altura (cm)',
                      hint: 'Ex: 170',
                      suffixIcon:
                          _heightCtrl.text.isNotEmpty
                              ? IconButton(
                                onPressed:
                                    () => setState(() => _heightCtrl.clear()),
                                icon: Icon(
                                  Icons.close,
                                  size: 18 * scale,
                                  color: AppColors.mediumGray,
                                ),
                              )
                              : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: 12 * scale),

                  _DropdownField(
                    label: 'Tempo de Prática',
                    value: safePractice,
                    items: practiceItems,
                    onChanged: (v) => setState(() => _practiceYears = v),
                    onClear: () => setState(() => _practiceYears = null),
                    scale: scale,
                  ),

                  SizedBox(height: 22 * scale),

                  Text(
                    'Fatores de Atenção',
                    style: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 16 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                  SizedBox(height: 12 * scale),

                  _FactorSection(
                    title: 'Respiratórias',
                    noneLabel: 'Não possuo problemas respiratórios',
                    scale: scale,
                    items: _factorOptions['respiratorias'] ?? const [],
                    selected: _selectedFactors['respiratorias'] ?? const {},
                    onToggle:
                        (label, checked) =>
                            _toggleFactor('respiratorias', label, checked),
                    onAddNew:
                        () => _openAddComorbiditySheet(
                          sectionKey: 'respiratorias',
                          sectionTitle: 'Respiratórias',
                        ),
                  ),
                  _FactorSection(
                    title: 'Cardiovasculares',
                    noneLabel: 'Não possuo problemas cardiovasculares',
                    scale: scale,
                    items: _factorOptions['cardiovasculares'] ?? const [],
                    selected: _selectedFactors['cardiovasculares'] ?? const {},
                    onToggle:
                        (label, checked) =>
                            _toggleFactor('cardiovasculares', label, checked),
                    onAddNew:
                        () => _openAddComorbiditySheet(
                          sectionKey: 'cardiovasculares',
                          sectionTitle: 'Cardiovasculares',
                        ),
                  ),
                  _FactorSection(
                    title: 'Ortopédicas',
                    noneLabel: 'Não possuo problemas ortopédicos',
                    scale: scale,
                    items: _factorOptions['ortopedicas'] ?? const [],
                    selected: _selectedFactors['ortopedicas'] ?? const {},
                    onToggle:
                        (label, checked) =>
                            _toggleFactor('ortopedicas', label, checked),
                    onAddNew:
                        () => _openAddComorbiditySheet(
                          sectionKey: 'ortopedicas',
                          sectionTitle: 'Ortopédicas',
                        ),
                  ),
                  _FactorSection(
                    title: 'Neurológicas',
                    noneLabel: 'Não possuo problemas neurológicos',
                    scale: scale,
                    items: _factorOptions['neurologicas'] ?? const [],
                    selected: _selectedFactors['neurologicas'] ?? const {},
                    onToggle:
                        (label, checked) =>
                            _toggleFactor('neurologicas', label, checked),
                    onAddNew:
                        () => _openAddComorbiditySheet(
                          sectionKey: 'neurologicas',
                          sectionTitle: 'Neurológicas',
                        ),
                  ),
                  _FactorSection(
                    title: 'Metabólicas',
                    noneLabel: 'Não possuo problemas metabólicos',
                    scale: scale,
                    items: _factorOptions['metabolicas'] ?? const [],
                    selected: _selectedFactors['metabolicas'] ?? const {},
                    onToggle:
                        (label, checked) =>
                            _toggleFactor('metabolicas', label, checked),
                    onAddNew:
                        () => _openAddComorbiditySheet(
                          sectionKey: 'metabolicas',
                          sectionTitle: 'Metabólicas',
                        ),
                  ),
                  _FactorSection(
                    title: 'Outros Quadros Clínicos',
                    noneLabel: 'Não possuo outros quadros clínicos',
                    scale: scale,
                    items: _factorOptions['outros'] ?? const [],
                    selected: _selectedFactors['outros'] ?? const {},
                    onToggle:
                        (label, checked) =>
                            _toggleFactor('outros', label, checked),
                    onAddNew:
                        () => _openAddComorbiditySheet(
                          sectionKey: 'outros',
                          sectionTitle: 'Outros Quadros Clínicos',
                        ),
                  ),
                  _FactorSection(
                    title: 'Hábitos de Risco',
                    noneLabel: 'Não possuo hábitos de risco',
                    scale: scale,
                    items: _factorOptions['habitos'] ?? const [],
                    selected: _selectedFactors['habitos'] ?? const {},
                    onToggle:
                        (label, checked) =>
                            _toggleFactor('habitos', label, checked),
                    onAddNew:
                        () => _openAddComorbiditySheet(
                          sectionKey: 'habitos',
                          sectionTitle: 'Hábitos de Risco',
                        ),
                  ),

                  SizedBox(height: 18 * scale),

                  OutlinedButton(
                    onPressed: _saving ? null : _saveAndClose,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.baseBlue, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * scale,
                        vertical: 10 * scale,
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
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _RadioChip extends StatelessWidget {
  final String label;
  final String value;
  final String? groupValue;
  final ValueChanged<String> onChanged;

  const _RadioChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = groupValue == value;
    final scale = MediaQuery.of(context).size.width / 375.0;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(999),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: (v) => onChanged(v ?? value),
            activeColor: AppColors.baseBlue,
            visualDensity: VisualDensity.compact,
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
              color: selected ? AppColors.baseBlue : AppColors.darkText,
              fontWeight: selected ? AppFontWeight.bold : AppFontWeight.regular,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final VoidCallback onClear;
  final double scale;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.onClear,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = (value != null && items.contains(value)) ? value : null;

    return DropdownButtonFormField<String>(
      value: safeValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Selecione uma opção',
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
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
        suffixIcon:
            safeValue == null
                ? null
                : IconButton(
                  onPressed: onClear,
                  icon: Icon(
                    Icons.close,
                    size: 18 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
      ),
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: AppColors.mediumGray,
        size: 20 * scale,
      ),
      items:
          items
              .map(
                (e) => DropdownMenuItem<String>(
                  value: e,
                  child: Text(
                    e,
                    overflow: TextOverflow.ellipsis,
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
    );
  }
}

class _FactorSection extends StatelessWidget {
  final String title;
  final String? noneLabel;
  final double scale;
  final List<String> items;
  final Set<String> selected;
  final void Function(String label, bool checked) onToggle;
  final VoidCallback onAddNew;

  const _FactorSection({
    required this.title,
    this.noneLabel,
    required this.scale,
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.onAddNew,
  });

  /// Rótulo fixo que representa "sem problemas nessa categoria".
  String get _noneLabel => noneLabel ?? 'Não possuo problemas $title';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // title + "Adicionar nova"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 12 * scale,
                  color: AppColors.darkText,
                ),
              ),
              TextButton.icon(
                onPressed: onAddNew,
                icon: Icon(
                  Icons.add,
                  size: 16 * scale,
                  color: AppColors.baseBlue,
                ),
                label: Text(
                  'Adicionar nova',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 12 * scale,
                    color: AppColors.baseBlue,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale,
                    vertical: 2,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * scale),

          Column(
            children: [
              // ── Opção fixa "Não possuo problemas X" ──
              _FactorItem(
                label: _noneLabel,
                checked: selected.contains(_noneLabel),
                scale: scale,
                onToggle: (checked) {
                  // Ao marcar "nenhum", desmarca todos os outros
                  if (checked) {
                    for (final item in items) {
                      onToggle(item, false);
                    }
                  }
                  onToggle(_noneLabel, checked);
                },
              ),
              // ── Itens da categoria ──
              ...items.map((label) {
                final checked = selected.contains(label);

                return _FactorItem(
                  label: label,
                  checked: checked,
                  scale: scale,
                  onToggle: (v) {
                    // Ao marcar qualquer item, desmarca "nenhum"
                    if (v) onToggle(_noneLabel, false);
                    onToggle(label, v);
                  },
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Item individual de fator (checkbox + label)
// ─────────────────────────────────────────────────────────────────────────────

class _FactorItem extends StatelessWidget {
  final String label;
  final bool checked;
  final double scale;
  final void Function(bool checked) onToggle;

  const _FactorItem({
    required this.label,
    required this.checked,
    required this.scale,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onToggle(!checked),
      child: Padding(
        padding: EdgeInsets.only(bottom: 4 * scale),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: checked,
              onChanged: (v) => onToggle(v ?? false),
              activeColor: AppColors.baseBlue,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 8 * scale),
                child: Text(
                  label,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.darkText,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
