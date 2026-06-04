import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/analysis_service.dart';
import 'package:flutter_app/shared/widgets/cards/simple_analysis_card.dart';
import 'package:flutter_app/shared/models/analysis_summary.dart';

/// Section que exibe o modo **simples** de análise em carousel:
/// – título “Análises”
/// – PageView com viewportFraction=0.9 (um card inteiro + parte do próximo)
/// – auto‑scroll a cada 8s
class SimpleAnalysisSection extends StatefulWidget {
  const SimpleAnalysisSection({Key? key}) : super(key: key);

  @override
  _SimpleAnalysisSectionState createState() => _SimpleAnalysisSectionState();
}

class _SimpleAnalysisSectionState extends State<SimpleAnalysisSection> {
  final _controller = PageController(viewportFraction: 0.9);
  List<AnalysisSummary>? _items;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    AnalysisService.fetchSimpleAnalyses().then((list) {
      if (!mounted) return;
      setState(() => _items = list);
      _timer = Timer.periodic(const Duration(seconds: 8), (_) => _nextPage());
    });
  }

  void _nextPage() {
    if (_items == null || _items!.isEmpty) return;
    final next = (_controller.page!.round() + 1) % _items!.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final scale = screenW / 375.0;
    // altura do card + destaque
    final height = (12 * 2 + 80 + 8 + 120 + 8 + 16) * scale;

    if (_items == null) {
      return SizedBox(
        height: height + 32 * scale,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_items!.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Text(
            'Análises',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: 8 * scale),

        // Carousel
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            padEnds: false, // evita o offset centralizado
            itemCount: _items!.length,
            itemBuilder: (ctx, i) {
              final left = i == 0 ? 6 * scale : 8 * scale;
              return Padding(
                padding: EdgeInsets.only(
                  left: left, // primeiro item “cola” na esquerda
                  right: 8 * scale, // mantém espaçamento à direita
                ),
                child: SimpleAnalysisCard(summary: _items![i]),
              );
            },
          ),
        ),

        SizedBox(height: 32 * scale),
      ],
    );
  }
}
