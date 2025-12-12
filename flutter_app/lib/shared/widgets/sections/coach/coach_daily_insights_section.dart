import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/users/coach/daily_insights_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/carousels/recomendations_carousel.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';

/// Section que exibe um carrossel de insights do COACH.
/// Modo 1 (legado): sem filtros -> insights do DIA.
/// Modo 2 (novo): se [selectedCategory] **e** [trainingId] vierem, mostra
/// apenas insights do treino específico (categoria + data + treino).
class CoachDailyInsightsSection extends StatelessWidget {
  final DateTime date;
  final String boxId;

  /// (Opcional) treino específico
  final String? selectedCategory; // 'WOD' | 'LPO' | 'Ginastica' | 'Endurance'
  final String? trainingId;

  /// Título opcional. Se não vier:
  /// - com treino específico → "Insights do Treino"
  /// - legado → "Insights do dia"
  final String? title;

  /// Exibir botão “ver todos os insights” ao lado do título (padrão: false).
  final bool showSeeAllButton;

  /// Callback do botão “ver todos os insights”.
  /// Se não vier, faz fallback para a tela de projeção de ciclo
  /// (`CoachTrainingInsightsScreen`) já com o mês atual.
  final VoidCallback? onSeeAll;

  /// NOVO: botões do footer opcionais (true = mantém comportamento atual).
  final bool showWeeklyAnalysisButton;
  final bool showCycleProjectionButton;

  const CoachDailyInsightsSection({
    super.key,
    required this.date,
    required this.boxId,
    this.selectedCategory,
    this.trainingId,
    this.title,
    this.showSeeAllButton = false,
    this.onSeeAll,
    this.showWeeklyAnalysisButton = false,
    this.showCycleProjectionButton = true,
  });

  bool get _isTrainingScoped => selectedCategory != null && trainingId != null;
  bool get _showActionsRow =>
      showWeeklyAnalysisButton || showCycleProjectionButton;

  String _defaultTitle() =>
      title ?? (_isTrainingScoped ? 'Insights do Treino' : 'Insights do dia');

  /// Sempre retorna um VoidCallback válido (evita "use_of_void_result").
  /// Se não receber [onSeeAll], navega para CoachTrainingInsights com o mês atual.
  VoidCallback _resolveSeeAll(BuildContext context) {
    if (onSeeAll != null) return onSeeAll!;

    return () {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      Navigator.pushNamed(
        context,
        AppRoutes.coachTrainingInsights,
        arguments: {
          'month': currentMonth,
          // se quiser depois, pode passar boxId aqui também:
          // 'boxId': boxId,
        },
      );
    };
  }

  String _fmtDateLong(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day/$m/$y';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final service = CoachDailyInsightsService();

    // 1) Tipos habilitados pelo coach
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

        // ───────────────── MODO 2: treino específico ─────────────────
        if (_isTrainingScoped) {
          final cat = selectedCategory!;
          if (!enabled.contains(cat)) return const SizedBox.shrink();

          return FutureBuilder<List<CoachInsightModel>>(
            future: service.fetchCoachInsightsForTraining(
              boxId: boxId,
              trainingId: trainingId!,
              date: date,
              category: cat,
            ),
            builder: (ctx2, snapScoped) {
              if (snapScoped.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final list = snapScoped.data ?? [];

              if (list.isEmpty) {
                return _TitleAndEmpty(
                  title: _defaultTitle(),
                  showSeeAllButton: showSeeAllButton,
                  onSeeAll: _resolveSeeAll(context),
                  emptyText: 'Sem insights para $cat em ${_fmtDateLong(date)}.',
                );
              }

              final recos =
                  list
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
                  _TitleRow(
                    title: _defaultTitle(),
                    showSeeAllButton: showSeeAllButton,
                    onSeeAll: _resolveSeeAll(context),
                    scale: scale,
                  ),
                  SizedBox(height: 8 * scale),
                  RecomendationsCarousel(
                    allRecomendations: recos,
                    enabledRecomendationsTypes: {cat},
                  ),
                  if (_showActionsRow) ...[
                    SizedBox(height: 16 * scale),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                      child: _CoachInsightsActions(
                        scale: scale,
                        showWeekly: showWeeklyAnalysisButton,
                        showCycleProjection: showCycleProjectionButton,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                  ],
                ],
              );
            },
          );
        }

        // ───────────────── MODO 1: legado (insights do dia) ─────────────────
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

                final filtered =
                    allCoachInsights
                        .where((i) => enabled.contains(i.type))
                        .where((i) => existing.contains(i.type))
                        .toList();

                if (filtered.isEmpty) {
                  return _TitleAndEmpty(
                    title: _defaultTitle(),
                    showSeeAllButton: showSeeAllButton,
                    onSeeAll: _resolveSeeAll(context),
                    emptyText:
                        'Sem insights gerados para ${_fmtDateLong(date)}.',
                  );
                }

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
                    _TitleRow(
                      title: _defaultTitle(),
                      showSeeAllButton: showSeeAllButton,
                      onSeeAll: _resolveSeeAll(context),
                      scale: scale,
                    ),
                    SizedBox(height: 8 * scale),
                    RecomendationsCarousel(
                      allRecomendations: recos,
                      enabledRecomendationsTypes: enabled.intersection(
                        existing,
                      ),
                    ),
                    if (_showActionsRow) ...[
                      SizedBox(height: 16 * scale),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                        child: _CoachInsightsActions(
                          scale: scale,
                          showWeekly: showWeeklyAnalysisButton,
                          showCycleProjection: showCycleProjectionButton,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                    ],
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

class _TitleRow extends StatelessWidget {
  final String title;
  final bool showSeeAllButton;
  final VoidCallback onSeeAll;
  final double scale;

  const _TitleRow({
    required this.title,
    required this.showSeeAllButton,
    required this.onSeeAll,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          if (showSeeAllButton)
            TextActionButton(
              text: 'Ver todos os insights',
              onPressed: onSeeAll,
              icon: Icons.add,
              color: AppColors.baseBlue,
            ),
        ],
      ),
    );
  }
}

class _TitleAndEmpty extends StatelessWidget {
  final String title;
  final bool showSeeAllButton;
  final VoidCallback onSeeAll;
  final String emptyText;

  const _TitleAndEmpty({
    required this.title,
    required this.showSeeAllButton,
    required this.onSeeAll,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TitleRow(
          title: title,
          showSeeAllButton: showSeeAllButton,
          onSeeAll: onSeeAll,
          scale: scale,
        ),
        SizedBox(height: 8 * scale),
        Center(
          child: Padding(
            padding: EdgeInsets.all(16 * scale),
            child: Text(emptyText, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}

class _CoachInsightsActions extends StatelessWidget {
  final double scale;
  final bool showWeekly;
  final bool showCycleProjection;

  const _CoachInsightsActions({
    required this.scale,
    required this.showWeekly,
    required this.showCycleProjection,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (showWeekly) {
      children.add(
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
                side: const BorderSide(color: AppColors.darkBlue, width: 1),
              ),
              textStyle: TextStyle(
                fontSize: 12 * scale,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    if (showWeekly && showCycleProjection) {
      children.add(SizedBox(width: 8 * scale));
    }

    if (showCycleProjection) {
      children.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // 🔹 Navega para a tela de insights de ciclo
              //     já com o MÊS ATUAL selecionado.
              final now = DateTime.now();
              final currentMonth = DateTime(now.year, now.month);

              Navigator.pushNamed(
                context,
                AppRoutes.coachTrainingInsights,
                arguments: {
                  'month': currentMonth,
                  // se quiser depois passar boxId aqui, é só incluir:
                  // 'boxId': '1',
                },
              );
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
              style: const TextStyle(color: AppColors.darkBlue),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.darkBlue, width: 1),
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
      );
    }

    return Row(children: children);
  }
}
