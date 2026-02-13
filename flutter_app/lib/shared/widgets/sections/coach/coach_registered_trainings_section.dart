import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import necessário para formatar datas
import 'package:flutter_app/shared/widgets/utils/compact_date_picker.dart';
import 'package:flutter_app/shared/widgets/utils/type_picker.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/dialogs/confirm_delete_training.dart';

/// Section: “Esses são todos os treinos cadastrados do Box”
class CoachRegisteredTrainingsSection extends StatefulWidget {
  // Callback opcional caso a tela pai precise saber quando algo foi clicado
  final void Function({
    required DateTime date,
    required String category,
    String? trainingBlockId,
  })?
  onSelectionChanged;

  const CoachRegisteredTrainingsSection({super.key, this.onSelectionChanged});

  @override
  State<CoachRegisteredTrainingsSection> createState() =>
      _CoachRegisteredTrainingsSectionState();
}

class _CoachRegisteredTrainingsSectionState
    extends State<CoachRegisteredTrainingsSection> {
  static const _categories = ['WOD', 'LPO', 'Ginastica', 'Endurance'];

  DateTime _date = DateTime.now();
  String _category = _categories[0];

  Future<Map<String, TrainingBlock?>>? _fut;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      // Busca TODOS os documentos do dia, independente do ID ou Tipo
      _fut = TrainingService.getAllTrainingBlocksRaw(
        boxId: 'DEFAULT_BOX',
        date: _date,
      );
    });
  }

  /// 🔴 CORREÇÃO AQUI:
  /// Filtra olhando o CONTEÚDO (Subtitle) e não a CHAVE (ID do documento).
  List<TrainingBlock> _getMatchingBlocks(Map<String, TrainingBlock?> map) {
    final target = _category.toUpperCase().trim();
    final List<TrainingBlock> list = [];

    print("--- 🕵️‍♀️ FILTRANDO NA TELA ---");
    print("Alvo: $target");
    print("Total de blocos recebidos do Service: ${map.length}");

    for (var block in map.values) {
      if (block == null) continue;

      final contentToCheck = block.subtitle.toUpperCase();
      print(
        " > Checando bloco '${block.title}' com Subtitulo: '$contentToCheck'",
      );

      // Aumentei a segurança: verifica se contem o alvo
      if (contentToCheck.contains(target)) {
        print("   ✅ MATCH!");
        list.add(block);
      } else {
        print("   ⛔ Ignorado");
      }
    }

    return list;
  }

  void _openCoachTrainingDetail(TrainingBlock block) {
    // Avisa o pai (opcional, para atualizar gráficos/insights)
    widget.onSelectionChanged?.call(
      date: _date,
      category: _category,
      trainingBlockId: block.id,
    );

    Navigator.of(context).pushNamed(
      AppRoutes.coachTrainingDetail,
      arguments: {
        'boxId': '1',
        'date': _date,
        'category': _category,
        'blockId': block.id,
        'expectedTitle': block.title,
      },
    );
  }

  // --- Métodos Auxiliares ---

  Future<void> _openRegisterResult() async {
    // await showRegisterResultBottomSheet(context);
    // Comentado pois não vi o import no seu código original, mas mantenho a estrutura
  }

  void _onTapVerResultadosAlunos() {
    // TODO: implementar
  }

  void _onTapComentariosDoCriador() {
    // TODO: implementar
  }

  String _fmtDate(DateTime d) {
    return DateFormat('dd/MM/yyyy').format(d);
  }

  Future<void> _onTapApagarTreino(TrainingBlock block) async {
    final confirmed = await showConfirmDeleteTrainingDialog(
      context,
      trainingTitle: block.title,
      dateLabel: _fmtDate(_date),
      categoryLabel: _category.toUpperCase(),
    );

    if (confirmed != true) return;

    await TrainingService.deleteTraining(
      boxId: 'DEFAULT_BOX',
      date: _date,
      category: _category,
      blockId: block.id,
    );

    if (!mounted) return;

    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Treino "${block.title}" removido.')),
    );

    _reload();
  }

  void _onTapEditarTreino(TrainingBlock block) {
    Navigator.pushNamed(
      context,
      AppRoutes.coachTrainingEdit,
      arguments: {
        'boxId': '1',
        'date': _date,
        'category': _category,
        'blockId': block.id, // O ID do documento Firestore
      },
    ).then((saved) {
      if (saved == true) {
        _reload();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino atualizado com sucesso.')),
        );
      }
    });
  }

  /// Constrói um CARD individual para cada treino encontrado
  Widget _buildTrainingCard(
    BuildContext context,
    TrainingBlock block,
    double scale,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: AppColors.mediumGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3 * scale,
            offset: Offset(0, 1 * scale),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Conteúdo do Treino
          Padding(
            padding: EdgeInsets.fromLTRB(12 * scale, 12 * scale, 12 * scale, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        block.title, // Ex: Infinity
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 16 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    // Badge opcional para debug (pode remover depois)
                    // Text(block.id.substring(0,4), style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 4 * scale),
                Text(
                  block.subtitle, // Ex: WOD • 20 min
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
                SizedBox(height: 8 * scale),
                // Exibimos apenas as primeiras linhas para não poluir
                ...block.items
                    .take(5)
                    .map(
                      (line) => Padding(
                        padding: EdgeInsets.only(bottom: 4 * scale),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 12 * scale,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ),
                    ),
                if (block.items.length > 5)
                  Text(
                    "...",
                    style: TextStyle(
                      color: AppColors.mediumGray,
                      fontSize: 10 * scale,
                    ),
                  ),
                SizedBox(height: 8 * scale),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.lightGray),

          // Footer Linha 1: Ações sociais
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 2 * scale,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _onTapComentariosDoCriador,
                  icon: Icon(
                    Icons.comment_outlined,
                    size: 14 * scale,
                    color: AppColors.baseBlue,
                  ),
                  label: Text(
                    'Comentários do criador',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 11 * scale,
                      color: AppColors.baseBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: AppColors.lightGray.withOpacity(0.6)),

          // Footer Linha 2: Ver detalhes
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 2 * scale,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _openCoachTrainingDetail(block),
                  icon: Icon(
                    Icons.visibility_outlined,
                    size: 16 * scale,
                    color: AppColors.baseBlue,
                  ),
                  label: Text(
                    'Ver treino completo',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 13 * scale,
                      color: AppColors.baseBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- RODAPÉ: APAGAR E EDITAR ---
          Container(height: 1, color: AppColors.lightGray.withOpacity(0.6)),
          Padding(
            padding: EdgeInsets.all(8.0 * scale),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _onTapApagarTreino(block),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade700, width: 1.2),
                      backgroundColor: Colors.red.withOpacity(0.05),
                      minimumSize: Size(0, 32 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6 * scale),
                      ),
                    ),
                    child: Text(
                      'Apagar',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 12 * scale,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8 * scale),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _onTapEditarTreino(block),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.baseBlue,
                        width: 1.2,
                      ),
                      backgroundColor: AppColors.baseBlue.withAlpha(20),
                      minimumSize: Size(0, 32 * scale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6 * scale),
                      ),
                    ),
                    child: const Text(
                      'Editar',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 12,
                        color: AppColors.baseBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1) Título
        Text(
          'Esses são todos os treinos cadastrados do Box',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        SizedBox(height: 8 * scale),

        // 2) Linha: Date + Ver ciclos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CompactDatePicker(
              initialDate: _date,
              onChanged: (d) {
                _date = d;
                _reload();
              },
            ),
            TextActionButton(
              text: 'Ver todos os ciclos',
              icon: Icons.add,
              onPressed:
                  () => Navigator.pushNamed(context, AppRoutes.coachAllCycles),
            ),
          ],
        ),
        SizedBox(height: 12 * scale),

        // 3) TypePicker
        Align(
          alignment: Alignment.center,
          child: TypePicker(
            types: _categories,
            initialType: _category,
            onChanged: (t) => setState(() => _category = t),
          ),
        ),
        SizedBox(height: 12 * scale),

        // 4) LISTA DE CARDS
        FutureBuilder<Map<String, TrainingBlock?>>(
          future: _fut,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 140 * scale,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final map = snap.data ?? {};
            // Filtra pelo conteúdo (Subtitle contém "WOD"?)
            final blocks = _getMatchingBlocks(map);

            if (blocks.isEmpty) {
              return Container(
                padding: EdgeInsets.all(16 * scale),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      color: AppColors.mediumGray,
                      size: 32 * scale,
                    ),
                    SizedBox(height: 8 * scale),
                    Text(
                      'Nenhum treino de $_category cadastrado.',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 14 * scale,
                        color: AppColors.mediumGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Renderiza um Card para CADA bloco encontrado
            return Column(
              children:
                  blocks
                      .map((block) => _buildTrainingCard(context, block, scale))
                      .toList(),
            );
          },
        ),
      ],
    );
  }
}
