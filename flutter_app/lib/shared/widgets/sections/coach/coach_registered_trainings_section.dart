import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/utils/compact_date_picker.dart';
import 'package:flutter_app/shared/widgets/utils/type_picker.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
// ⤵️ ADIÇÃO: import dos diálogos
import 'package:flutter_app/shared/widgets/dialogs/confirm_delete_training.dart';

/// Section: “Esses são todos os treinos cadastrados do Box”
class CoachRegisteredTrainingsSection extends StatefulWidget {
  const CoachRegisteredTrainingsSection({super.key});

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

  // ⤵️ ADIÇÃO: manter referência ao bloco atual para o diálogo de exclusão
  TrainingBlock? _currentBlock;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _fut = TrainingService.fetchTrainingBlocksByCategoryForDate(
      boxId: 'DEFAULT_BOX', // compat
      date: _date,
    );
    setState(() {});
  }

  void _openCoachTrainingDetail(TrainingBlock block) {
    Navigator.of(context).pushNamed(
      AppRoutes.coachTrainingDetail,
      arguments: {
        'boxId': '1',
        'date': _date,
        'category': _category,
        'blockId': block.id,
        'expectedTitle': block.title, // << envia o título mostrado no card
      },
    );
  }

  Future<void> _openRegisterResult() async {
    await showRegisterResultBottomSheet(context);
  }

  // TODOs vazios (ficam prontos pra integrar):
  void _onTapVerResultadosAlunos() {
    /* TODO: implementar */
  }
  void _onTapComentariosDoCriador() {
    /* TODO: implementar */
  }

  // ⤵️ ADIÇÃO: helper para exibir data no diálogo
  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yy';
  }

  // ⤵️ ADIÇÃO: fluxo dos diálogos de exclusão
  Future<void> _onTapApagarTreino() async {
    final block = _currentBlock;
    if (block == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não há treino para apagar nesta data/categoria.'),
        ),
      );
      return;
    }

    final confirmed = await showConfirmDeleteTrainingDialog(
      context,
      trainingTitle: block.title,
      dateLabel: _fmtDate(_date),
      categoryLabel: _category.toUpperCase(),
    );

    if (confirmed != true) return;

    // Chama o service (implemente no backend depois)
    await TrainingService.deleteTraining(
      boxId: 'DEFAULT_BOX',
      date: _date,
      category: _category,
      blockId: block.id,
    );

    if (!mounted) return;

    await showTrainingDeletedDialog(
      context,
      trainingTitle: block.title,
      dateLabel: _fmtDate(_date),
      categoryLabel: _category.toUpperCase(),
    );

    _reload();
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

        // 2) Linha: Date + "+ Ver todos os ciclos"
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

        // 3) TypePicker (estética igual ao DateSelector compacto)
        Align(
          alignment: Alignment.center,
          child: TypePicker(
            types: _categories,
            initialType: _category,
            onChanged: (t) => setState(() => _category = t),
          ),
        ),
        SizedBox(height: 12 * scale),

        // 4) Card com o último bloco do tipo selecionado + FOOTER interno
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
            final block = map[_category];

            // ⤵️ ADIÇÃO: manter o bloco atual para o botão externo "Apagar Treino"
            _currentBlock = block;

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4 * scale),
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
              child:
                  block == null
                      ? Padding(
                        padding: EdgeInsets.all(12 * scale),
                        child: Text(
                          'Não há treino de $_category para a data selecionada.',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 12 * scale,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      )
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Conteúdo
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              12 * scale,
                              12 * scale,
                              12 * scale,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  block.title,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: 16 * scale,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  block.subtitle,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontSize: 12 * scale,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                ...block.items.map(
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
                                SizedBox(height: 8 * scale),
                              ],
                            ),
                          ),

                          // Divider do footer
                          Container(height: 1, color: AppColors.lightGray),

                          // Footer interno (linha 1)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 6 * scale,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // TextButton.icon(
                                //   onPressed: _onTapVerResultadosAlunos,
                                //   icon: Icon(
                                //     Icons.group_outlined,
                                //     size: 14 * scale,
                                //     color: AppColors.baseBlue,
                                //   ),
                                //   label: Text(
                                //     'Ver resultados dos alunos',
                                //     style: TextStyle(
                                //       fontFamily: AppFonts.roboto,
                                //       fontWeight: AppFontWeight.bold,
                                //       fontSize: 11 * scale,
                                //       color: AppColors.baseBlue,
                                //     ),
                                //   ),
                                //   style: TextButton.styleFrom(
                                //     padding: EdgeInsets.symmetric(
                                //       horizontal: 8 * scale,
                                //       vertical: 4 * scale,
                                //     ),
                                //     minimumSize: const Size(0, 0),
                                //     tapTargetSize:
                                //         MaterialTapTargetSize.shrinkWrap,
                                //   ),
                                // ),
                                SizedBox(width: 2 * scale),
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
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * scale,
                                      vertical: 4 * scale,
                                    ),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // divisor entre as duas linhas do footer
                          Container(
                            height: 1,
                            color: AppColors.lightGray.withOpacity(0.6),
                          ),

                          // Footer interno (linha 2)
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 6 * scale,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed:
                                      () => _openCoachTrainingDetail(block),
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
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * scale,
                                      vertical: 4 * scale,
                                    ),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                SizedBox(width: 6 * scale),
                                // TextButton.icon(
                                //   onPressed: _openRegisterResult,
                                //   icon: Icon(
                                //     Icons.emoji_events_outlined,
                                //     size: 16 * scale,
                                //     color: AppColors.baseBlue,
                                //   ),
                                //   label: Text(
                                //     'Registrar resultado',
                                //     style: TextStyle(
                                //       fontFamily: AppFonts.roboto,
                                //       fontWeight: AppFontWeight.bold,
                                //       fontSize: 13 * scale,
                                //       color: AppColors.baseBlue,
                                //     ),
                                //   ),
                                //   style: TextButton.styleFrom(
                                //     padding: EdgeInsets.symmetric(
                                //       horizontal: 8 * scale,
                                //       vertical: 4 * scale,
                                //     ),
                                //     minimumSize: const Size(0, 0),
                                //     tapTargetSize:
                                //         MaterialTapTargetSize.shrinkWrap,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                        ],
                      ),
            );
          },
        ),

        SizedBox(height: 12 * scale),

        // 5) Linha com 2 botões (Outlined translúcidos) — fora do card
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed:
                    _onTapApagarTreino, // ⤵️ ADIÇÃO: chama o fluxo dos diálogos
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade700, width: 1.2),
                  backgroundColor: Colors.red.withOpacity(0.1),
                  minimumSize: Size(0, 36 * scale),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                ),
                child: Text(
                  'Apagar Treino',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  final block = _currentBlock;
                  if (block == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Não há treino para editar.'),
                      ),
                    );
                    return;
                  }
                  Navigator.pushNamed(
                    context,
                    AppRoutes.coachTrainingEdit, // <- nova rota
                    arguments: {
                      'boxId': '1', // troque pelo seu box real
                      'date': _date,
                      'category': _category,
                      'blockId':
                          block.id, // ajuda a pré-destacar o bloco principal
                    },
                  ).then((saved) {
                    if (saved == true) {
                      _reload();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Treino atualizado com sucesso.'),
                        ),
                      );
                    }
                  });
                },

                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.baseBlue, width: 1.2),
                  backgroundColor: AppColors.baseBlue.withAlpha(32),
                  minimumSize: Size(0, 36 * scale),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                ),
                child: const Text(
                  'Editar Treino',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    color: AppColors.baseBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
