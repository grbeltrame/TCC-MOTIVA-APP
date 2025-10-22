// lib/shared/widgets/recomendations_carousel.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Modelo simples de destaque — usado para tipagem e lógica dentro do widget.
class RecomendationModel {
  final String type;
  final String message;
  RecomendationModel({required this.type, required this.message});
}

/// Um carrossel de cartões de destaques.
/// Exibe apenas os tipos habilitados e percorre automaticamente.
class RecomendationsCarousel extends StatefulWidget {
  final List<RecomendationModel> allRecomendations;
  final Set<String> enabledRecomendationsTypes;

  const RecomendationsCarousel({
    Key? key,
    required this.allRecomendations,
    required this.enabledRecomendationsTypes,
  }) : super(key: key);

  @override
  _RecomendationsCarouselState createState() => _RecomendationsCarouselState();
}

class _RecomendationsCarouselState extends State<RecomendationsCarousel> {
  late final PageController _controller;
  late final List<RecomendationModel> _filtered;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _filtered =
        widget.allRecomendations
            .where((a) => widget.enabledRecomendationsTypes.contains(a.type))
            .toList();

    _controller = PageController(viewportFraction: 1);

    if (_filtered.isNotEmpty) {
      // Garante que o PageView esteja montado antes de agendar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scheduleNext();
      });
    }
  }

  void _scheduleNext() {
    _autoTimer?.cancel();
    _autoTimer = Timer(const Duration(seconds: 5), _nextPage);
  }

  void _nextPage() {
    if (!mounted || _filtered.isEmpty) return;
    if (!_controller.hasClients) {
      // Se ainda não tem cliente, tenta novamente mais tarde
      _scheduleNext();
      return;
    }

    final current = _controller.page?.round() ?? 0;
    final next = (current + 1) % _filtered.length;

    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    // agenda o próximo ciclo
    _autoTimer = Timer(const Duration(seconds: 8), _nextPage);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    if (_filtered.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      // altura definida apenas pelo conteúdo + padding
      height:
          (16 + 14 * 3 + 16) *
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
                color: AppColors.lightBlue.withAlpha(31),
                border: Border.all(color: AppColors.darkBlue),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 28 * scale,
                    color: AppColors.darkText,
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      a.message,
                      textAlign: TextAlign.left,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
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
}
