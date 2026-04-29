import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/settings/accaount_service.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';
import 'package:flutter_app/routes/app_routes.dart';

class SettingsResetPasswordScreen extends StatefulWidget {
  static const routeName = '/settings/reset_password';
  const SettingsResetPasswordScreen({super.key});

  @override
  State<SettingsResetPasswordScreen> createState() =>
      _SettingsResetPasswordScreenState();
}

class _SettingsResetPasswordScreenState
    extends State<SettingsResetPasswordScreen> {
  final _service = AccountService();
  bool _loading = false;

  Future<void> _sendReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Redefinir senha?'),
          content: const Text(
            'Enviaremos um link para o email da sua conta e você será desconectado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.mediumGray),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.baseBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar link'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await _service.sendCurrentUserPasswordResetAndSignOut();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar o email de redefinição.'),
        ),
      );
      setState(() => _loading = false);
    }
  }

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
              'Vamos enviar o link de redefinição para o email da sua conta.',
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
                onPressed: _loading ? null : _sendReset,
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.baseBlue),
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                  elevation: WidgetStatePropertyAll(0),
                ),
                child: Text(_loading ? 'Enviando...' : 'Enviar link'),
              ),
            ),
            SizedBox(height: 12 * scale),
            Text(
              'Após o envio, entre novamente quando concluir a troca de senha.',
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
