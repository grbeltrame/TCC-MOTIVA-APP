import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';
import 'package:flutter_app/routes/app_routes.dart';

class SettingsResetPasswordScreen extends StatelessWidget {
  static const routeName = '/settings/reset_password';
  const SettingsResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SettingsScaffold(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 8 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsHeader(title: 'Redefinir senha'),
            Text(
              'Nos informe seu email para enviarmos o link de redefinicao de senha.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 16 * scale),
            SizedBox(
              width: double.infinity,
              height: 44 * scale,
              child: ElevatedButton(
                onPressed:
                    () =>
                        Navigator.pushNamed(context, AppRoutes.forgotPassword),
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.baseBlue),
                  elevation: WidgetStatePropertyAll(0),
                ),
                child: const Text('Continuar'),
              ),
            ),
            SizedBox(height: 12 * scale),
            Text(
              'Se o email estiver cadastrado, o link sera enviado para a caixa de entrada. Vale conferir tambem a pasta de spam.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 11 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
