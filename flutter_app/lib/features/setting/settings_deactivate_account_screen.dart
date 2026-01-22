import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/settings/accaount_service.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';

class SettingsDeactivateAccountScreen extends StatefulWidget {
  static const routeName = '/settings/deactivate_account';
  const SettingsDeactivateAccountScreen({super.key});

  @override
  State<SettingsDeactivateAccountScreen> createState() =>
      _SettingsDeactivateAccountScreenState();
}

class _SettingsDeactivateAccountScreenState
    extends State<SettingsDeactivateAccountScreen> {
  final _service = AccountService();
  bool _loading = false;

  Future<void> _confirmDeactivate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Desativar conta?'),
          content: const Text('Sua conta ficará desativada temporariamente.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() => _loading = true);
    await _service.requestDeactivateAccount();
    setState(() => _loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Solicitação enviada (mock).')),
    );
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
            const SettingsHeader(title: 'Desativar conta'),
            Text(
              'Desativa temporariamente o acesso. Você poderá reativar no futuro.',
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
                onPressed: _loading ? null : _confirmDeactivate,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled))
                      return AppColors.lightGray;
                    return Colors.orange.shade700;
                  }),
                  elevation: const MaterialStatePropertyAll(0),
                ),
                child: Text(_loading ? 'Enviando...' : 'Desativar conta'),
              ),
            ),

            SizedBox(height: 12 * scale),
            Text(
              'TODO(BACKEND): marcar conta como desativada + validar login.',
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
