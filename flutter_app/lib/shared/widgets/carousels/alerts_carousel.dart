// lib/shared/widgets/alerts_carousel.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Modelo simples de alerta — usado para tipagem e lógica dentro do widget.
class AlertModel {
  final String type;
  final String message;
  AlertModel({required this.type, required this.message});
}

/// Um carrossel de cartões de alerta.
/// Exibe apenas os tipos habilitados e percorre automaticamente.
class AlertsCarousel extends StatefulWidget {
  final List<AlertModel> allAlerts;
  final Set<String> enabledTypes;

  const AlertsCarousel({
    Key? key,
    required this.allAlerts,
    required this.enabledTypes,
  }) : super(key: key);

  @override
  _AlertsCarouselState createState() => _AlertsCarouselState();
}

class _AlertsCarouselState extends State<AlertsCarousel> {
  late final PageController _controller;
  late final List<AlertModel> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered =
        widget.allAlerts
            .where((a) => widget.enabledTypes.contains(a.type))
            .toList();
    // agora mostra 1 cartão por página
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
                color: AppColors.lightMagenta.withAlpha(31),
                border: Border.all(color: AppColors.baseMagenta),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 28 * scale,
                    color: AppColors.lightMagenta,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
