import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/pending_actions_service.dart';

/// Banner de Ações Pendentes (mostra no máx. 1 card).
/// Some quando não há pendência.
class PendingActionsSection extends StatelessWidget {
  /// Espaço após a section (pedido: respiro no final da section).
  final double? bottomSpacing;

  const PendingActionsSection({Key? key, this.bottomSpacing}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final spacing = bottomSpacing ?? 16 * scale;

    return FutureBuilder<PendingAction?>(
      future: PendingActionsService.fetchTopPendingForToday(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final action = snap.data;
        if (action == null) return const SizedBox.shrink();

        final card = Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 10 * scale,
          ),
          decoration: BoxDecoration(
            color: AppColors.lightMagenta.withAlpha(50),
            borderRadius: BorderRadius.circular(12 * scale),
            border: Border.all(color: AppColors.baseMagenta, width: 1 * scale),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Mensagem
              Text(
                action.message,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.regular,
                  fontSize: 12 * scale,
                  color: AppColors.darkText,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 6 * scale),
              // CTA (texto azul com ícone "edit")
              TextButton.icon(
                onPressed: () async {
                  if (action.onTap != null) {
                    await action.onTap!(
                      context,
                    ); // abre o bottom sheet na mesma tela
                  } else if (action.route.isNotEmpty) {
                    Navigator.of(
                      context,
                    ).pushNamed(action.route); // navega quando for o caso
                  }
                },
                icon: Icon(
                  action.ctaIcon,
                  color: AppColors.baseBlue,
                  size: 16 * scale,
                ),
                label: Text(
                  action.ctaLabel,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 12 * scale,
                    color: AppColors.baseBlue,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            card,
            SizedBox(height: spacing), // respiro para a próxima section
          ],
        );
      },
    );
  }
}
