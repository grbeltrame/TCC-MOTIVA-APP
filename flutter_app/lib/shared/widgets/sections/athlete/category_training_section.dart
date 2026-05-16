// lib/shared/widgets/category_training_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/adaptations_suggestions_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/icon_text_action_button.dart';

import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/core/constants/app_box.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

import 'package:flutter_app/core/services/effort_service.dart';

class CategoryTrainingSection extends StatefulWidget {
  final String boxId;
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
  static const List<String> _preferredOrder = [
    'WOD',
    'LPO',
    'FitnessRun',
    'Endurance',
  ];

  Future<_CategoryData>? _futData;
  bool _tabListenerAttached = false;

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  @override
  void didUpdateWidget(covariant CategoryTrainingSection old) {
    super.didUpdateWidget(old);
    if (old.boxId != widget.boxId || old.date != widget.date) {
      _reloadData();
    }
  }

  void _reloadData() {
    _futData = _loadAll();
    if (mounted) setState(() {});
  }

  // Partes internas que não são tipos de treino — ignoradas nas tabs
  static const _kSupportParts = {
    'WARM UP',
    'WARMUP',
    'EXTRA TRAINING',
    'EXTRA',
    'MOBILIDADE',
    'MOBILITY',
    'SKILL',
  };

  Future<_CategoryData> _loadAll() async {
    // Busca os treinos reais do Firestore — mesma fonte que o coach usa
    final trainings = await TrainingService.fetchTrainingsListForDate(
      boxId: widget.boxId.isNotEmpty ? widget.boxId : AppBox.id,
      date: widget.date,
    );

    if (trainings.isEmpty) {
      return _CategoryData(categories: [], blocksByCategory: {});
    }

    // Deriva categorias das chaves de partes, ignorando partes de suporte
    final rawCats = <String>[];
    for (final t in trainings) {
      for (final key in t.partes.keys) {
        if (!_kSupportParts.contains(key.toUpperCase())) {
          rawCats.add(key);
        }
      }
    }

    final orderedCats = _orderCategories(rawCats.toSet().toList());

    // Busca os blocos para exibição (título, itens, etc.)
    final blocksMap =
        await TrainingService.fetchTrainingBlocksByCategoryForDate(
          boxId: widget.boxId.isNotEmpty ? widget.boxId : AppBox.id,
          date: widget.date,
        );

    final byCategory = _mapBlocksToCategories(
      categories: orderedCats,
      rawBlocksMap: blocksMap,
    );

    return _CategoryData(categories: orderedCats, blocksByCategory: byCategory);
  }

  List<String> _orderCategories(List<String> categories) {
    final set = categories.toSet();

    final preferred = <String>[];
    for (final p in _preferredOrder) {
      if (set.contains(p)) preferred.add(p);
    }

    final others =
        categories.where((c) => !preferred.contains(c)).toList()
          ..sort((a, b) => a.compareTo(b));

    return [...preferred, ...others];
  }

  Map<String, TrainingBlock?> _mapBlocksToCategories({
    required List<String> categories,
    required Map<String, TrainingBlock?> rawBlocksMap,
  }) {
    final result = <String, TrainingBlock?>{};

    // 1) Se o map já vier com chave = categoria, pega direto
    for (final cat in categories) {
      if (rawBlocksMap.containsKey(cat)) {
        result[cat] = rawBlocksMap[cat];
      }
    }

    // 2) Caso contrário, tenta inferir pelo conteúdo (title/subtitle/items)
    for (final cat in categories) {
      if (result[cat] != null) continue;

      TrainingBlock? found;
      for (final b in rawBlocksMap.values) {
        if (b == null) continue;
        if (_blockLooksLikeCategory(b, cat)) {
          found = b;
          break;
        }
      }

      result[cat] = found;
    }

    return result;
  }

  bool _blockLooksLikeCategory(TrainingBlock block, String category) {
    final cat = category.toLowerCase();

    final title = block.title.toLowerCase();
    final subtitle = block.subtitle.toLowerCase();
    final itemsText = block.items.join(' ').toLowerCase();

    bool contains(String needle) =>
        title.contains(needle) ||
        subtitle.contains(needle) ||
        itemsText.contains(needle);

    if (contains(cat)) return true;

    // Normalizações extras
    if (cat == 'fitnessrun') {
      if (contains('fitness run')) return true;
      if (contains('run')) return true;
      if (contains('corrida')) return true;
    }

    return false;
  }

  Future<void> _openAdaptationsForCategory(
    String category,
    TrainingBlock? block,
  ) async {
    String? wodName;
    if (block != null && category.toLowerCase() == 'wod') {
      wodName = _extractWodNameFromTitle(block.title);
    }

    await showAdaptationSuggestionsBottomSheet(
      context,
      category: category,
      wodName: wodName,
      onTapRegister: () async {
        final existing = await EffortService.fetchTodayResult(
          date: widget.date,
          wodType: category,
        );
        if (!mounted) return;
        await showRegisterResultBottomSheet(
          context,
          existingRecord: existing,
          initialDate: widget.date,
        );
      },
    );
  }

  String? _extractWodNameFromTitle(String title) {
    final withQuotes = RegExp(
      r'WOD\s*[\"“](.+?)[\"”]',
      caseSensitive: false,
    ).firstMatch(title);
    if (withQuotes != null) return withQuotes.group(1)?.trim();

    final noQuotes = RegExp(
      r'WOD\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(title);
    if (noQuotes != null) return noQuotes.group(1)?.trim();

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final future = _futData;
    if (future == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<_CategoryData>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snap.hasData) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * scale),
            child: Text(
              'Não foi possível carregar os treinos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          );
        }

        final data = snap.data!;
        final categories = data.categories;
        final byCat = data.blocksByCategory;

        if (categories.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * scale),
            child: Text(
              'Não há treinos cadastrados para hoje.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          );
        }

        final tabs = categories.map((c) => Tab(text: c)).toList();

        final pages = categories
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconTextActionButton(
                            text: 'Adaptações',
                            iconData: Icons.edit_outlined,
                            fontSize: 9,
                            onPressed:
                                () => _openAdaptationsForCategory(cat, block),
                          ),
                          // IconTextActionButton(
                          //   text: 'Ver resultados de perfis semelhantes',
                          //   iconData: Icons.groups_outlined,
                          //   fontSize: 9,
                          //   onPressed:
                          //       () =>
                          //           _openSimilarProfilesForCategory(cat, block),
                          // ),
                        ],
                      ),
                      Divider(color: AppColors.lightGray),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconTextActionButton(
                            text: 'Ver treino completo',
                            iconData: Icons.add,
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.athleteFullTraining,
                                arguments: {
                                  'boxId': widget.boxId,
                                  'date': widget.date,
                                  'category': cat,
                                },
                              );
                            },
                          ),
                          IconTextActionButton(
                            text: 'Registrar Resultado',
                            svgAsset: 'assets/icons/rewards.svg',
                            onPressed: () async {
                              final existing =
                                  await EffortService.fetchTodayResult(
                                    date: widget.date,
                                    wodType: cat,
                                  );
                              if (!mounted) return;
                              await showRegisterResultBottomSheet(
                                context,
                                existingRecord: existing,
                                initialDate: widget.date,
                              );
                            },
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
          key: ValueKey('cats_${categories.join("|")}'),
          length: categories.length,
          child: Builder(
            builder: (innerCtx) {
              final tabController = DefaultTabController.of(innerCtx);
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

class _CategoryData {
  final List<String> categories;
  final Map<String, TrainingBlock?> blocksByCategory;

  _CategoryData({required this.categories, required this.blocksByCategory});
}
