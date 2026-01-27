import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/settings/support_service.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';

class SettingsFeedbackScreen extends StatefulWidget {
  static const routeName = '/settings/feedback';
  const SettingsFeedbackScreen({super.key});

  @override
  State<SettingsFeedbackScreen> createState() => _SettingsFeedbackScreenState();
}

class _SettingsFeedbackScreenState extends State<SettingsFeedbackScreen> {
  final _service = SettingsSupportService();
  final _ctrl = TextEditingController();
  int _rating = 5;
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    await _service.sendFeedback(_ctrl.text.trim(), _rating);
    setState(() => _loading = false);

    if (!mounted) return;
    _ctrl.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback enviado (mock).')));
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
            const SettingsHeader(title: 'Feedback'),
            Text(
              'Conte o que você gostaria de ver melhor no app.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 12 * scale),

            Text(
              'Nota: $_rating/10',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13 * scale,
                fontWeight: AppFontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
            Slider(
              value: _rating.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (v) => setState(() => _rating = v.round()),
              activeColor: AppColors.baseBlue,
            ),

            TextField(
              controller: _ctrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Sua sugestão',
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
                  backgroundColor: MaterialStatePropertyAll(AppColors.baseBlue),
                  elevation: MaterialStatePropertyAll(0),
                ),
                child: Text(_loading ? 'Enviando...' : 'Enviar feedback'),
              ),
            ),

            SizedBox(height: 12 * scale),
            Text(
              'TODO(BACKEND): armazenar feedback + rating + versão do app + device.',
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
