// lib/features/user/coach/coach_training_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

class CoachTrainingEditScreen extends StatefulWidget {
  static const routeName = '/coach_training_edit';

  const CoachTrainingEditScreen({
    super.key,
    required this.boxId,
    required this.date,
    required this.category,
    this.highlightBlockId,
  });

  final String boxId;
  final DateTime date;
  final String category;
  final String? highlightBlockId;

  static CoachTrainingEditScreen fromArgs(RouteSettings settings) {
    final args = (settings.arguments ?? {}) as Map;
    return CoachTrainingEditScreen(
      boxId: args['boxId']?.toString() ?? 'DEFAULT_BOX',
      date:
          args['date'] is DateTime ? args['date'] as DateTime : DateTime.now(),
      category: args['category']?.toString() ?? 'WOD',
      highlightBlockId: args['blockId']?.toString(),
    );
  }

  @override
  State<CoachTrainingEditScreen> createState() =>
      _CoachTrainingEditScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo editável
// ─────────────────────────────────────────────────────────────────────────────

const _kSectionTypes = <String>['WarmUp', 'ExtraTraining', 'Skill', 'WOD'];

class EditableMovement {
  /// Ex.: "21", "400m", "12'", "5x5", "21-15-9" (mas aqui a gente já separa em linhas)
  String reps;

  /// Apenas o nome do movimento. Ex.: "Thrusters", "Muscle Snatch", "Run"
  String name;

  /// Carga (opcional). Ex.: "40/25", "60kg", "Rx", etc.
  String? load;

  EditableMovement({required this.reps, required this.name, this.load});
}

class EditableSection {
  String id;
  String type; // WarmUp/ExtraTraining/Skill/WOD

  /// Nome da seção SEM tempo (ex.: "WOD - Fran")
  String? name;

  /// Tempo (minutos) separado (ex.: 5)
  int? timeMinutes;

  final List<EditableMovement> movements;

  EditableSection({
    required this.id,
    required this.type,
    this.name,
    this.timeMinutes,
    List<EditableMovement>? movements,
  }) : movements = movements ?? <EditableMovement>[];
}

class EditableTraining {
  final String category;
  final List<EditableSection> sections;

  EditableTraining({required this.category, List<EditableSection>? sections})
    : sections = sections ?? <EditableSection>[];
}

// ─────────────────────────────────────────────────────────────────────────────

class _CoachTrainingEditScreenState extends State<CoachTrainingEditScreen> {
  late Future<EditableTraining> _futureEditable;

  /// Mantém sempre o último estado editado vindo do _EditBody.
  EditableTraining? _currentEdited;

  @override
  void initState() {
    super.initState();
    _futureEditable = _loadEditableFromService(
      boxId: widget.boxId,
      date: widget.date,
      category: widget.category,
      highlightBlockId: widget.highlightBlockId,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // AppBar solicitado
  // ───────────────────────────────────────────────────────────────────────────

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  // ───────────────────────────────────────────────────────────────────────────

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yy';
  }

  // ── Parsers ────────────────────────────────────────────────────────────────

  /// Divide título em nome + tempo. Exemplos:
  /// "Warm Up - 5 min" => ("Warm Up", 5)
  /// "WarmUp 10min"    => ("WarmUp", 10)
  /// "WOD - Fran"      => ("WOD - Fran", null)
  (String name, int? minutes) _splitTitleNameAndTime(String title) {
    final t = title.trim();

    // ... - 5 min | ... - 10min
    final dashMin = RegExp(
      r'^(.*?)[\s\-–—]+(\d+)\s*min\s*$',
      caseSensitive: false,
    );
    final m1 = dashMin.firstMatch(t);
    if (m1 != null) {
      return (m1.group(1)!.trim(), int.tryParse(m1.group(2)!) ?? 0);
    }

    // ... 5 min | ... 10min
    final tailMin = RegExp(r'^(.*?)[\s]+(\d+)\s*min\s*$', caseSensitive: false);
    final m2 = tailMin.firstMatch(t);
    if (m2 != null) {
      return (m2.group(1)!.trim(), int.tryParse(m2.group(2)!) ?? 0);
    }

    return (t, null);
  }

  /// "21-15-9 Thrusters (40/25)" → 3 linhas:
  ///   (21, Thrusters, 40/25), (15, Thrusters, 40/25), (9, Thrusters, 40/25)
  ///
  /// "5 Muscle Snatch" → (5, Muscle Snatch, null)
  /// "400m Run" → (400m, Run, null)
  List<EditableMovement> _parseLineIntoMovements(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return const [];

    // 21-15-9 Thrusters (40/25)
    final dashRe = RegExp(
      r'^\s*(\d+(?:-\d+)+)\s+([A-Za-z].*?)(?:\s*\(([^)]+)\))?\s*$',
    );
    final dashM = dashRe.firstMatch(s);
    if (dashM != null) {
      final repsSeq = dashM
          .group(1)!
          .split('-')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);
      final name = dashM.group(2)!.trim();
      final load = dashM.group(3)?.trim();

      return repsSeq
          .map(
            (r) => EditableMovement(
              reps: r,
              name: name,
              load: (load?.trim().isEmpty ?? true) ? null : load!.trim(),
            ),
          )
          .toList();
    }

    // 400m Run | 1km Row | 12' Burpees
    final distRe = RegExp(
      r"^\s*(\d+\s*(?:m|km|min|sec|[\x27\x22]))\s+(.+?)(?:\s*\(([^)]+)\))?\s*$",
      caseSensitive: false,
    );
    final distM = distRe.firstMatch(s);
    if (distM != null) {
      final reps = distM.group(1)!.trim();
      final name = distM.group(2)!.trim();
      final load = distM.group(3)?.trim();

      return [
        EditableMovement(
          reps: reps,
          name: name,
          load: (load?.trim().isEmpty ?? true) ? null : load!.trim(),
        ),
      ];
    }

    // 5x5 Back Squat (60/40) → reps "5x5"
    final setRe = RegExp(
      r'^\s*(\d+\s*x\s*\d+)\s+(.+?)(?:\s*\(([^)]+)\))?\s*$',
      caseSensitive: false,
    );
    final setM = setRe.firstMatch(s);
    if (setM != null) {
      final reps = setM.group(1)!.replaceAll(RegExp(r'\s+'), '');
      final name = setM.group(2)!.trim();
      final load = setM.group(3)?.trim();

      return [
        EditableMovement(
          reps: reps,
          name: name,
          load: (load?.trim().isEmpty ?? true) ? null : load!.trim(),
        ),
      ];
    }

    // 5 Muscle Snatch (opcionalmente com carga)
    final simpleRe = RegExp(
      r'^\s*(\d+)\s+(.+?)(?:\s*\(([^)]+)\))?\s*$',
      caseSensitive: false,
    );
    final sm = simpleRe.firstMatch(s);
    if (sm != null) {
      final reps = sm.group(1)!.trim();
      final name = sm.group(2)!.trim();
      final load = sm.group(3)?.trim();

      return [
        EditableMovement(
          reps: reps,
          name: name,
          load: (load?.trim().isEmpty ?? true) ? null : load!.trim(),
        ),
      ];
    }

    // fallback: trata tudo como nome
    return [EditableMovement(reps: '', name: s, load: null)];
  }

  String _inferTypeFromTitle(String title) {
    final t = title.trim().toLowerCase();
    if (t.startsWith('warm') || t.contains('warm up')) return 'WarmUp';
    if (t.startsWith('skill')) return 'Skill';
    if (t.startsWith('extra')) return 'ExtraTraining';
    return 'WOD';
  }

  EditableTraining _mapBlocksToEditable(List<TrainingBlock> blocks) {
    final sections = <EditableSection>[];

    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final id = b.id.isNotEmpty ? b.id : 'section_$i';

      final inferredType = _inferTypeFromTitle(b.title);
      final (nameOnly, minutes) = _splitTitleNameAndTime(b.title);

      final movements = <EditableMovement>[];
      for (final raw in b.items) {
        final parsed = _parseLineIntoMovements(raw);
        movements.addAll(parsed);
      }

      sections.add(
        EditableSection(
          id: id,
          type: inferredType,
          name: nameOnly.isNotEmpty ? nameOnly : null,
          timeMinutes: minutes,
          movements: movements,
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(
        EditableSection(
          id: 'section_0',
          type: 'WOD',
          name: null,
          timeMinutes: null,
          movements: [],
        ),
      );
    }

    return EditableTraining(category: widget.category, sections: sections);
  }

  Future<EditableTraining> _loadEditableFromService({
    required String boxId,
    required DateTime date,
    required String category,
    String? highlightBlockId,
  }) async {
    final blocks = await TrainingService.fetchFullTrainingBlocks(
      boxId: boxId,
      date: date,
      category: category,
    );

    if (highlightBlockId != null && highlightBlockId.isNotEmpty) {
      blocks.sort((a, b) {
        if (a.id == highlightBlockId) return -1;
        if (b.id == highlightBlockId) return 1;
        return 0;
      });
    }

    return _mapBlocksToEditable(blocks);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Persistência REAL
  // ───────────────────────────────────────────────────────────────────────────

  Future<void> _persistEditedTraining(EditableTraining edited) async {
    // 🔥 Chama a função que salva e reseta o status para 'pendente'
    await TrainingService.updateTrainingFromEditable(
      boxId: widget.boxId,
      date: widget.date,
      category: widget.category,
      edited: edited,
    );
  }

  Future<void> _onConfirmPressed() async {
    final edited = _currentEdited;
    if (edited == null) return;

    // Loading...
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _persistEditedTraining(edited);

      if (!mounted) return;
      // Fecha o loading
      Navigator.of(context).pop();

      // Mostra sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Treino atualizado com sucesso!'),
          backgroundColor: AppColors.baseBlue,
        ),
      );

      // Fecha a tela e retorna true para dar refresh na lista anterior
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Fecha loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao salvar treino: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),
      body: SafeArea(
        child: FutureBuilder<EditableTraining>(
          future: _futureEditable,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || !snap.hasData) {
              return const Center(child: Text('Falha ao carregar treino.'));
            }

            // primeira carga: se ainda não tem estado editado, inicia
            _currentEdited ??= snap.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // BACK BUTTON
                Padding(
                  padding: EdgeInsets.only(
                    top: 8 * scale,
                    left: 6 * scale,
                    right: 6 * scale,
                  ),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: AppBackButton(),
                  ),
                ),

                // TÍTULO
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12 * scale,
                    4 * scale,
                    12 * scale,
                    8 * scale,
                  ),
                  child: Text(
                    'Você está editando o treino\ndo dia ${_fmtDate(widget.date)} da categoria ${widget.category}',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 14 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                ),

                Expanded(
                  child: _EditBody(
                    editable: _currentEdited!,
                    onEditedChanged: (edited) {
                      _currentEdited = edited;
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + 4 * scale),
          child: SizedBox(
            width: double.infinity,
            height: 46 * scale,
            child: ElevatedButton(
              onPressed: _onConfirmPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.baseBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * scale),
                ),
                textStyle: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 14 * scale,
                ),
              ),
              child: const Text('Confirmar'),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _EditBody extends StatefulWidget {
  const _EditBody({required this.editable, required this.onEditedChanged});

  final EditableTraining editable;
  final ValueChanged<EditableTraining> onEditedChanged;

  @override
  State<_EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends State<_EditBody> {
  late EditableTraining _edited;

  @override
  void initState() {
    super.initState();
    _edited = widget.editable;
  }

  void _notify() {
    widget.onEditedChanged(_edited);
  }

  void _addSection() {
    final id = 'section_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _edited.sections.add(
        EditableSection(
          id: id,
          type: 'WOD',
          name: null,
          timeMinutes: null,
          movements: [],
        ),
      );
    });
    _notify();
  }

  void _removeSection(String id) {
    setState(() {
      _edited.sections.removeWhere((s) => s.id == id);
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 * scale),
          sliver: SliverList.separated(
            itemCount: _edited.sections.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: 10 * scale),
            itemBuilder: (ctx, index) {
              if (index == _edited.sections.length) {
                return OutlinedButton.icon(
                  onPressed: _addSection,
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar seção'),
                );
              }

              final section = _edited.sections[index];
              return _SectionEditorCard(
                key: ValueKey(section.id),
                section: section,
                onDelete: () => _removeSection(section.id),
                onChanged: () {
                  setState(() {});
                  _notify();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionEditorCard extends StatefulWidget {
  const _SectionEditorCard({
    super.key,
    required this.section,
    required this.onDelete,
    this.onChanged,
  });

  final EditableSection section;
  final VoidCallback onDelete;
  final VoidCallback? onChanged;

  @override
  State<_SectionEditorCard> createState() => _SectionEditorCardState();
}

class _SectionEditorCardState extends State<_SectionEditorCard> {
  List<String> _typesWithCurrent(String current) {
    final set = <String>{..._kSectionTypes};
    set.add(current);
    return set.toList();
  }

  void _addMovement() {
    setState(() {
      widget.section.movements.add(
        EditableMovement(reps: '', name: '', load: null),
      );
    });
    widget.onChanged?.call();
  }

  void _removeMovement(int idx) {
    setState(() {
      if (idx >= 0 && idx < widget.section.movements.length) {
        widget.section.movements.removeAt(idx);
      }
    });
    widget.onChanged?.call();
  }

  bool _looksLikeLoad(String? load) {
    if (load == null) return false;
    final v = load.trim();
    if (v.isEmpty) return false;

    // "40/25", "60", "60kg", "Rx"
    final rx = RegExp(r'^(rx|r[xX])$', caseSensitive: false);
    if (rx.hasMatch(v)) return true;

    final hasDigit = RegExp(r'\d').hasMatch(v);
    final hasSlash = v.contains('/');
    final hasKgLb = RegExp(r'(kg|lb)', caseSensitive: false).hasMatch(v);

    return hasDigit || hasSlash || hasKgLb;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final typeItems =
        _typesWithCurrent(widget.section.type)
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList();

    final hintLoad = TextStyle(
      color: AppColors.mediumGray.withValues(alpha: 0.7),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 3 * scale,
            offset: Offset(0, 1 * scale),
          ),
        ],
      ),
      padding: EdgeInsets.all(12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: tipo + delete
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: widget.section.type,
                  items: typeItems,
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => widget.section.type = val);
                    widget.onChanged?.call();
                  },
                  decoration: const InputDecoration(labelText: 'Tipo da seção'),
                ),
              ),
              SizedBox(width: 8 * scale),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Apagar seção',
              ),
            ],
          ),
          SizedBox(height: 8 * scale),

          // Nome (limpo, sem tempo)
          TextFormField(
            initialValue: widget.section.name ?? '',
            onChanged: (v) {
              setState(
                () => widget.section.name = v.trim().isNotEmpty ? v : null,
              );
              widget.onChanged?.call();
            },
            decoration: const InputDecoration(
              labelText: 'Nome da seção (opcional)',
            ),
          ),
          SizedBox(height: 8 * scale),

          // Tempo (minutos) — separado
          TextFormField(
            initialValue:
                widget.section.timeMinutes != null
                    ? '${widget.section.timeMinutes}'
                    : '',
            onChanged: (v) {
              final n = int.tryParse(v);
              setState(() => widget.section.timeMinutes = n);
              widget.onChanged?.call();
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Tempo (min, opcional)',
            ),
          ),
          SizedBox(height: 12 * scale),

          Text(
            'Movimentos',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 14 * scale,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 6 * scale),

          for (int i = 0; i < widget.section.movements.length; i++) ...[
            _MovementRow(
              index: i,
              movement: widget.section.movements[i],
              onChanged: () => setState(() {}),
              onDelete: () => _removeMovement(i),
              hintLoadStyle: hintLoad,
              looksLikeLoad: _looksLikeLoad(widget.section.movements[i].load),
            ),
            SizedBox(height: 8 * scale),
          ],

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addMovement,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar movimento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovementRow extends StatefulWidget {
  const _MovementRow({
    required this.index,
    required this.movement,
    required this.onChanged,
    required this.onDelete,
    required this.hintLoadStyle,
    required this.looksLikeLoad,
  });

  final int index;
  final EditableMovement movement;
  final VoidCallback onChanged;
  final VoidCallback onDelete;
  final TextStyle hintLoadStyle;
  final bool looksLikeLoad;

  @override
  State<_MovementRow> createState() => _MovementRowState();
}

class _MovementRowState extends State<_MovementRow> {
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final loadEnabled =
        widget.looksLikeLoad ||
        (widget.movement.load?.trim().isNotEmpty ?? false);

    return Row(
      children: [
        // Reps
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: widget.movement.reps,
            onChanged: (v) {
              setState(() => widget.movement.reps = v);
              widget.onChanged();
            },
            decoration: const InputDecoration(
              labelText: 'Reps',
              hintText: "ex.: 21 | 400m | 12'",
            ),
          ),
        ),
        SizedBox(width: 8 * scale),

        // Movimento (apenas o nome)
        Expanded(
          flex: 4,
          child: TextFormField(
            initialValue: widget.movement.name,
            onChanged: (v) {
              setState(() => widget.movement.name = v);
              widget.onChanged();
            },
            decoration: const InputDecoration(labelText: 'Movimento'),
          ),
        ),
        SizedBox(width: 8 * scale),

        // Carga (opcional)
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: widget.movement.load ?? '',
            onChanged: (v) {
              final val = v.trim();
              setState(() => widget.movement.load = val.isEmpty ? null : val);
              widget.onChanged();
            },
            enabled: true,
            decoration: InputDecoration(
              labelText: 'Carga',
              hintText: '',
              hintStyle: widget.hintLoadStyle,
              filled: !loadEnabled,
              fillColor:
                  !loadEnabled
                      ? AppColors.lightGray.withValues(alpha: 0.35)
                      : null,
            ),
          ),
        ),

        SizedBox(width: 4 * scale),
        IconButton(
          onPressed: widget.onDelete,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Remover movimento',
        ),
      ],
    );
  }
}
