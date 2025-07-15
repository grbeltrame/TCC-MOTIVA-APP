import 'package:flutter/material.dart';

/// Carrossel de itens de texto simples, com auto-scroll.
/// Use sempre que precisar exibir uma sequência de mensagens em texto.
class TextCarousel extends StatefulWidget {
  /// Lista de strings que serão exibidas.
  final List<String> items;

  /// Altura do carrossel; se não fornecida, usa 60*h da escala.
  final double? height;

  const TextCarousel({Key? key, required this.items, this.height})
    : super(key: key);

  @override
  _TextCarouselState createState() => _TextCarouselState();
}

class _TextCarouselState extends State<TextCarousel> {
  late final PageController _controller;
  late final List<String> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
    _controller = PageController(viewportFraction: 1.0);
    Future.delayed(const Duration(seconds: 5), _nextPage);
  }

  void _nextPage() {
    if (!mounted || _items.isEmpty) return;
    final next = (_controller.page!.round() + 1) % _items.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 8), _nextPage);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final scale = MediaQuery.of(context).size.width / 375.0;
    final h = widget.height ?? 40 * scale;
    return SizedBox(
      height: h,
      child: PageView.builder(
        controller: _controller,
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          return Center(
            child: Text(
              _items[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14 * scale,
                fontWeight: FontWeight.normal,
                height: 1.3,
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
