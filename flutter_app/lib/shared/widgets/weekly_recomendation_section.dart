// lib/shared/widgets/weekly_stats_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/highlights_service.dart';
import 'package:flutter_app/shared/widgets/recomendations_carousel.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seção “Destaques da Semana”
/// – busca todos os destaques estatísticos
/// – busca os tipos que o usuário habilitou
/// – só renderiza se, após o filtro, restar ao menos 1 item
class WeeklyRecomendationSection extends StatelessWidget {
  const WeeklyRecomendationSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // 1) Busca todos os destaques estatísticos
    return FutureBuilder<List<RecomendationModel>>(
      future: HighlightsService().fetchWeeklyStatsRecommendations(),
      builder: (ctx, snapStats) {
        if (snapStats.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final stats = snapStats.data ?? [];

        // 2) Busca quais tipos o usuário habilitou
        return FutureBuilder<Set<String>>(
          future: HighlightsService().fetchEnabledWeeklyStatsTypes(),
          builder: (ctx2, snapEnabled) {
            if (snapEnabled.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final enabled = snapEnabled.data!;

            // 3) Filtra só os habilitados
            final filtered =
                stats.where((r) => enabled.contains(r.type)).toList();

            // 4) Se não sobrar nada, some tudo
            if (filtered.isEmpty) return const SizedBox.shrink();

            // 5) Renderiza título + carousel + espaçamento
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Text(
                    'Destaques da Semana',
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
