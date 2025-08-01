// lib/shared/widgets/complex_analyses_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/core/services/analysis_service.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/complex_analysis_card.dart';

/// Section com 3 abas: Movimentos, WODs e Volume,
/// cada uma com seus dropdowns mockados e botões de ação.
class ComplexAnalysisSection extends StatelessWidget {
  const ComplexAnalysisSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widthScale = MediaQuery.of(context).size.width / 375.0;
    final totalHeight = MediaQuery.of(context).size.height;
    // definimos uma altura fixa para o conteúdo das abas: 60% da tela
    final tabsHeight = totalHeight * 0.5;

    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            labelColor: AppColors.baseBlue,
            unselectedLabelColor: AppColors.mediumGray,
            indicatorColor: AppColors.baseBlue,
            tabs: const [
              Tab(text: 'Movimentos'),
              Tab(text: 'WODs'),
              Tab(text: 'Volume'),
            ],
          ),
          SizedBox(height: 12 * widthScale),
          SizedBox(
            height: tabsHeight,
            child: TabBarView(
              children: const [_MovementsTab(), _WodsTab(), _VolumeTab()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Aba “Movimentos”
class _MovementsTab extends StatefulWidget {
  const _MovementsTab();
  @override
  State<_MovementsTab> createState() => _MovementsTabState();
}

class _MovementsTabState extends State<_MovementsTab> {
  List<String> _cats = [];
  List<String> _moves = [];
  String? _selCat;
  String? _selMove;

  @override
  void initState() {
    super.initState();
    // TODO: trazer categorias reais do backend
    AnalysisService.fetchMovementCategories().then(
      (l) => setState(() => _cats = l),
    );
  }

  void _onCatChanged(String? cat) {
    if (cat == null) return;
    setState(() {
      _selCat = cat;
      _selMove = null;
      _moves = [];
    });
    // TODO: trazer movimentos reais do backend
    AnalysisService.fetchMovementsForCategory(
      cat,
    ).then((l) => setState(() => _moves = l));
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Frase fixa
          Text(
            '🏋️ Como estou evoluindo nos principais levantamentos e movimentos ginásticos?',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 10 * scale,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 8 * scale),
          // Dropdowns: categoria e movimento
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.arrow_drop_down, color: AppColors.darkText),
                    SizedBox(width: 4 * scale),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        icon: const SizedBox.shrink(),
                        underline: const SizedBox.shrink(),
                        hint: Text(
                          'Selecione categoria',
                          style: TextStyle(color: AppColors.darkText),
                        ),
                        value: _selCat,
                        items:
                            _cats
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: _onCatChanged,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.arrow_drop_down, color: AppColors.darkText),
                    SizedBox(width: 4 * scale),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        icon: const SizedBox.shrink(),
                        underline: const SizedBox.shrink(),
                        hint: Text(
                          'Selecione movimento',
                          style: TextStyle(color: AppColors.darkText),
                        ),
                        value: _selMove,
                        items:
                            _moves
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _selMove = v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          // Card e Destaque
          if (_selCat != null && _selMove != null) ...[
            ComplexAnalysisCard(type: AnalysisType.effort),
            SizedBox(height: 12 * scale),
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    /* TODO: Ação Todos os PRs */
                  },
                  icon: Icon(Icons.bar_chart, size: 16 * scale),
                  label: Text(
                    'Todos os PRs',
                    style: TextStyle(fontSize: 10 * scale),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.baseBlue,
                    side: BorderSide(color: AppColors.baseBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * scale,
                      vertical: 4 * scale,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(width: 16 * scale),
                OutlinedButton.icon(
                  onPressed: () {
                    /* TODO: Ação Ver média */
                  },
                  icon: Icon(Icons.groups_outlined, size: 16 * scale),
                  label: Text(
                    'Ver média de perfis semelhantes',
                    style: TextStyle(fontSize: 10 * scale),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.baseBlue,
                    side: BorderSide(color: AppColors.baseBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * scale,
                      vertical: 4 * scale,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Aba “WODs”
class _WodsTab extends StatefulWidget {
  const _WodsTab();
  @override
  State<_WodsTab> createState() => _WodsTabState();
}

class _WodsTabState extends State<_WodsTab> {
  List<String> _bench = [];
  String? _selBench;

  @override
  void initState() {
    super.initState();
    // TODO: trazer benchmarks reais do backend
    AnalysisService.fetchCrossfitBenchmarks().then(
      (l) => setState(() => _bench = l),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🏋️ Como estou evoluindo nos Benchmarks do esporte?',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 10 * scale,
              fontWeight: AppFontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              Icon(Icons.arrow_drop_down, color: AppColors.darkText),
              SizedBox(width: 4 * scale),
              Expanded(
                child: DropdownButton<String>(
                  isExpanded: true,
                  icon: const SizedBox.shrink(),
                  underline: const SizedBox.shrink(),
                  hint: Text(
                    'Selecione benchmark',
                    style: TextStyle(color: AppColors.darkText),
                  ),
                  value: _selBench,
                  items:
                      _bench
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selBench = v),
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          if (_selBench != null) ...[
            ComplexAnalysisCard(type: AnalysisType.frequency),
            SizedBox(height: 12 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    /* TODO: Ação Ver WOD */
                  },
                  icon: SvgPicture.asset(
                    'assets/icons/exercise.svg',
                    width: 16 * scale,
                    height: 16 * scale,
                    color: AppColors.baseBlue,
                  ),
                  label: Text(
                    'Ver WOD',
                    style: TextStyle(fontSize: 10 * scale),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.baseBlue,
                    side: BorderSide(color: AppColors.baseBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * scale,
                      vertical: 4 * scale,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(width: 16 * scale),
                OutlinedButton.icon(
                  onPressed: () {
                    /* TODO: Ação Ver média */
                  },
                  icon: Icon(Icons.groups_outlined, size: 16 * scale),
                  label: Text(
                    'Ver média de perfis semelhantes',
                    style: TextStyle(fontSize: 10 * scale),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.baseBlue,
                    side: BorderSide(color: AppColors.baseBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * scale,
                      vertical: 4 * scale,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Aba “Volume”
class _VolumeTab extends StatefulWidget {
  const _VolumeTab();
  @override
  State<_VolumeTab> createState() => _VolumeTabState();
}

class _VolumeTabState extends State<_VolumeTab> {
  List<String> _cats = [];
  List<String> _moves = [];
  String? _selCat;
  String? _selMove;

  @override
  void initState() {
    super.initState();
    // TODO: trazer categorias reais do backend
    AnalysisService.fetchMovementCategories().then(
      (l) => setState(() => _cats = l),
    );
  }

  void _onCatChanged(String? cat) {
    if (cat == null) return;
    setState(() {
      _selCat = cat;
      _selMove = null;
      _moves = [];
    });
    // TODO: trazer movimentos puros do backend
    AnalysisService.fetchMovementsForCategory(
      cat,
    ).then((l) => setState(() => _moves = l));
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '🏋️ Como está minha evolução em volume de movimentos?',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 10 * scale,
              fontWeight: AppFontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 8 * scale),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.arrow_drop_down, color: AppColors.darkText),
                    SizedBox(width: 4 * scale),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        icon: const SizedBox.shrink(),
                        underline: const SizedBox.shrink(),
                        hint: Text(
                          'Selecione categoria',
                          style: TextStyle(color: AppColors.darkText),
                        ),
                        value: _selCat,
                        items:
                            _cats
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                )
                                .toList(),
                        onChanged: _onCatChanged,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.arrow_drop_down, color: AppColors.darkText),
                    SizedBox(width: 4 * scale),
                    Expanded(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        icon: const SizedBox.shrink(),
                        underline: const SizedBox.shrink(),
                        hint: Text(
                          'Selecione movimento',
                          style: TextStyle(color: AppColors.darkText),
                        ),
                        value: _selMove,
                        items:
                            _moves
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _selMove = v),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12 * scale),
          if (_selCat != null && _selMove != null) ...[
            ComplexAnalysisCard(type: AnalysisType.volume),
            SizedBox(height: 12 * scale),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    /* TODO: Ação Registrar */
                  },
                  icon: Icon(Icons.edit_outlined, size: 16 * scale),
                  label: Text(
                    'Registrar',
                    style: TextStyle(fontSize: 10 * scale),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.baseBlue,
                    side: BorderSide(color: AppColors.baseBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * scale,
                      vertical: 4 * scale,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                SizedBox(width: 16 * scale),
                OutlinedButton.icon(
                  onPressed: () {
                    /* TODO: Ação Ver média */
                  },
                  icon: Icon(Icons.groups_outlined, size: 16 * scale),
                  label: Text(
                    'Ver média de perfis semelhantes',
                    style: TextStyle(fontSize: 10 * scale),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.baseBlue,
                    side: BorderSide(color: AppColors.baseBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * scale,
                      vertical: 4 * scale,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
