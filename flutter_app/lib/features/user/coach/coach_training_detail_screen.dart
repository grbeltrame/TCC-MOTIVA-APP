// lib/features/coach/coach_training_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/training.dart'; // <--- IMPORTANTE
import 'package:flutter_app/shared/widgets/sections/athlete/worked_muscles_section.dart';
// import 'package:flutter_app/shared/widgets/sections/coach/coach_interested_per_class_section.dart'; // (Se não estiver usando, pode manter comentado)
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/cards/training_blocks_card.dart';
import 'package:flutter_app/shared/widgets/footers/coach_training_footer.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/core/constants/app_colors.dart'; // Para cores do botão

class CoachTrainingDetailScreen extends StatefulWidget {
  static const routeName = '/coach_training_detail';
  const CoachTrainingDetailScreen({Key? key}) : super(key: key);

  @override
  State<CoachTrainingDetailScreen> createState() =>
      _CoachTrainingDetailScreenState();
}

class _CoachTrainingDetailScreenState extends State<CoachTrainingDetailScreen> {
  late String _boxId;
  late DateTime _date;
  late String _category;
  String? _blockId;
  String? _expectedTitle;

  // 1. Armazena o objeto Treino para passar para a tela de Insights depois
  Training? _trainingObject;

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
    _blockId = args['blockId'] as String?;

    final rawDate = args['date'];
    _date = (rawDate is DateTime) ? rawDate : DateTime.now();

    // 2. RECUPERA O TREINO E O ID
    if (args['training'] is Training) {
      _trainingObject = args['training'];
    }
    final String? trainingId = _trainingObject?.id;

    // 3. PASSA O trainingId PARA O SERVIÇO (Resolve o Bug do Treino Duplicado)
    _blocksFut = TrainingService.fetchFullTrainingBlocks(
      boxId: _boxId,
      date: _date,
      category: _category,
      trainingId: trainingId, // <--- AQUI ESTÁ A CORREÇÃO
    );

    _bootstrapped = true;
  }

  // ... (Métodos auxiliares mantidos iguais: _chooseTargetBlock, _parseDateLeniente, etc) ...
  TrainingBlock? _chooseTargetBlock(List<TrainingBlock> blocks) {
    if (blocks.isEmpty) return null;
    if (_blockId != null && _blockId!.isNotEmpty) {
      final i = blocks.indexWhere((b) => b.id == _blockId);
      if (i != -1) return blocks[i];
    }
    if (_expectedTitle != null && _expectedTitle!.trim().isNotEmpty) {
      final i = blocks.indexWhere(
        (b) =>
            b.title.trim().toLowerCase() ==
            _expectedTitle!.trim().toLowerCase(),
      );
      if (i != -1) return blocks[i];
    }
    final wodIdx = blocks.indexWhere(
      (b) => b.title.toLowerCase().contains('wod'),
    );
    if (wodIdx != -1) return blocks[wodIdx];
    final mainIdx = blocks.indexWhere((b) {
      final t = '${b.title} ${b.subtitle}'.toLowerCase();
      return t.contains('for time') || t.contains('amrap');
    });
    if (mainIdx != -1) return blocks[mainIdx];
    return blocks.last;
  }

  void _onTapVerResultados() {}
  void _onTapRegistrarResultado() {}

  // 4. Novo método para navegar para os Insights da IA
  void _onTapVerInsightsAI() {
    if (_trainingObject != null) {
      Navigator.pushNamed(
        context,
        '/coach_insights', // Ou CoachInsightsScreen.routeName
        arguments: {'training': _trainingObject},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Dados do treino não disponíveis para análise."),
        ),
      );
    }
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
          // Header com Botão Voltar e Título ou Ações
          Padding(
            padding: EdgeInsets.only(
              top: 8 * scale,
              left: 6 * scale,
              right: 6 * scale,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppBackButton(),
                // Botão de Atalho para Insights (Opcional, mas útil)
                TextButton.icon(
                  onPressed: _onTapVerInsightsAI,
                  icon: Icon(
                    Icons.auto_awesome,
                    size: 16 * scale,
                    color: AppColors.baseBlue,
                  ),
                  label: Text(
                    "Insights IA",
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: AppColors.baseBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
                          // Aqui conectamos o botão do rodapé aos Insights também
                          onTapComentariosDoCriador: _onTapVerInsightsAI,
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
