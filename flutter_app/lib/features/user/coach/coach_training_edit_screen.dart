// lib/features/user/coach/coach_training_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

// =============================================================================
// CONSTANTES
// =============================================================================

const _kSectionTypes = <String>['WarmUp', 'ExtraTraining', 'Skill', 'WOD'];

/// Modalidades disponíveis no selector de cada seção.
/// "ROUNDS FOR TIME" exige preenchimento do campo de rounds.
const _kModalidades = <String>['AMRAP', 'FOR TIME', 'EMOM', 'ROUNDS FOR TIME'];

// =============================================================================
// MODELOS EDITÁVEIS
// =============================================================================

class EditableMovement {
  /// Ex.: "21", "400m", "12'", "5x5"
  String reps;

  /// Apenas o nome do movimento. Ex.: "Thrusters", "Run"
  String name;

  /// Carga (opcional). Ex.: "40/25", "60kg", "Rx"
  String? load;

  EditableMovement({required this.reps, required this.name, this.load});
}

class EditableSection {
  String id;

  /// Tipo da seção: WarmUp / ExtraTraining / Skill / WOD
  String type;

  /// Nome da seção. Ex.: "SKY IS THE LIMIT"
  String? name;

  /// Tempo em minutos (opcional). Ex.: 5
  int? timeMinutes;

  /// Modalidade do treino. Ex.: "AMRAP", "FOR TIME", "ROUNDS FOR TIME"
  String? modalidade;

  /// Número de rounds — preenchido quando modalidade == "ROUNDS FOR TIME"
  int? rounds;

  final List<EditableMovement> movements;

  EditableSection({
    required this.id,
    required this.type,
    this.name,
    this.timeMinutes,
    this.modalidade,
    this.rounds,
    List<EditableMovement>? movements,
  }) : movements = movements ?? <EditableMovement>[];
}

class EditableTraining {
  final String category;
  final List<EditableSection> sections;

  EditableTraining({required this.category, List<EditableSection>? sections})
    : sections = sections ?? <EditableSection>[];
}

// =============================================================================
// TELA PRINCIPAL
// =============================================================================

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

class _CoachTrainingEditScreenState extends State<CoachTrainingEditScreen> {
  late Future<EditableTraining> _futureEditable;
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

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yy';
  }

  // ---------------------------------------------------------------------------
  // Parsing de título em nome + tempo
  // ---------------------------------------------------------------------------

  (String name, int? minutes) _splitTitleNameAndTime(String title) {
    final t = title.trim();
    final dashMin = RegExp(
      r'^(.*?)[\s\-–—]+(\d+)\s*min\s*$',
      caseSensitive: false,
    );
    final m1 = dashMin.firstMatch(t);
    if (m1 != null) {
      return (m1.group(1)!.trim(), int.tryParse(m1.group(2)!) ?? 0);
    }
    final tailMin = RegExp(r'^(.*?)[\s]+(\d+)\s*min\s*$', caseSensitive: false);
    final m2 = tailMin.firstMatch(t);
    if (m2 != null) {
      return (m2.group(1)!.trim(), int.tryParse(m2.group(2)!) ?? 0);
    }
    return (t, null);
  }

  // ---------------------------------------------------------------------------
  // Parsing de linha em movements
  // ---------------------------------------------------------------------------

  List<EditableMovement> _parseLineIntoMovements(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return const [];

    // "21-15-9 Thrusters (40/25)"
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

    // "400m Run" | "1km Row" | "12' Burpees"
    final distRe = RegExp(
      r"^\s*(\d+\s*(?:m|km|min|sec|[\x27\x22]))\s+(.+?)(?:\s*\(([^)]+)\))?\s*$",
      caseSensitive: false,
    );
    final distM = distRe.firstMatch(s);
    if (distM != null) {
      return [
        EditableMovement(
          reps: distM.group(1)!.trim(),
          name: distM.group(2)!.trim(),
          load:
              (distM.group(3)?.trim().isEmpty ?? true)
                  ? null
                  : distM.group(3)!.trim(),
        ),
      ];
    }

    // "5x5 Back Squat (60/40)"
    final setRe = RegExp(
      r'^\s*(\d+\s*x\s*\d+)\s+(.+?)(?:\s*\(([^)]+)\))?\s*$',
      caseSensitive: false,
    );
    final setM = setRe.firstMatch(s);
    if (setM != null) {
      return [
        EditableMovement(
          reps: setM.group(1)!.replaceAll(RegExp(r'\s+'), ''),
          name: setM.group(2)!.trim(),
          load:
              (setM.group(3)?.trim().isEmpty ?? true)
                  ? null
                  : setM.group(3)!.trim(),
        ),
      ];
    }

    // "5 Muscle Snatch (optionally with carga)"
    final simpleRe = RegExp(
      r'^\s*(\d+)\s+(.+?)(?:\s*\(([^)]+)\))?\s*$',
      caseSensitive: false,
    );
    final sm = simpleRe.firstMatch(s);
    if (sm != null) {
      return [
        EditableMovement(
          reps: sm.group(1)!.trim(),
          name: sm.group(2)!.trim(),
          load:
              (sm.group(3)?.trim().isEmpty ?? true)
                  ? null
                  : sm.group(3)!.trim(),
        ),
      ];
    }

    // "15|12|9|6|3 HSPU strict" — reps decrescentes separadas por pipe
    // Gerado pelo parser quando há esquema de reps em linha isolada
    // seguido do nome do exercício. Ex: "15|12|9|6|3 HSPU strict (70/50)"
    final pipeRe = RegExp(
      r'^\s*(\d+(?:\|\d+)+)\s+(.+?)(?:\s*\(([^)]+)\))?\s*$',
      caseSensitive: false,
    );
    final pipeM = pipeRe.firstMatch(s);
    if (pipeM != null) {
      return [
        EditableMovement(
          reps: pipeM.group(1)!.trim(),
          name: pipeM.group(2)!.trim(),
          load:
              (pipeM.group(3)?.trim().isEmpty ?? true)
                  ? null
                  : pipeM.group(3)!.trim(),
        ),
      ];
    }

    return [EditableMovement(reps: '', name: s, load: null)];
  }

  // ---------------------------------------------------------------------------
  // Inferência de tipo e modalidade
  // ---------------------------------------------------------------------------

  String _inferTypeFromTitle(String title) {
    final t = title.trim().toLowerCase();
    if (t.startsWith('warm') || t.contains('warm up')) return 'WarmUp';
    if (t.startsWith('skill')) return 'Skill';
    if (t.startsWith('extra')) return 'ExtraTraining';
    return 'WOD';
  }

  // ---------------------------------------------------------------------------
  // Mapeamento de blocks → EditableTraining
  // ---------------------------------------------------------------------------

  EditableTraining _mapBlocksToEditable(List<TrainingBlock> blocks) {
    final sections = <EditableSection>[];

    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final id = b.id.isNotEmpty ? b.id : 'section_$i';
      final inferredType = _inferTypeFromTitle(b.title);
      final (nameOnly, minutes) = _splitTitleNameAndTime(b.title);

      // Extrai nome limpo (remove prefixo da seção: "WOD - " → "")
      String? cleanName = nameOnly;
      for (final prefix in ['WARM UP', 'EXTRA TRAINING', 'SKILL', 'WOD']) {
        if (cleanName!.toUpperCase().startsWith(prefix)) {
          cleanName = cleanName
              .substring(prefix.length)
              .replaceFirst(RegExp(r'^[\s\-–—:]+'), '');
          break;
        }
      }
      if (cleanName!.trim().isEmpty) cleanName = null;

      // Modalidade e rounds
      // b.subtitle já contém a modalidade montada pelo fetchFullTrainingBlocks
      // mas para maior precisão usamos _inferModalidadeFromPart com o dado raw
      final subtitleModalidade = _inferModalidadeFromSubtitle(b.subtitle);
      final (modalidade, rounds) = subtitleModalidade;

      final movements = <EditableMovement>[];
      for (final raw in b.items) {
        movements.addAll(_parseLineIntoMovements(raw));
      }

      sections.add(
        EditableSection(
          id: id,
          type: inferredType,
          name: cleanName,
          timeMinutes: minutes,
          modalidade: modalidade,
          rounds: rounds,
          movements: movements,
        ),
      );
    }

    if (sections.isEmpty) {
      sections.add(EditableSection(id: 'section_0', type: 'WOD'));
    }

    return EditableTraining(category: widget.category, sections: sections);
  }

  /// Extrai modalidade e rounds do subtitle do TrainingBlock.
  /// Ex: "3 ROUNDS FOR TIME (20 min)" → ("ROUNDS FOR TIME", 3)
  /// Ex: "AMRAP (5 min)"              → ("AMRAP", null)
  (String? modalidade, int? rounds) _inferModalidadeFromSubtitle(
    String subtitle,
  ) {
    final s = subtitle.trim().toUpperCase();

    final roundsForTime = RegExp(
      r'^(\d+)\s+ROUNDS?\s+FOR\s+TIME',
    ).firstMatch(s);
    if (roundsForTime != null) {
      return ('ROUNDS FOR TIME', int.tryParse(roundsForTime.group(1)!));
    }

    if (s.contains('AMRAP')) return ('AMRAP', null);
    if (s.contains('EMOM')) return ('EMOM', null);
    if (s.contains('FOR TIME')) return ('FOR TIME', null);

    return (null, null);
  }

  // ---------------------------------------------------------------------------
  // Carregamento e persistência
  // ---------------------------------------------------------------------------

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
      trainingId: highlightBlockId,
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

  Future<void> _persistEditedTraining(EditableTraining edited) async {
    String? realDocId;
    if (widget.highlightBlockId != null &&
        widget.highlightBlockId!.contains('__')) {
      realDocId = widget.highlightBlockId!.split('__')[0];
    } else {
      realDocId = widget.highlightBlockId;
    }

    await TrainingService.updateTrainingFromEditable(
      boxId: widget.boxId,
      date: widget.date,
      category: widget.category,
      edited: edited,
      docId: realDocId,
    );
  }

  Future<void> _onConfirmPressed() async {
    final edited = _currentEdited;
    if (edited == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _persistEditedTraining(edited);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Treino atualizado com sucesso!'),
          backgroundColor: AppColors.baseBlue,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha ao salvar treino: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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

            _currentEdited ??= snap.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    12 * scale,
                    4 * scale,
                    12 * scale,
                    8 * scale,
                  ),
                  child: Text(
                    'Você está editando o treino\n'
                    'do dia ${_fmtDate(widget.date)} da categoria ${widget.category}',
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

// =============================================================================
// _EditBody — lista de seções com drag para reordenar seções
// =============================================================================

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

  void _notify() => widget.onEditedChanged(_edited);

  void _addSection() {
    final id = 'section_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _edited.sections.add(
        EditableSection(
          id: id,
          type: 'WOD',
          name: null,
          timeMinutes: null,
          modalidade: null,
          rounds: null,
          movements: [],
        ),
      );
    });
    _notify();
  }

  void _removeSection(String id) {
    setState(() => _edited.sections.removeWhere((s) => s.id == id));
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

// =============================================================================
// _SectionEditorCard — card de edição de uma seção
// =============================================================================

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
    final set = <String>{..._kSectionTypes, current};
    return set.toList();
  }

  /// Ao reordenar no ReorderableListView, Flutter passa o new_index
  /// ANTES de remover o item, então ajustamos aqui.
  void _onReorderMovements(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = widget.section.movements.removeAt(oldIndex);
      widget.section.movements.insert(newIndex, item);
    });
    widget.onChanged?.call();
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
    if (RegExp(r'^(rx|r[xX])$', caseSensitive: false).hasMatch(v)) return true;
    return RegExp(r'\d').hasMatch(v) ||
        v.contains('/') ||
        RegExp(r'(kg|lb)', caseSensitive: false).hasMatch(v);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final typeItems =
        _typesWithCurrent(widget.section.type)
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList();

    // Opções de modalidade: null (Nenhuma) + lista de modalidades
    final modalidadeItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('— Nenhuma —')),
      ..._kModalidades.map(
        (e) => DropdownMenuItem<String?>(value: e, child: Text(e)),
      ),
    ];

    final bool needsRounds = widget.section.modalidade == 'ROUNDS FOR TIME';

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
          // ── Linha 1: Tipo da seção + botão deletar ──────────────────────
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.section.type,
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

          // ── Nome da seção ────────────────────────────────────────────────
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

          // ── Tempo (minutos) ──────────────────────────────────────────────
          TextFormField(
            initialValue:
                widget.section.timeMinutes != null
                    ? '${widget.section.timeMinutes}'
                    : '',
            onChanged: (v) {
              setState(() => widget.section.timeMinutes = int.tryParse(v));
              widget.onChanged?.call();
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Tempo (min, opcional)',
            ),
          ),
          SizedBox(height: 8 * scale),

          // ── Modalidade ───────────────────────────────────────────────────
          DropdownButtonFormField<String?>(
            value: widget.section.modalidade,
            items: modalidadeItems,
            onChanged: (val) {
              setState(() {
                widget.section.modalidade = val;
                // Limpa rounds se a nova modalidade não precisar
                if (val != 'ROUNDS FOR TIME') {
                  widget.section.rounds = null;
                }
              });
              widget.onChanged?.call();
            },
            decoration: const InputDecoration(
              labelText: 'Modalidade (ex: AMRAP, FOR TIME)',
            ),
          ),
          SizedBox(height: 8 * scale),

          // ── Rounds — só aparece quando modalidade == ROUNDS FOR TIME ─────
          if (needsRounds) ...[
            TextFormField(
              initialValue:
                  widget.section.rounds != null
                      ? '${widget.section.rounds}'
                      : '',
              onChanged: (v) {
                setState(() => widget.section.rounds = int.tryParse(v));
                widget.onChanged?.call();
              },
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Número de rounds',
                hintText: 'Ex: 3',
              ),
            ),
            SizedBox(height: 8 * scale),
          ],

          SizedBox(height: 4 * scale),

          // ── Título da lista de movimentos ────────────────────────────────
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

          // ── Lista de movimentos com drag & drop ──────────────────────────
          // ReorderableListView em modo não-scrollável dentro do CustomScrollView.
          // Cada linha tem um handle à esquerda para arrastar.
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.section.movements.length,
            onReorder: _onReorderMovements,
            proxyDecorator: (child, index, animation) {
              // Eleva visualmente o item sendo arrastado
              return Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: child,
              );
            },
            itemBuilder: (ctx, i) {
              final mov = widget.section.movements[i];
              return _MovementRow(
                // ObjectKey(mov): o state segue o OBJETO após reorder,
                // não o índice. Corrige o bug visual do drag & drop.
                key: ObjectKey(mov),
                index: i,
                movement: mov,
                onChanged: () => setState(() {}),
                onDelete: () => _removeMovement(i),
                hintLoadStyle: TextStyle(
                  color: AppColors.mediumGray.withValues(alpha: 0.7),
                ),
                looksLikeLoad: _looksLikeLoad(mov.load),
              );
            },
          ),

          // ── Botão adicionar movimento ────────────────────────────────────
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

// =============================================================================
// _MovementRow — linha de um movimento com handle de drag
// =============================================================================

class _MovementRow extends StatefulWidget {
  const _MovementRow({
    super.key,
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
  // Controllers evitam o bug do initialValue:
  // initialValue só é lido na CRIAÇÃO do widget. Após um reorder com
  // ObjectKey, o mesmo state é reutilizado pelo mesmo objeto, e os
  // controllers mantêm o texto correto sem precisar de rebuild.
  late TextEditingController _repsCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _loadCtrl;

  @override
  void initState() {
    super.initState();
    _repsCtrl = TextEditingController(text: widget.movement.reps);
    _nameCtrl = TextEditingController(text: widget.movement.name);
    _loadCtrl = TextEditingController(text: widget.movement.load ?? '');
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    _nameCtrl.dispose();
    _loadCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final loadEnabled =
        widget.looksLikeLoad ||
        (widget.movement.load?.trim().isNotEmpty ?? false);

    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        children: [
          // Handle de drag — o ReorderableListView usa isso para iniciar o arraste
          ReorderableDragStartListener(
            index: widget.index,
            child: Icon(
              Icons.drag_handle,
              color: AppColors.mediumGray,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 4 * scale),

          // Reps
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _repsCtrl,
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
          SizedBox(width: 6 * scale),

          // Nome do movimento
          Expanded(
            flex: 4,
            child: TextFormField(
              controller: _nameCtrl,
              onChanged: (v) {
                setState(() => widget.movement.name = v);
                widget.onChanged();
              },
              decoration: const InputDecoration(labelText: 'Movimento'),
            ),
          ),
          SizedBox(width: 6 * scale),

          // Carga (opcional)
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _loadCtrl,
              onChanged: (v) {
                final val = v.trim();
                setState(() => widget.movement.load = val.isEmpty ? null : val);
                widget.onChanged();
              },
              decoration: InputDecoration(
                labelText: 'Carga',
                hintStyle: widget.hintLoadStyle,
                filled: !loadEnabled,
                fillColor:
                    !loadEnabled
                        ? AppColors.lightGray.withValues(alpha: 0.35)
                        : null,
              ),
            ),
          ),

          SizedBox(width: 2 * scale),
          IconButton(
            onPressed: widget.onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Remover movimento',
          ),
        ],
      ),
    );
  }
}
