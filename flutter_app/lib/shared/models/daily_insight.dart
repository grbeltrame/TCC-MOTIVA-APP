import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/users/coach/daily_insights_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/carousels/recomendations_carousel.dart';

/// Section que exibe um carrossel de insights do COACH para o dia,
/// reusando o RecomendationsCarousel (type/message).
class CoachDailyInsightsSection extends StatelessWidget {
  final DateTime date;
  final String boxId;

  const CoachDailyInsightsSection({
    super.key,
    required this.date,
    required this.boxId,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final service = CoachDailyInsightsService();

    // 1) Busca categorias habilitadas pelo coach
    return FutureBuilder<Set<String>>(
      future: service.fetchEnabledCoachInsightTypes(boxId),
      builder: (ctx, snapEnabled) {
        if (snapEnabled.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final enabled = snapEnabled.data ?? {};
        if (enabled.isEmpty) return const SizedBox.shrink();

        // 2) Busca quais categorias realmente existem no dia
        return FutureBuilder<Set<String>>(
          future: service.fetchExistingCategoriesForDay(
            boxId: boxId,
            date: date,
          ),
          builder: (ctx2, snapExisting) {
            if (snapExisting.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final existing = snapExisting.data ?? {};
            if (existing.isEmpty) return const SizedBox.shrink();

            // 3) Busca insights do coach do dia
            return FutureBuilder<List<CoachInsightModel>>(
              future: service.fetchCoachInsightsForDay(
                boxId: boxId,
                date: date,
              ),
              builder: (ctx3, snapInsights) {
                if (snapInsights.connectionState != ConnectionState.done) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final allCoachInsights = snapInsights.data ?? [];

                // 4) Filtra: apenas os tipos habilitados E que existem no dia
                final filtered =
                    allCoachInsights
                        .where((i) => enabled.contains(i.type))
                        .where((i) => existing.contains(i.type))
                        .toList();

                if (filtered.isEmpty) return const SizedBox.shrink();

                // 5) Adapta para o formato esperado pelo RecomendationsCarousel
                final recos =
                    filtered
                        .map(
                          (i) => RecomendationModel(
                            type: i.type,
                            message: i.message,
                          ),
                        )
                        .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                      child: Text(
                        'Insights do dia',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    SizedBox(height: 8 * scale),

                    //  Reuso do carrossel existente
                    RecomendationsCarousel(
                      allRecomendations: recos,
                      enabledRecomendationsTypes: enabled.intersection(
                        existing,
                      ),
                    ),

                    SizedBox(height: 16 * scale),

                    // ─────────── Botões de ação ───────────
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                      child: _CoachInsightsActions(scale: scale),
                    ),

                    SizedBox(height: 8 * scale),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _CoachInsightsActions extends StatelessWidget {
  final double scale;
  const _CoachInsightsActions({required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Botão preenchido
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.coachEvolutions);
            },
            icon: Icon(Icons.lightbulb_outline_rounded, size: 18 * scale),
            label: Text(
              'Análise semanal',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: 10 * scale,
                horizontal: 12 * scale,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * scale),
                side: BorderSide(color: AppColors.darkBlue, width: 1),
              ),
              textStyle: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 8 * scale),

        // Botão vazado (outlined)
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.coachTrainingInsights);
            },
            icon: Icon(
              Icons.show_chart_rounded,
              size: 18 * scale,
              color: AppColors.darkBlue,
            ),
            label: Text(
              'Projeção do ciclo',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.darkBlue),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.darkBlue, width: 1),
              padding: EdgeInsets.symmetric(
                vertical: 10 * scale,
                horizontal: 12 * scale,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              textStyle: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
