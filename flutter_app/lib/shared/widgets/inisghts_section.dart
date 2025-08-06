// lib/shared/widgets/insights_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/insights_service.dart';
import 'package:flutter_app/shared/models/inisght_model.dart';
import 'package:flutter_app/shared/widgets/inisghts_carousel.dart';

/// Seção de “Insights do Treino do Dia”:
/// – só aparece se houver insights habilitados
/// – título + carrossel + espaçamento
class InsightsSection extends StatelessWidget {
  const InsightsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final today = DateTime.now();

    return FutureBuilder<Set<String>>(
      future: InsightsService().fetchEnabledInsightTypes(),
      builder: (ctx, snapEnabled) {
        if (snapEnabled.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final enabled = snapEnabled.data!;
        if (enabled.isEmpty) return const SizedBox.shrink();

        return FutureBuilder<List<InsightsModel>>(
          future: InsightsService().fetchDailyInsights(today),
          builder: (ctx2, snapList) {
            if (snapList.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final all = snapList.data!;
            final filtered =
                all.where((i) => enabled.contains(i.type)).toList();
            if (filtered.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Text(
                    'Insights do Treino do Dia',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 8 * scale),
                InsightsCarousel(
                  allInsights: filtered,
                  enabledInsightTypes: enabled,
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
