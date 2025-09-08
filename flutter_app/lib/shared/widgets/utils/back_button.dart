// lib/shared/widgets/back_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';

/// Botão de voltar padrão, com ícone e texto "Voltar".
/// - Usa Navigator.maybePop() para evitar tela preta quando não há rota anterior.
/// - Se não conseguir voltar, navega para [fallbackRoute] limpando a pilha.
/// - Opcionalmente pode atuar no rootNavigator.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    Key? key,
    this.label = 'Voltar',
    this.fallbackRoute = AppRoutes.athleteHome,
    this.useRootNavigator = false,
  }) : super(key: key);

  /// Texto do botão.
  final String label;

  /// Rota de fallback quando não há nada para voltar.
  final String fallbackRoute;

  /// Se true, usa o rootNavigator (útil em casos com Navigators aninhados).
  final bool useRootNavigator;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return TextButton.icon(
      onPressed: () async {
        final nav = Navigator.of(context, rootNavigator: useRootNavigator);

        // maybePop tenta dar pop; retorna true se conseguiu.
        final popped = await nav.maybePop();
        if (!popped) {
          // Nada para voltar → vamos para a home (ou rota que você quiser)
          nav.pushNamedAndRemoveUntil(fallbackRoute, (route) => false);
        }
      },
      icon: Icon(
        Icons.chevron_left, // ícone mais padrão de "voltar"
        size: 20 * scale,
        color: AppColors.darkBlue,
        semanticLabel: 'Voltar',
      ),
      label: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.medium,
          fontSize: 16 * scale,
          color: AppColors.darkBlue,
        ),
      ),
      style: TextButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
