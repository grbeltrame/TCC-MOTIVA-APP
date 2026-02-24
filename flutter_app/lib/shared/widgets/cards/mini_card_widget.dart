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
  final Widget iconWidget;
  final String title;
  final String? tipo; // 1. MUDOU AQUI: Agora é opcional (String?)
  final String? customValue; // 2. MUDOU AQUI: Nova variável de bypass
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final bool showButton;
  final Widget? buttonWidget;
  final double? titleFontSize;
  final double? valueFontSize;

  const MiniCardWidget({
    Key? key,
    required this.iconWidget,
    required this.title,
    this.tipo, // 3. MUDOU AQUI: Tirou o required
    this.customValue, // 4. MUDOU AQUI: Adicionado no construtor
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    this.showButton = false,
    this.buttonWidget,
    this.titleFontSize,
    this.valueFontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<String>(
      // 5. MUDOU AQUI: Se tem customValue, pula o serviço (fica null). Se não, chama normal.
      future:
          customValue != null
              ? null
              : (tipo == WeeklyStatsType.cargas ||
                  tipo == WeeklyStatsType.frequencia ||
                  tipo == WeeklyStatsType.esforco)
              ? WeeklyStatsService.getWeeklyStat(tipo: tipo!)
              : MiniCardService.getCardInfo(tipo: tipo!),
      builder: (context, snapshot) {
        // 6. MUDOU AQUI: Usa o customValue na hora, sem esperar nada. Senão, carrega o original.
        final value =
            customValue ??
            (snapshot.connectionState == ConnectionState.waiting
                ? '...'
                : snapshot.hasError
                ? 'Erro'
                : snapshot.data ?? 'N/A');

        return Container(
          //width: 120 * scale, // mantém a largura original do card
          padding: EdgeInsets.symmetric(
            horizontal: 6 * scale,
            vertical: 8 * scale,
          ),
          decoration: BoxDecoration(
            color: backgroundColor.withAlpha(70),
            border: Border.all(color: borderColor, width: 1 * scale),
            borderRadius: BorderRadius.circular(10 * scale),
          ),
          // dá um mínimo de altura para existir "espaço" e o botão poder ficar no meio
          constraints: BoxConstraints(minHeight: 90 * scale),
          child: Column(
            // quando tem botão, distribuímos o topo e o botão para "abraçar" o meio
            mainAxisAlignment:
                showButton
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Bloco topo: Ícone + título + valor ─────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      iconWidget,
                      SizedBox(width: 6 * scale),
                      // evita overflow lateral no título
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.bold,
                            fontSize: titleFontSize ?? 14,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.bold,
                      fontSize: (valueFontSize ?? 14) * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),

              // ── Botão centralizado AO MEIO ──────────────────────────────────
              if (showButton && buttonWidget != null)
                Center(child: buttonWidget!),
            ],
          ),
        );
      },
    );
  }
}
