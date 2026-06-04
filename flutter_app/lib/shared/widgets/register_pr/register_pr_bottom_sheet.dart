// lib/shared/widgets/register_pr/register_pr_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_prs_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:intl/intl.dart';

/// Abre o sheet de cadastro de PR.
/// Quando [existingPr] é fornecido, opera em modo edição.
Future<void> showRegisterPrBottomSheet(
  BuildContext context, {
  AthletePr? existingPr,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => _RegisterPrSheet(
        existingPr: existingPr,
        scrollController: scrollCtrl,
      ),
    ),
  );
}

class _RegisterPrSheet extends StatefulWidget {
  final AthletePr? existingPr;
  final ScrollController scrollController;

  const _RegisterPrSheet({
    this.existingPr,
    required this.scrollController,
  });

  @override
  State<_RegisterPrSheet> createState() => _RegisterPrSheetState();
}

class _RegisterPrSheetState extends State<_RegisterPrSheet> {
  late Future<Map<String, List<Movement>>> _movementsFut;

  String? _selectedCategory;
  Movement? _selectedMovement;
  DateTime _date = DateTime.now();
  final TextEditingController _valueCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _submitting = false;

  bool get _isEditing => widget.existingPr != null;

  @override
  void initState() {
    super.initState();
    _movementsFut =
        AthletePrsService.fetchMovementsGroupedByCategory().then((grouped) {
      if (_isEditing && mounted) {
        _prefillFrom(grouped, widget.existingPr!);
      }
      return grouped;
    });
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _prefillFrom(Map<String, List<Movement>> grouped, AthletePr pr) {
    final val = pr.value % 1 == 0
        ? pr.value.toInt().toString()
        : pr.value.toStringAsFixed(1);

    String? foundCategory;
    Movement? foundMovement;
    for (final entry in grouped.entries) {
      final match = entry.value
          .cast<Movement?>()
          .firstWhere((m) => m?.id == pr.movementId, orElse: () => null);
      if (match != null) {
        foundCategory = entry.key;
        foundMovement = match;
        break;
      }
    }

    // Fallback: movimento não encontrado na coleção atual (id órfão).
    // Sintetiza um Movement a partir do PR para preencher o form.
    foundMovement ??= Movement(
      id: pr.movementId,
      displayName: pr.movementName,
      categories: const [],
      prType: pr.prType,
      supportedPrTypes: [pr.prType],
      unit: pr.unit,
    );
    foundCategory ??= grouped.keys.isNotEmpty ? grouped.keys.first : '—';

    if (!mounted) return;
    setState(() {
      _selectedCategory = foundCategory;
      _selectedMovement = foundMovement;
      _date = pr.date;
      _valueCtrl.text = val;
    });
  }

  String? _validate() {
    if (_selectedMovement == null) return 'Selecione um exercício.';
    final raw = _valueCtrl.text.replaceAll(',', '.').trim();
    final val = double.tryParse(raw);
    if (val == null || val <= 0) return 'Informe um valor válido.';
    return null;
  }

  Future<void> _handleSubmit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _submitting = true);

    try {
      final value =
          double.parse(_valueCtrl.text.replaceAll(',', '.').trim());

      if (_isEditing) {
        await AthletePrsService.updatePr(
          prId: widget.existingPr!.id,
          movement: _selectedMovement!,
          prType: _selectedMovement!.prType,
          value: value,
          date: _date,
        );
      } else {
        await AthletePrsService.submitPr(
          movement: _selectedMovement!,
          prType: _selectedMovement!.prType,
          value: value,
          date: _date,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      await Future.microtask(() {});
      if (!mounted) return;

      await showDialog(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        builder: (dCtx) => AppDialog(
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.baseBlue,
          title: _isEditing ? 'PR Atualizado!' : 'PR Registrado!',
          message:
              '${_selectedMovement!.displayName} — '
              '${_valueCtrl.text} ${_selectedMovement!.unit}',
          primaryAction: TextButton(
            onPressed: () =>
                Navigator.of(dCtx, rootNavigator: true).pop(),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
            child: const Text('OK'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _selectMovement(Movement m) {
    setState(() {
      _selectedMovement = m;
      _searchCtrl.clear();
      _searchQuery = '';
      _valueCtrl.clear();
    });
  }

  List<Movement> _filterMovements(List<Movement> all) {
    if (_searchQuery.isEmpty) return all;
    return all
        .where((m) => m.displayName.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ── Handle + Título (fixos) ──────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              16 * scale, 10 * scale, 16 * scale, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40 * scale,
                    height: 4 * scale,
                    decoration: BoxDecoration(
                      color: AppColors.mediumGray.withValues(alpha: .6),
                      borderRadius: BorderRadius.circular(2 * scale),
                    ),
                  ),
                ),
                SizedBox(height: 12 * scale),
                Text(
                  _isEditing ? 'Editar PR' : 'Registrar novo PR',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 20 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  'Selecione a categoria e o exercício para registrar seu recorde pessoal.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
                SizedBox(height: 14 * scale),
              ],
            ),
          ),

          // ── Corpo scrollável ─────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<Map<String, List<Movement>>>(
              future: _movementsFut,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final grouped = snap.data ?? {};
                if (grouped.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum exercício encontrado.',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 13 * scale,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  );
                }

                final categories = grouped.keys.toList();
                final movementsForCategory =
                    _selectedCategory != null
                        ? _filterMovements(grouped[_selectedCategory]!)
                        : <Movement>[];

                return ListView(
                  controller: widget.scrollController,
                  padding: EdgeInsets.fromLTRB(
                    16 * scale, 0, 16 * scale, 16 * scale,
                  ),
                  children: [
                    // 1. Categoria
                    _SectionLabel(label: 'Categoria', scale: scale),
                    SizedBox(height: 6 * scale),
                    _StyledDropdown<String>(
                      value: _selectedCategory,
                      hint: 'Selecione a categoria',
                      items: categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(_capitalize(c)),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedCategory = v;
                          _selectedMovement = null;
                          _searchCtrl.clear();
                          _searchQuery = '';
                          _valueCtrl.clear();
                        });
                      },
                      scale: scale,
                    ),

                    // 2. Exercício (busca + lista inline)
                    if (_selectedCategory != null) ...[
                      SizedBox(height: 14 * scale),
                      _SectionLabel(label: 'Exercício', scale: scale),
                      SizedBox(height: 6 * scale),

                      // Exercício selecionado (chip removível)
                      if (_selectedMovement != null) ...[
                        _SelectedMovementChip(
                          movement: _selectedMovement!,
                          scale: scale,
                          onClear: () {
                            setState(() {
                              _selectedMovement = null;
                              _valueCtrl.clear();
                            });
                          },
                        ),
                      ] else ...[
                        // Campo de busca
                        TextField(
                          controller: _searchCtrl,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Pesquisar exercício...',
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18 * scale,
                              color: AppColors.mediumGray,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? GestureDetector(
                                    onTap: () => _searchCtrl.clear(),
                                    child: Icon(
                                      Icons.close,
                                      size: 16 * scale,
                                      color: AppColors.mediumGray,
                                    ),
                                  )
                                : null,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10 * scale,
                              vertical: 10 * scale,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(8 * scale),
                              borderSide: const BorderSide(
                                  color: AppColors.mediumGray),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(8 * scale),
                              borderSide: const BorderSide(
                                  color: AppColors.mediumGray),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(8 * scale),
                              borderSide: const BorderSide(
                                color: AppColors.baseBlue,
                                width: 1.4,
                              ),
                            ),
                          ),
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 14 * scale,
                          ),
                        ),

                        SizedBox(height: 8 * scale),

                        // Lista de exercícios inline
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.lightGray,
                            ),
                            borderRadius:
                                BorderRadius.circular(8 * scale),
                          ),
                          child: movementsForCategory.isEmpty
                              ? Padding(
                                  padding:
                                      EdgeInsets.all(16 * scale),
                                  child: Center(
                                    child: Text(
                                      'Nenhum exercício encontrado.',
                                      style: TextStyle(
                                        fontFamily: AppFonts.roboto,
                                        fontSize: 13 * scale,
                                        color: AppColors.mediumGray,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: movementsForCategory
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    final i = entry.key;
                                    final m = entry.value;
                                    final isLast = i ==
                                        movementsForCategory
                                                .length -
                                            1;
                                    return _MovementListItem(
                                      movement: m,
                                      scale: scale,
                                      isLast: isLast,
                                      onTap: () =>
                                          _selectMovement(m),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ],

                    // 3. Valor + Data
                    if (_selectedMovement != null) ...[
                      SizedBox(height: 14 * scale),
                      _SectionLabel(
                        label: _inputLabel(_selectedMovement!.prType),
                        scale: scale,
                      ),
                      SizedBox(height: 6 * scale),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _valueCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              decoration: _fieldDecoration(
                                scale: scale,
                                suffix: _selectedMovement!.unit,
                                hint: _inputHint(
                                    _selectedMovement!.prType),
                              ),
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: 14 * scale,
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * scale),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10 * scale,
                                vertical: 9 * scale,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.mediumGray),
                                borderRadius:
                                    BorderRadius.circular(8 * scale),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14 * scale,
                                    color: AppColors.baseBlue,
                                  ),
                                  SizedBox(width: 6 * scale),
                                  Text(
                                    DateFormat('dd/MM/yyyy')
                                        .format(_date),
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
                                      fontSize: 13 * scale,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 24 * scale),

                      // Botões
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: AppTheme.secondaryButtonStyle(
                              AppColors.darkBlue,
                              AppColors.baseBlue,
                            ),
                            onPressed:
                                _submitting ? null : _handleSubmit,
                            child: _submitting
                                ? SizedBox(
                                    width: 18 * scale,
                                    height: 18 * scale,
                                    child:
                                        const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.darkBlue,
                                    ),
                                  )
                                : Text(
                                    _isEditing
                                        ? 'Salvar'
                                        : 'Registrar',
                                  ),
                          ),
                          OutlinedButton(
                            style: AppTheme.tertiaryButtonStyle(
                                AppColors.baseMagenta),
                            onPressed: () =>
                                Navigator.of(context).pop(),
                            child: const Text('Fechar'),
                          ),
                        ],
                      ),
                      SizedBox(height: 8 * scale),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _inputLabel(PrType type) => switch (type) {
        PrType.weight => 'Carga (kg)',
        PrType.reps => 'Repetições',
        PrType.time => 'Tempo (segundos)',
        PrType.distance => 'Distância (metros)',
      };

  static String _inputHint(PrType type) => switch (type) {
        PrType.weight => 'Ex: 80',
        PrType.reps => 'Ex: 15',
        PrType.time => 'Ex: 60',
        PrType.distance => 'Ex: 500',
      };

  static InputDecoration _fieldDecoration({
    required double scale,
    String? suffix,
    String? hint,
  }) {
    return InputDecoration(
      isDense: true,
      suffixText: suffix,
      hintText: hint,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 10 * scale,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * scale),
        borderSide: const BorderSide(color: AppColors.mediumGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * scale),
        borderSide: const BorderSide(color: AppColors.mediumGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8 * scale),
        borderSide: const BorderSide(
          color: AppColors.baseBlue,
          width: 1.4,
        ),
      ),
    );
  }
}

// =============================================================================
// Chip de exercício selecionado
// =============================================================================

class _SelectedMovementChip extends StatelessWidget {
  final Movement movement;
  final double scale;
  final VoidCallback onClear;

  const _SelectedMovementChip({
    required this.movement,
    required this.scale,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 10 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.baseBlue.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: AppColors.baseBlue.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          Icon(Icons.fitness_center,
              size: 16 * scale, color: AppColors.baseBlue),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.displayName,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  'PR: ${movement.prType.label} (${movement.unit})',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 11 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close,
                size: 18 * scale, color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Item da lista de exercícios
// =============================================================================

class _MovementListItem extends StatelessWidget {
  final Movement movement;
  final double scale;
  final bool isLast;
  final VoidCallback onTap;

  const _MovementListItem({
    required this.movement,
    required this.scale,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? BorderRadius.only(
              bottomLeft: Radius.circular(8 * scale),
              bottomRight: Radius.circular(8 * scale),
            )
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 11 * scale,
        ),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: AppColors.lightGray.withValues(alpha: .6),
                  ),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                movement.displayName,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 13 * scale,
                  color: AppColors.darkText,
                ),
              ),
            ),
            // Chip do tipo de PR
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6 * scale,
                vertical: 2 * scale,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(4 * scale),
              ),
              child: Text(
                movement.unit,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 10 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Widgets auxiliares
// =============================================================================

class _SectionLabel extends StatelessWidget {
  final String label;
  final double scale;
  const _SectionLabel({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: AppFonts.roboto,
        fontWeight: FontWeight.bold,
        fontSize: 12 * scale,
        color: AppColors.darkBlue,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double scale;

  const _StyledDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 4 * scale,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: AppColors.mediumGray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down,
              size: 20 * scale, color: AppColors.darkText),
          hint: Text(
            hint,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 14 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 14 * scale,
            color: AppColors.darkText,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
