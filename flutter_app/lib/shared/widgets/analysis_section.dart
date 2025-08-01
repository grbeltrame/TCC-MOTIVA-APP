import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/analysis_service.dart';
import 'package:flutter_app/shared/widgets/complex_analysis_section.dart';
import 'package:flutter_app/shared/widgets/simple_analysis_section.dart';
// import 'complex_analyses_section.dart'; // TODO quando for criar o modo complexo

/// Section única que escolhe modo simples ou complexo
/// de acordo com a preferência do usuário.
class AnalysisSection extends StatelessWidget {
  const AnalysisSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnalysisDisplayMode>(
      future: AnalysisService.fetchDisplayMode(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final mode = snap.data!;
        if (mode == AnalysisDisplayMode.simple) {
          return const SimpleAnalysisSection();
        } else {
          return const ComplexAnalysisSection();
        }
      },
    );
  }
}
