import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/utils/compact_date_picker.dart';
import 'package:flutter_app/shared/widgets/utils/type_picker.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';

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

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _fut = TrainingService.fetchTrainingBlocksByCategoryForDate(
      boxId: 'DEFAULT_BOX', // ignorado na sua infra atual; mantido por compat.
      date: _date,
    );
    setState(() {});
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
              onPressed: () {
                /* TODO: navegação futura */
              },
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

        // 4) Card com o último bloco do tipo selecionado
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

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4 * scale),
              padding: EdgeInsets.all(12 * scale),
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
              child:
                  block == null
                      ? Text(
                        'Não há treino de $_category para esta data.',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 12 * scale,
                          color: AppColors.mediumGray,
                        ),
                      )
                      : Column(
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
                        ],
                      ),
            );
          },
        ),

        SizedBox(height: 12 * scale),

        // 5) Linha com 2 botões (Outlined translúcidos)
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  /* TODO: apagar */
                },
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
                  /* TODO: editar */
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.baseBlue, width: 1.2),
                  backgroundColor: AppColors.baseBlue.withAlpha(32),
                  minimumSize: Size(0, 36 * scale),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                ),
                child: Text(
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
