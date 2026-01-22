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

    setState(() => _loading = true);
    await _service.requestDeleteAccount();
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
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled))
                      return AppColors.lightGray;
                    return Colors.red.shade700;
                  }),
                  elevation: const MaterialStatePropertyAll(0),
                ),
                child: Text(_loading ? 'Enviando...' : 'Solicitar exclusão'),
              ),
            ),

            SizedBox(height: 12 * scale),
            Text(
              'TODO(BACKEND): registrar solicitação, prazos, LGPD e remoção de dados.',
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
