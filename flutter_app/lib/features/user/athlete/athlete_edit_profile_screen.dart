// lib/features/user/athlete/athlete_edit_profile_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/add_commobity_bottom_sheets.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

import 'package:flutter_app/core/services/users/athlete/athlete_service.dart';
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
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _picker = ImagePicker();

  late Future<AthleteProfile> _future;
  AthleteProfile? _profile;

  DateTime? _birthday;
  String? _localPhotoPath;

  bool _saving = false;

  // radios
  String? _category; // Iniciante | Scaled | Intermediário | RX | Elite
  String? _gender; // Homem | Mulher | Outro

  // dropdowns
  String? _weightRange;
  String? _practiceYears;
  String? _heightRange;

  // fatores (checkbox)
  late Map<String, List<String>> _factorOptions;
  late Map<String, Set<String>> _selectedFactors;

  @override
  void initState() {
    super.initState();
    _future = AthleteService.fetchAthleteProfile();

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
    setState(() => _saving = true);

    try {
      // TODO(BACKEND): salvar no service
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

    final weightItems = _uniqueItems(const [
      'Menos de 40kg',
      'Entre 40kg e 50kg',
      'Entre 50kg e 60kg',
      'Entre 60kg e 70kg',
      'Entre 70kg e 80kg',
      'Mais de 80kg',
    ]);

    final practiceItems = _uniqueItems(const [
      'Menos de 1 ano',
      'Entre 1 e 3 anos',
      'Entre 3 e 5 anos',
      'Mais de 5 anos',
    ]);

    final heightItems = _uniqueItems(const [
      'Menos de 150cm',
      'Entre 150cm e 160cm',
      'Entre 160cm e 170cm',
      'Entre 170cm e 180cm',
      'Mais de 180cm',
    ]);

    return Scaffold(
      appBar: const TopNavbar(),
      body: SafeArea(
        child: FutureBuilder<AthleteProfile>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData) {
              return const Center(child: Text('Falha ao carregar perfil.'));
            }

            _profile ??= snap.data!;
            final profile = _profile!;

            if (_nameCtrl.text.isEmpty) _nameCtrl.text = profile.name;
            _category ??= profile.category;

            if (profile.reference != null) {
              _gender ??= profile.reference!.gender;
              _weightRange ??= profile.reference!.weightRange;
              _practiceYears ??= profile.reference!.practiceYears;
              _heightRange ??= profile.reference!.heightRange;
            }

            final safeWeight = _sanitizeDropdownValue(
              _weightRange,
              weightItems,
            );
            final safePractice = _sanitizeDropdownValue(
              _practiceYears,
              practiceItems,
            );
            final safeHeight = _sanitizeDropdownValue(
              _heightRange,
              heightItems,
            );

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

                  _DropdownField(
                    label: 'Peso',
                    value: safeWeight,
                    items: weightItems,
                    onChanged: (v) => setState(() => _weightRange = v),
                    onClear: () => setState(() => _weightRange = null),
                    scale: scale,
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
                  SizedBox(height: 12 * scale),

                  _DropdownField(
                    label: 'Altura',
                    value: safeHeight,
                    items: heightItems,
                    onChanged: (v) => setState(() => _heightRange = v),
                    onClear: () => setState(() => _heightRange = null),
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
  final double scale;
  final List<String> items;
  final Set<String> selected;
  final void Function(String label, bool checked) onToggle;
  final VoidCallback onAddNew;

  const _FactorSection({
    required this.title,
    required this.scale,
    required this.items,
    required this.selected,
    required this.onToggle,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 1 coluna (full width) — texto vai até o fim
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
            children:
                items.map((label) {
                  final checked = selected.contains(label);

                  return InkWell(
                    onTap: () => onToggle(label, !checked),
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 4 * scale),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: checked,
                            onChanged: (v) => onToggle(label, v ?? false),
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
                }).toList(),
          ),
        ],
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
