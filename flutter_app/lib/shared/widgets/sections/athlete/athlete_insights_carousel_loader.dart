// lib/shared/widgets/sections/athlete/athlete_insights_carousel_loader.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/athlete_insights_service.dart';
import 'package:flutter_app/shared/widgets/carousels/athlete_insights_carousel.dart';

/// Modo de operação do loader.
enum AthleteInsightsMode {
  /// Home: mixa 2 insights semanais + 2 de evolução, sorteados.
  homeMix,

  /// Tela de insights semanais: só insights da semana.
  weeklyOnly,

  /// Tela de evolução: só insights de evolução. Dispara o onCall se
  /// o cache estiver vazio/expirado (o backend já decide isso).
  evolutionOnly,
}

/// Wrapper que carrega os insights do atleta e exibe o carrossel.
class AthleteInsightsCarouselLoader extends StatefulWidget {
  final AthleteInsightsMode mode;

  /// Callback para "ver mais" — clique em qualquer card.
  final VoidCallback? onTap;

  /// Força seed fixa para o sorteio (útil em testes). Null = aleatório.
  final int? seed;

  const AthleteInsightsCarouselLoader({
    Key? key,
    required this.mode,
    this.onTap,
    this.seed,
  }) : super(key: key);

  @override
  State<AthleteInsightsCarouselLoader> createState() =>
      AthleteInsightsCarouselLoaderState();
}

class AthleteInsightsCarouselLoaderState
    extends State<AthleteInsightsCarouselLoader> {
  AthleteWeeklyInsights? _weekly;
  AthleteEvolutionInsights? _evolution;

  bool _loadingEvolution = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Permite que a tela chame reload() externamente (ex: após gerar evolução).
  Future<void> reload() => _load();

  Future<void> _load() async {
    if (widget.mode == AthleteInsightsMode.weeklyOnly ||
        widget.mode == AthleteInsightsMode.homeMix) {
      try {
        final w = await AthleteInsightsService.fetchWeekly();
        if (mounted) setState(() => _weekly = w);
      } catch (e, st) {
        debugPrint('[InsightsLoader] fetchWeekly falhou: $e\n$st');
      }
    }

    if (widget.mode == AthleteInsightsMode.evolutionOnly ||
        widget.mode == AthleteInsightsMode.homeMix) {
      setState(() => _loadingEvolution = true);
      try {
        final cached =
            await AthleteInsightsService.fetchEvolutionCached();
        if (mounted && cached != null) {
          setState(() => _evolution = cached);
        }

        if (widget.mode == AthleteInsightsMode.evolutionOnly) {
          debugPrint('[InsightsLoader] chamando onCall get_athlete_evolution_insights...');
          final fresh = await AthleteInsightsService.fetchEvolution();
          debugPrint('[InsightsLoader] onCall retornou: alertas=${fresh.alertas.length} infos=${fresh.informacoes.length}');
          if (mounted) setState(() => _evolution = fresh);
        }
      } catch (e, st) {
        debugPrint('[InsightsLoader] evolution falhou: $e\n$st');
      } finally {
        if (mounted) setState(() => _loadingEvolution = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading "gerando análise..." só aparece na tela de evolução quando
    // ainda não temos NENHUM dado (cache vazio + onCall rodando).
    if (widget.mode == AthleteInsightsMode.evolutionOnly &&
        _loadingEvolution &&
        (_evolution == null || _evolution!.isEmpty)) {
      return const AthleteInsightsCarousel(
        items: [],
        loading: true,
      );
    }

    final List<InsightCardItem> items = switch (widget.mode) {
      AthleteInsightsMode.homeMix => AthleteInsightsService.buildHomeMix(
          weekly: _weekly,
          evolution: _evolution,
          seed: widget.seed,
        ),
      AthleteInsightsMode.weeklyOnly => _weekly?.toCards() ?? const [],
      AthleteInsightsMode.evolutionOnly =>
        _evolution?.toCards() ?? const [],
    };

    if (items.isEmpty) return const SizedBox.shrink();

    return AthleteInsightsCarousel(
      items: items,
      onTap: widget.onTap,
    );
  }
}
