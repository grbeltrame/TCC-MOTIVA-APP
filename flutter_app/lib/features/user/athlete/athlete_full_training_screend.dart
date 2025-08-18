import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/cards/training_blocks_card.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/worked_muscles_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';

import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';

import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';

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
  TrainingBlock? _lastBlock; // <- aqui

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

  void _openRegisterBoxSheet() {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  Future<void> _onTapRegisterResult() async {
    await showRegisterResultBottomSheet(context);
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
                  final lastBlock = _chooseLastBlock(blocks); // << calcula aqui

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TrainingBlocksCard(
                        blocks: blocks,
                        onTapRegisterResult: _onTapRegisterResult,
                      ),
                      if (lastBlock != null) ...[
                        SizedBox(height: 16 * scale),
                        WorkedMusclesSection(
                          lastBlock: lastBlock,
                        ), // << aparece no scroll
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
