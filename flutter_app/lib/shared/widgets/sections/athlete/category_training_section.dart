// lib/shared/widgets/category_training_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/adaptations_suggestions_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/icon_text_action_button.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

// Bottom sheet: perfis semelhantes
import 'package:flutter_app/shared/widgets/bottom_sheets/similar_profile_bottom_sheets.dart';

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
      category: category, // "WOD", "LPO", "Ginastica", "Endurance"
      wodName: wodName, // só preenche quando for WOD
      onTapRegister: () async {
        // em treino, registrar RESULTADO (não PR)
        await showRegisterResultBottomSheet(context);
      },
    );
  }

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

  // ===== Helpers para descobrir o alvo do bottom sheet =====

  /// Tenta extrair o nome do WOD a partir do título do bloco.
  /// Exemplos aceitos: 'WOD "Fran"', 'WOD “Fran”', 'WOD Fran'
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

  /// Heurística simples para pegar um “movimento principal” da lista de itens.
  /// Ex.: '5×2 Snatch @ técnica' -> 'Snatch'
  ///      '5×3 Clean & Jerk @ 70%' -> 'Clean & Jerk'
  String? _guessPrimaryMovementFromItems(List<String> items) {
    if (items.isEmpty) return null;
    // pega a primeira linha com alguma letra
    final line = items.firstWhere(
      (l) => RegExp(r'[A-Za-zÀ-ú]').hasMatch(l),
      orElse: () => items.first,
    );
    var s = line;
    // corta tudo após '@'
    final atIdx = s.indexOf('@');
    if (atIdx != -1) s = s.substring(0, atIdx);
    // remove prefixos com números, porcentagens etc.
    // mantém palavras com letras e símbolos & e -
    final tokens =
        s.split(RegExp(r'\s+')).where((t) {
          final hasLetter = RegExp(r'[A-Za-zÀ-ú]').hasMatch(t);
          final looksCount = RegExp(
            r'^\d|%|×|x',
            caseSensitive: false,
          ).hasMatch(t);
          return hasLetter && !looksCount;
        }).toList();

    if (tokens.isEmpty) return null;

    // junta tokens até um limite razoável
    final candidate = tokens.join(' ').trim();
    // pequenos ajustes de pontuação
    return candidate.replaceAll(RegExp(r'[,\.;]+$'), '');
  }

  Future<void> _openSimilarProfilesForCategory(
    String category,
    TrainingBlock? block,
  ) async {
    String? benchmarkName;
    String? movementName;

    if (block != null) {
      if (category.toLowerCase() == 'wod') {
        benchmarkName = _extractWodNameFromTitle(block.title);
      } else {
        movementName = _guessPrimaryMovementFromItems(block.items);
      }
    }

    // Abre o sheet e, no botão "Registrar", chamamos o sheet de RESULTADO
    await showSimilarProfilesBottomSheet(
      context,
      benchmarkName: benchmarkName,
      movementName: movementName,
      onTapRegister: () async {
        await showRegisterResultBottomSheet(context);
      },
    );
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
                            onPressed:
                                () => _openAdaptationsForCategory(cat, block),
                          ),
                          IconTextActionButton(
                            text: 'Ver resultados de perfis semelhantes',
                            iconData: Icons.groups_outlined,
                            fontSize: 9,
                            onPressed:
                                () =>
                                    _openSimilarProfilesForCategory(cat, block),
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
                            onPressed: () {
                              // TODO(back): navegar para treino completo do dia
                            },
                          ),
                          IconTextActionButton(
                            text: 'Registrar Resultado',
                            svgAsset: 'assets/icons/rewards.svg',
                            onPressed: () async {
                              await showRegisterResultBottomSheet(context);
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
