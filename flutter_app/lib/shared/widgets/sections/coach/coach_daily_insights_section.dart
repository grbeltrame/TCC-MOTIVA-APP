import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/users/coach/daily_insights_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/carousels/recomendations_carousel.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';

/// Section que exibe um carrossel de insights do COACH.
class CoachDailyInsightsSection extends StatelessWidget {
  final DateTime date;
  final String boxId;
  final String? selectedCategory;
  final String? trainingId;
  final String? title;
  final bool showSeeAllButton;
  final VoidCallback? onSeeAll;
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
      title ?? (_isTrainingScoped ? 'Análise do treino' : 'Análise do dia');

  VoidCallback _resolveSeeAll(BuildContext context) {
    if (onSeeAll != null) return onSeeAll!;

    return () {
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month);

      Navigator.pushNamed(
        context,
        AppRoutes.coachTrainingInsights,
        arguments: {'month': currentMonth},
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
                // CORREÇÃO AQUI: Passando os booleans para mostrar os botões
                return _TitleAndEmpty(
                  title: _defaultTitle(),
                  showSeeAllButton: showSeeAllButton,
                  onSeeAll: _resolveSeeAll(context),
                  emptyText:
                      'Sem análises para $cat em ${_fmtDateLong(date)}.',
                  showWeeklyAnalysisButton: showWeeklyAnalysisButton,
                  showCycleProjectionButton: showCycleProjectionButton,
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
            // Se não tem categoria existente no dia, mas queremos mostrar os botões mesmo assim?
            // O comportamento original retornava SizedBox.shrink().
            // Se você quiser que apareça "Sem insights" + Botão mesmo sem categorias,
            // remova este if. Por enquanto, mantive a lógica original.
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
                  // CORREÇÃO AQUI: Passando os booleans para mostrar os botões
                  return _TitleAndEmpty(
                    title: _defaultTitle(),
                    showSeeAllButton: showSeeAllButton,
                    onSeeAll: _resolveSeeAll(context),
                    emptyText:
                        'Sem análises geradas para ${_fmtDateLong(date)}.',
                    showWeeklyAnalysisButton: showWeeklyAnalysisButton,
                    showCycleProjectionButton: showCycleProjectionButton,
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
              text: 'Ver todas as análises',
              onPressed: onSeeAll,
              icon: Icons.add,
              color: AppColors.baseBlue,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CORREÇÃO NO WIDGET DE ESTADO VAZIO
// Antes ele só mostrava texto. Agora mostra texto E botões se configurado.
// ─────────────────────────────────────────────────────────────────────────────
class _TitleAndEmpty extends StatelessWidget {
  final String title;
  final bool showSeeAllButton;
  final VoidCallback onSeeAll;
  final String emptyText;

  // Novos campos recebidos
  final bool showWeeklyAnalysisButton;
  final bool showCycleProjectionButton;

  const _TitleAndEmpty({
    required this.title,
    required this.showSeeAllButton,
    required this.onSeeAll,
    required this.emptyText,
    required this.showWeeklyAnalysisButton,
    required this.showCycleProjectionButton,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // Verifica se deve mostrar a linha de ações
    final bool showActions =
        showWeeklyAnalysisButton || showCycleProjectionButton;

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

        // AQUI: Renderiza os botões mesmo no estado vazio
        if (showActions) ...[
          SizedBox(height: 8 * scale),
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
              final now = DateTime.now();
              final currentMonth = DateTime(now.year, now.month);

              Navigator.pushNamed(
                context,
                AppRoutes.coachTrainingInsights,
                arguments: {'month': currentMonth},
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
