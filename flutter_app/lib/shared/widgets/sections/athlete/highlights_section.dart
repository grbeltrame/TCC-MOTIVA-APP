// lib/shared/widgets/highlights_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/highlights_service.dart';
import 'package:flutter_app/shared/widgets/carousels/highlights_carousel.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seção completa de Destaques Inteligentes:
/// – inclui título, carousel e espaçamento final
/// – só aparece se houver highlights habilitados
class HighlightsSection extends StatelessWidget {
  const HighlightsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // 1) Busca todos os highlights
    return FutureBuilder<List<HighlightModel>>(
      future: HighlightsService().fetchHighlights(),
      builder: (ctx, snapHighlights) {
        // enquanto carrega, mostra o loader existente
        if (snapHighlights.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapHighlights.data!;

        // 2) Busca o conjunto de tipos habilitados
        return FutureBuilder<Set<String>>(
          future: HighlightsService().fetchEnabledHighlightsTypes(),
          builder: (ctx2, snapEnabled) {
            if (snapEnabled.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final enabled = snapEnabled.data!;

            // 3) Filtra apenas o que o usuário habilitou
            final filtered =
                all.where((h) => enabled.contains(h.type)).toList();

            // se não houver nenhum, não renderiza título, carousel nem espaçamento
            if (filtered.isEmpty) {
              return const SizedBox.shrink();
            }

            // 4) Renderiza título, carousel e espaçamento de 32*scale
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Text(
                    'Destaques Inteligentes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 8 * scale),
                HighlightsCarousel(
                  allHighlights: filtered,
                  enabledHighlightsTypes: enabled,
                ),
                SizedBox(height: 32 * scale),
              ],
            );
          },
        );
      },
    );
  }
}
