import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/settings/accaount_service.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';

class SettingsDeleteAccountScreen extends StatefulWidget {
  static const routeName = '/settings/delete_account';
  const SettingsDeleteAccountScreen({super.key});

  @override
  State<SettingsDeleteAccountScreen> createState() =>
      _SettingsDeleteAccountScreenState();
}

class _SettingsDeleteAccountScreenState
    extends State<SettingsDeleteAccountScreen> {
  final _service = AccountService();
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _requestDelete() async {
    if (_ctrl.text.trim().toUpperCase() != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite DELETE para confirmar.')),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Excluir permanentemente?'),
          content: const Text(
            'Essa ação apaga sua conta e seus dados de forma permanente.',
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
                backgroundColor: AppColors.baseMagenta,
                foregroundColor: Colors.white,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() => _loading = true);
    try {
      await _service.deleteCurrentAccount();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a conta.')),
      );
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
            const SettingsHeader(title: 'Excluir conta'),
            Text(
              'Essa ação é permanente. Para confirmar, digite DELETE.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 16 * scale),

            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: 'Digite DELETE',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12 * scale),

            SizedBox(
              width: double.infinity,
              height: 44 * scale,
              child: ElevatedButton(
                onPressed: _loading ? null : _requestDelete,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return AppColors.lightGray;
                    }
                    return AppColors.baseMagenta;
                  }),
                  foregroundColor: const WidgetStatePropertyAll(Colors.white),
                  elevation: const WidgetStatePropertyAll(0),
                ),
                child: Text(_loading ? 'Enviando...' : 'Solicitar exclusão'),
              ),
            ),

            SizedBox(height: 12 * scale),
            Text(
              'Ao confirmar, seus dados serão removidos permanentemente.',
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
