// lib/features/user/coach/coach_training_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';

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
  String name;
  String quantity;
  String? unit;

  EditableMovement({required this.name, this.quantity = '', this.unit});
}

class EditableSection {
  String id;
  String type; // WarmUp/ExtraTraining/Skill/WOD
  String? name;
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

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yy';
  }

  /// Separa "quantidade" e "movimento" a partir de uma linha
  (String qty, String name) _splitQtyAndName(String line) {
    final s = line.trim();
    if (s.isEmpty) return ('', '');

    // 21-15-9 Thrusters
    final dashRe = RegExp(r'^\s*(\d+(?:-\d+)+)\s+(.+)$');
    final dashM = dashRe.firstMatch(s);
    if (dashM != null) {
      return (dashM.group(1)!.trim(), dashM.group(2)!.trim());
    }

    // 5x5 Back Squat
    final setRe = RegExp(r'^\s*(\d+\s*x\s*\d+)\s+(.+)$', caseSensitive: false);
    final setM = setRe.firstMatch(s);
    if (setM != null) {
      return (
        setM.group(1)!.replaceAll(RegExp(r'\s+'), ''),
        setM.group(2)!.trim(),
      );
    }

    // 3 rounds (of) ...
    final roundsRe = RegExp(
      r'^\s*(\d+)\s*rounds?(?:\s*of)?[:\-]?\s*(.*)$',
      caseSensitive: false,
    );
    final roundsM = roundsRe.firstMatch(s);
    if (roundsM != null) {
      return (
        '${roundsM.group(1)!.trim()} rounds',
        (roundsM.group(2) ?? '').trim(),
      );
    }

    // EMOM/AMRAP/For time/For load + tempo opcional (12', 10min, etc)
    // ⚠️ Usa raw string com ASPAS DUPLAS por causa do apóstrofo
    final schemeRe = RegExp(
      r"^\s*(amrap|emom|for\s*time|for\s*load)\s*([0-9]+'?(?:\s*min)?)?[:\-]?\s*(.*)$",
      caseSensitive: false,
    );
    final schemeM = schemeRe.firstMatch(s);
    if (schemeM != null) {
      final head = schemeM
          .group(1)!
          .toUpperCase()
          .replaceAll(RegExp(r'\s+'), ' ');
      final time = (schemeM.group(2) ?? '').trim();
      final rest = (schemeM.group(3) ?? '').trim();
      final qty = time.isNotEmpty ? '$head $time' : head;
      return (qty, rest);
    }

    // 10 reps Pull-ups | 400m Run | 10 cal Row | 1km Run
    final unitRe = RegExp(
      r'^\s*(\d+\s*(?:reps?|cal|m|km|min|minutes?))\b[\s\:]*([^\n].*)$',
      caseSensitive: false,
    );
    final unitM = unitRe.firstMatch(s);
    if (unitM != null) {
      return (unitM.group(1)!.trim(), (unitM.group(2) ?? '').trim());
    }

    return ('', s);
  }

  EditableTraining _mapBlocksToEditable(List<TrainingBlock> blocks) {
    final sections = <EditableSection>[];

    String _inferTypeFromTitle(String title) {
      final t = title.trim().toLowerCase();
      if (t.startsWith('warm') || t.contains('warm up')) return 'WarmUp';
      if (t.startsWith('skill')) return 'Skill';
      if (t.startsWith('extra')) return 'ExtraTraining';
      return 'WOD';
    }

    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final id = 'section_$i';
      final inferredType = _inferTypeFromTitle(b.title);

      final movements = <EditableMovement>[];
      for (final raw in b.items) {
        final line = raw.trim();
        if (line.isEmpty) continue;
        final (qty, name) = _splitQtyAndName(line);
        movements.add(EditableMovement(name: name, quantity: qty));
      }

      sections.add(
        EditableSection(
          id: id,
          type: inferredType,
          name: b.title.trim().isNotEmpty ? b.title : null,
          timeMinutes: null,
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

  Future<void> _onConfirm(EditableTraining edited) async {
    // TODO: enviar "edited" para o backend consolidando TODAS as sections em blocks
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Treino atualizado (mock). TODO: persistir no backend)',
        ),
        backgroundColor: AppColors.baseBlue,
      ),
    );
    Navigator.of(context).pop(edited);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Você está editando o treino\ndo dia ${_fmtDate(widget.date)} da categoria ${widget.category}',
          style: const TextStyle(fontSize: 14),
        ),
        toolbarHeight: 64,
      ),
      body: FutureBuilder<EditableTraining>(
        future: _futureEditable,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(child: Text('Falha ao carregar treino.'));
          }

          final editable = snap.data!;
          return _EditBody(editable: editable, onConfirm: _onConfirm);
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + 4 * scale),
          child: SizedBox(
            width: double.infinity,
            height: 46 * scale,
            child: ElevatedButton(
              onPressed: () async {
                final editable = await _futureEditable;
                await _onConfirm(editable);
              },
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
  const _EditBody({required this.editable, required this.onConfirm});

  final EditableTraining editable;
  final Future<void> Function(EditableTraining edited) onConfirm;

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
  }

  void _removeSection(String id) {
    setState(() {
      _edited.sections.removeWhere((s) => s.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12 * scale),
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
                onChanged: () => setState(() {}),
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
      widget.section.movements.add(EditableMovement(name: '', quantity: ''));
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

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final typeItems =
        _typesWithCurrent(widget.section.type)
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.lightGray),
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3 * scale,
            offset: Offset(0, 1 * scale),
          ),
        ],
      ),
      padding: EdgeInsets.all(12 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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

          // Nome (título do bloco)
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

          // Tempo (minutos)
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

          // Movimentos
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
  });

  final int index;
  final EditableMovement movement;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  @override
  State<_MovementRow> createState() => _MovementRowState();
}

class _MovementRowState extends State<_MovementRow> {
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Row(
      children: [
        // Quantidade
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: widget.movement.quantity,
            onChanged: (v) {
              setState(() => widget.movement.quantity = v);
              widget.onChanged();
            },
            decoration: const InputDecoration(
              labelText: "Qtd (ex.: 21-15-9 / 5x5 / 10 reps / 400m / EMOM 12')",
            ),
          ),
        ),
        SizedBox(width: 8 * scale),

        // Movimento
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

        // Unidade (opcional)
        Expanded(
          flex: 2,
          child: TextFormField(
            initialValue: widget.movement.unit ?? '',
            onChanged: (v) {
              setState(
                () => widget.movement.unit = v.trim().isNotEmpty ? v : null,
              );
              widget.onChanged();
            },
            decoration: const InputDecoration(labelText: 'Unid. (opcional)'),
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
