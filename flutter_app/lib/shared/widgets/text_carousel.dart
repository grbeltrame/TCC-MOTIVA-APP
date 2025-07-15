// lib/shared/widgets/text_carousel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

/// Carrossel de itens de texto simples, com auto-scroll e setas manuais.
/// Adapta sua altura ao conteúdo.
class TextCarousel extends StatefulWidget {
  /// Lista de strings que serão exibidas.
  final List<String> items;

  /// Peso da fonte (e.g. FontWeight.bold). Padrão: normal.
  final FontWeight fontWeight;

  /// Estilo da fonte (e.g. FontStyle.italic). Padrão: normal.
  final FontStyle fontStyle;

  const TextCarousel({
    Key? key,
    required this.items,
    this.fontWeight = FontWeight.normal,
    this.fontStyle = FontStyle.normal,
  }) : super(key: key);

  @override
  _TextCarouselState createState() => _TextCarouselState();
}

class _TextCarouselState extends State<TextCarousel> {
  int _current = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // auto‑scroll a cada 8s
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || widget.items.isEmpty) return;
      setState(() {
        _current = (_current + 1) % widget.items.length;
      });
    });
  }

  void _prev() {
    if (widget.items.isEmpty) return;
    setState(() {
      _current = (_current - 1 + widget.items.length) % widget.items.length;
    });
  }

  void _next() {
    if (widget.items.isEmpty) return;
    setState(() {
      _current = (_current + 1) % widget.items.length;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // o AnimatedSize faz a altura subir/descer de acordo com o texto
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: Text(
              widget.items[_current],
              key: ValueKey<int>(_current),
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: widget.fontWeight,
                fontStyle: widget.fontStyle,
                color: AppColors.darkText,
              ),
            ),
          ),
        ),

        // espaçamento reduzido entre texto e setas
        SizedBox(height: 8 * scale),

        // setas manuais
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _prev,
              child: Icon(
                Icons.arrow_circle_left_outlined,
                size: 24 * scale,
                color: AppColors.lightBlue,
              ),
            ),
            SizedBox(width: 4 * scale),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _next,
              child: Icon(
                Icons.arrow_circle_right_outlined,
                size: 24 * scale,
                color: AppColors.lightBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
