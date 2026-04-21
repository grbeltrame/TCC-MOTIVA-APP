// lib/shared/widgets/carousels/athlete_insights_carousel.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_insights_service.dart';

/// Carrossel padronizado para os insights do atleta.
///
/// Mantém o mesmo tamanho/proporção do [PerformanceInsightsCarousel]
/// original, mas desenha cards com:
///   - Amarelo + ícone de alerta para alertas
///   - Paleta padrão (azul) para informações
///   - Badge "Semana" ou "Evolução" para diferenciar a origem
class AthleteInsightsCarousel extends StatefulWidget {
  final List<InsightCardItem> items;

  /// Callback opcional ao tocar em qualquer card — usado para o "ver mais"
  /// nas telas de insights/evolução.
  final VoidCallback? onTap;

  /// Quando true, mostra um card único "gerando análise..." (usado na tela
  /// de evolução enquanto a IA roda).
  final bool loading;
  final String? loadingMessage;

  const AthleteInsightsCarousel({
    Key? key,
    required this.items,
    this.onTap,
    this.loading = false,
    this.loadingMessage,
  }) : super(key: key);

  @override
  State<AthleteInsightsCarousel> createState() =>
      _AthleteInsightsCarouselState();
}

class _AthleteInsightsCarouselState extends State<AthleteInsightsCarousel> {
  final _controller = PageController(viewportFraction: 1);
  Timer? _ticker;
  bool _started = false;

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll(int count) {
    if (_started || count <= 1) return;
    _started = true;

    void tick() {
      if (!mounted || count <= 1) return;
      final current =
          _controller.hasClients ? (_controller.page?.round() ?? 0) : 0;
      final next = (current + 1) % count;
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
    // Mesma altura que o carrossel original (3 linhas de texto + padding).
    final height = (16 + 14 * 3 + 16) * scale;

    if (widget.loading) {
      return SizedBox(
        height: height,
        child: _LoadingCard(
          scale: scale,
          message: widget.loadingMessage ??
              'Gerando sua análise, isso leva alguns segundos...',
        ),
      );
    }

    if (widget.items.isEmpty) return const SizedBox.shrink();

    _startAutoScroll(widget.items.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            itemBuilder: (ctx, i) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                child: _InsightCard(
                  item: widget.items[i],
                  scale: scale,
                  onTap: widget.onTap,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16 * scale),
      ],
    );
  }
}

// =============================================================================
// Card unitário
// =============================================================================

class _InsightCard extends StatelessWidget {
  final InsightCardItem item;
  final double scale;
  final VoidCallback? onTap;

  const _InsightCard({
    required this.item,
    required this.scale,
    this.onTap,
  });

  // Paletas
  // Alerta → amarelo com texto legível
  static const _alertBg = Color(0xFFFFF6D6);
  static const _alertBorder = Color(0xFFE7B400);
  static const _alertText = Color(0xFF5C4300);

  @override
  Widget build(BuildContext context) {
    final isAlert = item.kind == InsightKind.alert;
    final isWeekly = item.source == InsightSource.weekly;

    final bg = isAlert ? _alertBg : Colors.white;
    final border = isAlert ? _alertBorder : AppColors.baseBlue;
    final iconColor = isAlert ? _alertBorder : AppColors.baseBlue;
    final textColor = isAlert ? _alertText : AppColors.darkText;

    final icon = isAlert
        ? Icons.warning_amber_rounded
        : (isWeekly ? Icons.calendar_today_outlined : Icons.trending_up);

    final badgeLabel = isWeekly ? 'Semana' : 'Evolução';
    final badgeIcon =
        isWeekly ? Icons.calendar_today : Icons.trending_up;

    final card = Container(
      padding: EdgeInsets.symmetric(
        vertical: 8 * scale,
        horizontal: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 26 * scale, color: iconColor),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 56 * scale),
                  child: Text(
                    item.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 13 * scale,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _SourceBadge(
              label: badgeLabel,
              icon: badgeIcon,
              scale: scale,
              isAlert: isAlert,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12 * scale),
      child: card,
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final double scale;
  final bool isAlert;
  const _SourceBadge({
    required this.label,
    required this.icon,
    required this.scale,
    required this.isAlert,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isAlert
        ? const Color(0xFF5C4300)
        : AppColors.baseBlue;
    final bg = isAlert
        ? const Color(0xFFFFE999)
        : AppColors.baseBlue.withValues(alpha: 0.08);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scale,
        vertical: 2 * scale,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9 * scale, color: fg),
          SizedBox(width: 3 * scale),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 9 * scale,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Loading state — usado enquanto a IA de evolução está rodando
// =============================================================================

class _LoadingCard extends StatelessWidget {
  final double scale;
  final String message;
  const _LoadingCard({required this.scale, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12 * scale,
          horizontal: 16 * scale,
        ),
        decoration: BoxDecoration(
          color: AppColors.baseBlue.withValues(alpha: 0.06),
          border: Border.all(color: AppColors.baseBlue.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22 * scale,
              height: 22 * scale,
              child: CircularProgressIndicator(
                strokeWidth: 2.2 * scale,
                valueColor: AlwaysStoppedAnimation(AppColors.baseBlue),
              ),
            ),
            SizedBox(width: 12 * scale),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.w500,
                  fontSize: 13 * scale,
                  color: AppColors.darkBlue,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
