import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Carrossel simples de textos longos:
/// - 1 insight por vez
/// - Altura se adapta ao tamanho do texto (nada é cortado)
/// - Navegação por setas (esquerda / direita)
class AdaptiveInsightsCarousel extends StatefulWidget {
  final String title; // Ex.: "Análise:", "Alertas:", ...
  final IconData icon; // Ex.: Icons.analytics_outlined
  final Color pillColor; // Cor de fundo do "chip" do título
  final Color pillTextColor; // Cor do texto/ícone do chip
  final List<String> messages; // Lista de insights (pode ser vazia)

  const AdaptiveInsightsCarousel({
    Key? key,
    required this.title,
    required this.icon,
    required this.pillColor,
    required this.pillTextColor,
    required this.messages,
  }) : super(key: key);

  @override
  State<AdaptiveInsightsCarousel> createState() =>
      _AdaptiveInsightsCarouselState();
}

class _AdaptiveInsightsCarouselState extends State<AdaptiveInsightsCarousel>
    with TickerProviderStateMixin {
  int _index = 0;

  void _goPrev() {
    if (widget.messages.isEmpty) return;
    setState(() {
      if (_index > 0) {
        _index--;
      }
    });
  }

  void _goNext() {
    if (widget.messages.isEmpty) return;
    setState(() {
      if (_index < widget.messages.length - 1) {
        _index++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final hasMessages = widget.messages.isNotEmpty;
    final currentText =
        hasMessages ? widget.messages[_index] : 'Nenhum insight disponível.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Chip" colorido com ícone + título (Análise:, Alertas:, etc.)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * scale,
            vertical: 4 * scale,
          ),
          decoration: BoxDecoration(
            color: widget.pillColor,
            borderRadius: BorderRadius.circular(6 * scale),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14 * scale, color: widget.pillTextColor),
              SizedBox(width: 4 * scale),
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 11 * scale,
                  color: widget.pillTextColor,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 8 * scale),

        // Texto do insight – altura dinâmica
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Text(
            currentText,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
              color: AppColors.darkText,
            ),
          ),
        ),

        SizedBox(height: 8 * scale),

        // Setinhas + indicador de página
        if (hasMessages && widget.messages.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // seta esquerda
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: 24 * scale,
                  height: 24 * scale,
                ),
                icon: Icon(
                  Icons.chevron_left,
                  size: 22 * scale,
                  color:
                      _index > 0
                          ? AppColors.baseBlue
                          : AppColors.mediumGray.withOpacity(0.5),
                ),
                onPressed: _index > 0 ? _goPrev : null,
              ),

              // indicador "1/3"
              Text(
                '${_index + 1}/${widget.messages.length}',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 11 * scale,
                  color: AppColors.mediumGray,
                ),
              ),

              // seta direita
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: 24 * scale,
                  height: 24 * scale,
                ),
                icon: Icon(
                  Icons.chevron_right,
                  size: 22 * scale,
                  color:
                      _index < widget.messages.length - 1
                          ? AppColors.baseBlue
                          : AppColors.mediumGray.withOpacity(0.5),
                ),
                onPressed: _index < widget.messages.length - 1 ? _goNext : null,
              ),
            ],
          ),
      ],
    );
  }
}
