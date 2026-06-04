import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/insights_service.dart';
import 'package:flutter_app/shared/models/inisght_model.dart';

/// Carrossel que exibe **apenas** insights de desempenho do atleta.
/// Some se o usuário desabilitar esse tipo OU se não houver insights no dia.
class PerformanceInsightsCarousel extends StatefulWidget {
  const PerformanceInsightsCarousel({Key? key}) : super(key: key);

  @override
  State<PerformanceInsightsCarousel> createState() =>
      _PerformanceInsightsCarouselState();
}

class _PerformanceInsightsCarouselState
    extends State<PerformanceInsightsCarousel> {
  final _svc = InsightsService();
  final _controller = PageController(viewportFraction: 1);
  Timer? _ticker;
  bool _started = false;

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll(int itemCount) {
    if (_started || itemCount <= 1) return;
    _started = true;

    void tick() {
      if (!mounted || itemCount <= 1) return;
      final current =
          _controller.hasClients ? (_controller.page?.round() ?? 0) : 0;
      final next = (current + 1) % itemCount;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _ticker = Timer(const Duration(seconds: 8), tick);
    }

    _ticker = Timer(const Duration(seconds: 5), tick);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<bool>(
      future: _svc.fetchShowPerformanceInsightsSection(),
      builder: (context, showSnap) {
        if (showSnap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final show = showSnap.data ?? false;
        if (!show) return const SizedBox.shrink();

        return FutureBuilder<Set<String>>(
          future: _svc.fetchEnabledInsightTypes(),
          builder: (context, typesSnap) {
            if (typesSnap.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            final enabled = typesSnap.data ?? {};
            if (!enabled.contains(InsightsService.performanceType)) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<List<InsightsModel>>(
              future: _svc.fetchDailyPerformanceInsights(DateTime.now()),
              builder: (context, dataSnap) {
                if (dataSnap.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                final items = (dataSnap.data ?? []);
                if (items.isEmpty) return const SizedBox.shrink();

                _startAutoScroll(items.length);

                // === Carrossel + espaçamento para a próxima seção ===
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      // mesma altura do highlights (3 linhas máx)
                      height: (16 + 14 * 3 + 16) * scale,
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final insight = items[i];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4 * scale,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 8 * scale,
                                horizontal: 12 * scale,
                              ),
                              decoration: BoxDecoration(
                                // diferença: borda azul
                                border: Border.all(color: AppColors.baseBlue),
                                borderRadius: BorderRadius.circular(12 * scale),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // mesmo ícone do highlights
                                  SvgPicture.asset(
                                    'assets/icons/social_leaderboard.svg',
                                    width: 28 * scale,
                                    height: 28 * scale,
                                    color: AppColors.baseBlue,
                                  ),
                                  SizedBox(width: 8 * scale),
                                  Expanded(
                                    child: Text(
                                      insight.message,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontFamily: AppFonts.roboto,
                                        fontWeight: AppFontWeight.bold,
                                        fontSize: 14 * scale,
                                        color: AppColors.darkText,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Espaço para a próxima section
                    SizedBox(height: 16 * scale),
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
