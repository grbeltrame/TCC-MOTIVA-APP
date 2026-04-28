import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/cards/training_blocks_card.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/pre_workout_insights_section.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/worked_muscles_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';

import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
import 'package:flutter_app/core/services/effort_service.dart';

class FullTrainingScreen extends StatefulWidget {
  static const routeName = '/training_full';
  const FullTrainingScreen({Key? key}) : super(key: key);

  @override
  State<FullTrainingScreen> createState() => _FullTrainingScreenState();
}

class _FullTrainingScreenState extends State<FullTrainingScreen> {
  late String _boxId;
  late DateTime _date;
  late String _category; // 'WOD', 'LPO', ...

  bool _bootstrapped = false;
  late Future<List<TrainingBlock>> _blocksFut;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _boxId = (args['boxId'] ?? '1') as String;
    _date = (args['date'] as DateTime?) ?? DateTime.now();
    _category = (args['category'] ?? 'WOD') as String;

    _blocksFut = TrainingService.fetchFullTrainingBlocks(
      boxId: _boxId,
      date: _date,
      category: _category,
    );

    _bootstrapped = true;
  }

  TrainingBlock? _chooseLastBlock(List<TrainingBlock> blocks) {
    if (blocks.isEmpty) return null;

    // 1) tenta o bloco cujo título contenha "WOD"
    final wodIdx = blocks.indexWhere(
      (b) => b.title.toLowerCase().contains('wod'),
    );
    if (wodIdx != -1) return blocks[wodIdx];

    // 2) tenta algo que indique o bloco “principal”
    final mainIdx = blocks.indexWhere((b) {
      final t = '${b.title} ${b.subtitle}'.toLowerCase();
      return t.contains('for time') || t.contains('amrap');
    });
    if (mainIdx != -1) return blocks[mainIdx];

    // 3) fallback: último bloco da lista
    return blocks.last;
  }

  Future<void> _onTapRegisterResult() async {
    final existing = await EffortService.fetchTodayResult(
      date: _date,
      wodType: _category,
    );
    if (!mounted) return;
    await showRegisterResultBottomSheet(
      context,
      existingRecord: existing,
      initialDate: _date,
    );
    if (!mounted) return;
    setState(() {
      _blocksFut = TrainingService.fetchFullTrainingBlocks(
        boxId: _boxId,
        date: _date,
        category: _category,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

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
                  final lastBlock = _chooseLastBlock(blocks); // << calcula aqui

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Insights pré-treino: o atleta naquele tipo de treino.
                      // Foco no histórico do próprio atleta — nunca crítica
                      // à montagem do treino. A seção resolve o workoutId
                      // internamente a partir da data; se não houver treino
                      // publicado ou insights ainda, a seção fica oculta.
                      PreWorkoutInsightsSection(date: _date),
                      SizedBox(height: 12 * scale),
                      TrainingBlocksCard(
                        blocks: blocks,
                        onTapRegisterResult: _onTapRegisterResult,
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
