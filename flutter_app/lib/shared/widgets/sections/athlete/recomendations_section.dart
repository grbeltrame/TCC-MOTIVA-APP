// lib/shared/widgets/highlights_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/recomendations_service.dart';
import 'package:flutter_app/shared/widgets/carousels/recomendations_carousel.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seção completa de Destaques Inteligentes:
/// – inclui título, carousel e espaçamento final
/// – só aparece se houver highlights habilitados
class RecomendationsSection extends StatelessWidget {
  const RecomendationsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // 1) Busca todos os highlights
    return FutureBuilder<List<RecomendationModel>>(
      future: RecomendationsService().fetchRecomendations(),
      builder: (ctx, snapRecomendations) {
        // enquanto carrega, mostra o loader existente
        if (snapRecomendations.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapRecomendations.data!;

        // 2) Busca o conjunto de tipos habilitados
        return FutureBuilder<Set<String>>(
          future: RecomendationsService().fetchEnabledRecomendationsTypes(),
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
                    'Recomendações Inteligentes',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 8 * scale),
                RecomendationsCarousel(
                  allRecomendations: filtered,
                  enabledRecomendationsTypes: enabled,
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
