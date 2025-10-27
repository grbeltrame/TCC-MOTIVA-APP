// lib/features/coach/coach_training_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/worked_muscles_section.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/cards/training_blocks_card.dart';
import 'package:flutter_app/shared/widgets/footers/coach_training_footer.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';

class CoachTrainingDetailScreen extends StatefulWidget {
  static const routeName = '/coach_training_detail';
  const CoachTrainingDetailScreen({Key? key}) : super(key: key);

  @override
  State<CoachTrainingDetailScreen> createState() =>
      _CoachTrainingDetailScreenState();
}

class _CoachTrainingDetailScreenState extends State<CoachTrainingDetailScreen> {
  late String _boxId; // manter compat até trocar service
  late DateTime _date;
  late String _category; // 'WOD', 'LPO', ...
  String? _blockId;
  String? _expectedTitle;

  TrainingBlock? _lastBlock;
  bool _bootstrapped = false;
  late Future<List<TrainingBlock>> _blocksFut;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _boxId = (args['boxId'] ?? '1') as String;
    _category = (args['category'] ?? 'WOD') as String;
    _expectedTitle = args['expectedTitle'] as String?;
    _blockId = args['blockId'] as String?; // << NEW

    final rawDate = args['date'];
    _date = (rawDate is DateTime) ? rawDate : DateTime.now();

    _blocksFut = TrainingService.fetchFullTrainingBlocks(
      boxId: _boxId,
      date: _date,
      category: _category,
    );

    _bootstrapped = true;
  }

  TrainingBlock? _chooseTargetBlock(List<TrainingBlock> blocks) {
    if (blocks.isEmpty) return null;

    // 1) Prioriza ID
    if (_blockId != null && _blockId!.isNotEmpty) {
      final i = blocks.indexWhere((b) => b.id == _blockId);
      if (i != -1) return blocks[i];
    }

    // 2) Fallback por expectedTitle (compat com passado)
    if (_expectedTitle != null && _expectedTitle!.trim().isNotEmpty) {
      final i = blocks.indexWhere(
        (b) =>
            b.title.trim().toLowerCase() ==
            _expectedTitle!.trim().toLowerCase(),
      );
      if (i != -1) return blocks[i];
    }

    // 3) Heurísticas antigas (WOD / for time / amrap)
    final wodIdx = blocks.indexWhere(
      (b) => b.title.toLowerCase().contains('wod'),
    );
    if (wodIdx != -1) return blocks[wodIdx];

    final mainIdx = blocks.indexWhere((b) {
      final t = '${b.title} ${b.subtitle}'.toLowerCase();
      return t.contains('for time') || t.contains('amrap');
    });
    if (mainIdx != -1) return blocks[mainIdx];

    // 4) Último como último recurso
    return blocks.last;
  }

  DateTime? _parseDateLeniente(String s) {
    try {
      return DateTime.parse(s);
    } catch (_) {}
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(s);
    } catch (_) {}
    return null;
  }

  void _openRegisterBoxSheet() {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  // callbacks (TODOs vazios, como combinado)
  void _onTapVerResultados() {
    /* TODO: implementar */
  }
  void _onTapComentariosDoCriador() {
    /* TODO: implementar */
  }
  void _onTapRegistrarResultado() {
    /* TODO: implementar */
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: _openRegisterBoxSheet),
      bottomNavigationBar: const BottomNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // back
          Padding(
            padding: EdgeInsets.only(
              top: 8 * scale,
              left: 6 * scale,
              right: 6 * scale,
            ),
            child: const AppBackButton(),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 10 * scale,
              ),
              child: FutureBuilder<List<TrainingBlock>>(
                future: _blocksFut,
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final blocks = snap.data!;
                  final lastBlock = _chooseTargetBlock(blocks);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TrainingBlocksCard(
                        blocks: blocks,
                        onTapRegisterResult: _onTapRegistrarResultado,
                        footer: CoachTrainingFooter(
                          onTapVerResultados: _onTapVerResultados,
                          onTapComentariosDoCriador: _onTapComentariosDoCriador,
                          onTapRegistrarResultado: _onTapRegistrarResultado,
                        ),
                      ),

                      if (lastBlock != null) ...[
                        SizedBox(height: 16 * scale),
                        WorkedMusclesSection(lastBlock: lastBlock),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
