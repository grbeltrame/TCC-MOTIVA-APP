// lib/shared/widgets/category_training_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/utils/icon_text_action_button.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Section que exibe, em abas, o último bloco de treino de cada categoria
/// para um dado box e data. Usa TabBar + IndexedStack para shrink-wrap automático.
class CategoryTrainingSection extends StatefulWidget {
  /// ID do box selecionado.
  final String boxId;

  /// Data selecionada.
  final DateTime date;

  const CategoryTrainingSection({
    Key? key,
    required this.boxId,
    required this.date,
  }) : super(key: key);

  @override
  State<CategoryTrainingSection> createState() =>
      _CategoryTrainingSectionState();
}

class _CategoryTrainingSectionState extends State<CategoryTrainingSection> {
  static const List<String> _categories = [
    'WOD',
    'LPO',
    'Ginastica',
    'Endurance',
  ];

  late Future<Map<String, TrainingBlock?>> _futBlocks;
  bool _tabListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _reloadBlocks();
  }

  @override
  void didUpdateWidget(covariant CategoryTrainingSection old) {
    super.didUpdateWidget(old);
    // Se mudou box OU data, recarrega
    if (old.boxId != widget.boxId || old.date != widget.date) {
      _reloadBlocks();
    }
  }

  void _reloadBlocks() {
    _futBlocks = TrainingService.fetchTrainingBlocksByCategoryForDate(
      boxId: widget.boxId,
      date: widget.date,
    );
    setState(() {}); // força o FutureBuilder a rebuildar
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<Map<String, TrainingBlock?>>(
      future: _futBlocks,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final byCat = snap.data!;

        // preparamos abas e páginas
        final tabs = _categories.map((c) => Tab(text: c)).toList();
        final pages = _categories
            .map((cat) {
              final block = byCat[cat];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                child: Container(
                  padding: EdgeInsets.all(12 * scale),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: AppColors.mediumGray),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (block != null) ...[
                        Text(
                          block.title,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.bold,
                            fontSize: 14 * scale,
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
                      ] else ...[
                        Text(
                          'Não há treino de $cat cadastrado para hoje',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 12 * scale,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                      SizedBox(height: 24 * scale),
                      // primeira fileira de botões
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconTextActionButton(
                            text: 'Adaptações',
                            iconData: Icons.edit_outlined,
                            fontSize: 9,
                            onPressed: () {
                              /* … */
                            },
                          ),
                          IconTextActionButton(
                            text: 'Ver resultados de perfis semelhantes',
                            iconData: Icons.groups_outlined,
                            fontSize: 9,
                            onPressed: () {
                              /* … */
                            },
                          ),
                        ],
                      ),
                      Divider(color: AppColors.lightGray),
                      // segunda fileira de botões
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconTextActionButton(
                            text: 'Ver treino completo',
                            iconData: Icons.add,
                            onPressed: () {},
                          ),
                          IconTextActionButton(
                            text: 'Registrar Resultado',
                            svgAsset: 'assets/icons/rewards.svg',
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false);

        return DefaultTabController(
          length: _categories.length,
          child: Builder(
            builder: (innerCtx) {
              final tabController = DefaultTabController.of(innerCtx)!;
              if (!_tabListenerAttached) {
                tabController.addListener(() => setState(() {}));
                _tabListenerAttached = true;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TabBar(
                    labelColor: AppColors.baseBlue,
                    unselectedLabelColor: AppColors.mediumGray,
                    indicatorColor: AppColors.baseBlue,
                    tabs: tabs,
                  ),
                  SizedBox(height: 12 * scale),
                  IndexedStack(index: tabController.index, children: pages),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
