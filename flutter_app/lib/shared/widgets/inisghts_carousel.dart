// lib/shared/widgets/insights_carousel.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/inisght_model.dart';
import 'package:flutter_app/shared/widgets/icon_text_action_button.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Um carrossel de cards de Insight, igual ao HighlightsCarousel,
/// porém com altura que se ajusta ao conteúdo automaticamente.
class InsightsCarousel extends StatefulWidget {
  final List<InsightsModel> allInsights;
  final Set<String> enabledInsightTypes;

  const InsightsCarousel({
    Key? key,
    required this.allInsights,
    required this.enabledInsightTypes,
  }) : super(key: key);

  @override
  _InsightsCarouselState createState() => _InsightsCarouselState();
}

class _InsightsCarouselState extends State<InsightsCarousel> {
  late final List<InsightsModel> _filtered;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _filtered =
        widget.allInsights
            .where((i) => widget.enabledInsightTypes.contains(i.type))
            .toList();
    // avança a página a cada 8s
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_filtered.isEmpty) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _filtered.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    if (_filtered.isEmpty) return const SizedBox.shrink();

    final insight = _filtered[_currentIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      child: Padding(
        // chave única para cada insight forçar troca
        key: ValueKey<int>(_currentIndex),
        padding: EdgeInsets.symmetric(horizontal: 4 * scale),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: 12 * scale,
            horizontal: 16 * scale,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.mediumGray),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ícone de medalha
              SvgPicture.asset(
                'assets/icons/social_leaderboard.svg', // TODO: SVG real
                width: 28 * scale,
                height: 28 * scale,
                color: AppColors.lightBlue,
              ),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mensagem
                    Text(
                      insight.message,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 14 * scale,
                        color: AppColors.darkText,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    // Botão
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconTextActionButton(
                        text: 'Registrar agora',
                        iconData: Icons.edit,
                        svgAsset: null,
                        fontSize: 12 * scale,
                        onPressed: () {
                          // TODO: ação específica do insight
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
