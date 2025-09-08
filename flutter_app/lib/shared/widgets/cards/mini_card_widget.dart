// lib/shared/widgets/mini_card_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/mini_card_service.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/weekly_stats_service.dart';

import 'package:flutter_svg/flutter_svg.dart';

/// MiniCard que busca valor via service e exibe:
/// - ícone (Material ou SVG), título, valor e botão opcional.
class MiniCardWidget extends StatelessWidget {
  /// Aqui trocamos IconData por um Widget: qualquer ícone que você quiser.
  final Widget iconWidget;
  final String title;
  final String tipo; // chave para o service
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final bool showButton;
  final Widget? buttonWidget; // mesmo conceito para botão, se quiser

  const MiniCardWidget({
    Key? key,
    required this.iconWidget,
    required this.title,
    required this.tipo,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    this.showButton = false,
    this.buttonWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<String>(
      future:
          (tipo == WeeklyStatsType.cargas ||
                  tipo == WeeklyStatsType.frequencia ||
                  tipo == WeeklyStatsType.esforco)
              ? WeeklyStatsService.getWeeklyStat(tipo: tipo)
              : MiniCardService.getCardInfo(tipo: tipo),
      builder: (context, snapshot) {
        final value =
            snapshot.connectionState == ConnectionState.waiting
                ? '...'
                : snapshot.hasError
                ? 'Erro'
                : snapshot.data ?? 'N/A';

        return Container(
          width: 120 * scale,
          padding: EdgeInsets.symmetric(
            horizontal: 6 * scale,
            vertical: 8 * scale,
          ),
          decoration: BoxDecoration(
            color: backgroundColor.withAlpha(70),
            border: Border.all(color: borderColor, width: 1 * scale),
            borderRadius: BorderRadius.circular(10 * scale),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Linha de ícone + título ───────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // aqui usamos o widget passado
                  iconWidget,
                  SizedBox(width: 6 * scale),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.bold,
                      fontSize: 14 * scale,
                      color: iconColor,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 4 * scale),

              // ── Valor principal ────────────────────────────────
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.bold,
                  fontSize: 14 * scale,
                  color: AppColors.darkText,
                ),
              ),

              // ── Botão opcional ────────────────────────────────
              if (showButton && buttonWidget != null)
                Padding(
                  padding: EdgeInsets.only(top: 8 * scale),
                  child: buttonWidget!,
                ),
            ],
          ),
        );
      },
    );
  }
}
