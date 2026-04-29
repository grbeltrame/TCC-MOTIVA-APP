import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/settings/support_service.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';

class SettingsSupportScreen extends StatefulWidget {
  static const routeName = '/settings/support';
  const SettingsSupportScreen({super.key});

  @override
  State<SettingsSupportScreen> createState() => _SettingsSupportScreenState();
}

class _SettingsSupportScreenState extends State<SettingsSupportScreen> {
  final _service = SettingsSupportService();
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _service.sendSupportMessage(_ctrl.text.trim());
      if (!mounted) return;
      _ctrl.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mensagem enviada.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar a mensagem.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
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
            const SettingsHeader(title: 'Suporte'),
            Text(
              'Envie uma mensagem para o suporte do app.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 12 * scale),

            TextField(
              controller: _ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Descreva sua dúvida',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12 * scale),

            SizedBox(
              width: double.infinity,
              height: 44 * scale,
              child: ElevatedButton(
                onPressed: _loading ? null : _send,
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.baseBlue),
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                  elevation: WidgetStatePropertyAll(0),
                ),
                child: Text(_loading ? 'Enviando...' : 'Enviar'),
              ),
            ),

            SizedBox(height: 12 * scale),
            Text(
              'A mensagem será enviada para o suporte do projeto.',
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
