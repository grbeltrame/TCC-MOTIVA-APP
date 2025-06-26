// lib/shared/widgets/highlights_carousel.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Modelo simples de destaque — usado para tipagem e lógica dentro do widget.
class HighlightModel {
  final String type;
  final String message;
  HighlightModel({required this.type, required this.message});
}

/// Um carrossel de cartões de destaques.
/// Exibe apenas os tipos habilitados e percorre automaticamente.
class HighlightsCarousel extends StatefulWidget {
  final List<HighlightModel> allHighlights;
  final Set<String> enabledHighlightsTypes;

  const HighlightsCarousel({
    Key? key,
    required this.allHighlights,
    required this.enabledHighlightsTypes,
  }) : super(key: key);

  @override
  _HighlightsCarouselState createState() => _HighlightsCarouselState();
}

class _HighlightsCarouselState extends State<HighlightsCarousel> {
  late final PageController _controller;
  late final List<HighlightModel> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered =
        widget.allHighlights
            .where((a) => widget.enabledHighlightsTypes.contains(a.type))
            .toList();
    // mostra 1 cartão por página
    _controller = PageController(viewportFraction: 1);
    Future.delayed(const Duration(seconds: 5), _nextPage);
  }

  void _nextPage() {
    if (!mounted || _filtered.isEmpty) return;
    final next = (_controller.page!.round() + 1) % _filtered.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 8), _nextPage);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    if (_filtered.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      // altura definida apenas pelo conteúdo + padding
      height:
          (24 + 14 * 3 + 24) *
          scale, // padding 12*2 + até 3 linhas de 14px cada * scale
      child: PageView.builder(
        controller: _controller,
        itemCount: _filtered.length,
        itemBuilder: (ctx, i) {
          final a = _filtered[i];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4 * scale),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: 8 * scale,
                horizontal: 12 * scale,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.mediumGray),
                borderRadius: BorderRadius.circular(8 * scale),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/social_leaderboard.svg',
                    width: 28 * scale,
                    height: 28 * scale,
                    color: AppColors.lightBlue, // se quiser colorir via código
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      a.message,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.medium,
                        fontSize: 14 * scale,
                        color: AppColors.darkText,
                        height: 1.2, // garante espaçamento vertical
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
