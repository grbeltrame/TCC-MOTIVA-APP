import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/settings/support_service.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';

class SettingsBugReportScreen extends StatefulWidget {
  static const routeName = '/settings/bug_report';
  const SettingsBugReportScreen({super.key});

  @override
  State<SettingsBugReportScreen> createState() =>
      _SettingsBugReportScreenState();
}

class _SettingsBugReportScreenState extends State<SettingsBugReportScreen> {
  final _service = SettingsSupportService();
  final _desc = TextEditingController();
  final _steps = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _desc.dispose();
    _steps.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_desc.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      await _service.sendBugReport(
        _desc.text.trim(),
        steps: _steps.text.trim().isEmpty ? null : _steps.text.trim(),
      );
      if (!mounted) return;
      _desc.clear();
      _steps.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Relato enviado.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível enviar o relato.')),
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
            const SettingsHeader(title: 'Reportar erro'),
            Text(
              'Descreva o problema e, se possível, como reproduzir.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 12 * scale),

            TextField(
              controller: _desc,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'O que aconteceu?',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12 * scale),
            TextField(
              controller: _steps,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Passo a passo (opcional)',
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
                child: Text(_loading ? 'Enviando...' : 'Enviar relatório'),
              ),
            ),

            SizedBox(height: 12 * scale),
            Text(
              'O relato será enviado para o suporte do projeto.',
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
