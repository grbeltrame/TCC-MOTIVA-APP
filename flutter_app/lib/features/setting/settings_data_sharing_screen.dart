import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/settings/setting_privacy_service.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';

class SettingsDataSharingScreen extends StatefulWidget {
  static const routeName = '/settings/data_sharing';
  const SettingsDataSharingScreen({super.key});

  @override
  State<SettingsDataSharingScreen> createState() =>
      _SettingsDataSharingScreenState();
}

class _SettingsDataSharingScreenState extends State<SettingsDataSharingScreen> {
  final _service = SettingsPrivacyService();
  late Future<SettingsPrivacyState> _future;
  SettingsPrivacyState _state = SettingsPrivacyState.defaults();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<SettingsPrivacyState> _load() async {
    final s = await _service.fetch();
    _state = s;
    return s;
  }

  Future<void> _save() async {
    await _service.update(_state);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SettingsScaffold(
      child: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 8 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsHeader(title: 'Compartilhamento de dados'),
                Text(
                  'Controle o que o app pode coletar para melhorar a experiência.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
                SizedBox(height: 12 * scale),

                _SwitchRow(
                  title: 'Compartilhar dados de uso (analytics)',
                  value: _state.shareAnalytics,
                  onChanged: (v) async {
                    setState(() => _state.shareAnalytics = v);
                    await _save();
                  },
                ),
                _SwitchRow(
                  title: 'Enviar relatórios de falhas (crash reports)',
                  value: _state.shareCrashReports,
                  onChanged: (v) async {
                    setState(() => _state.shareCrashReports = v);
                    await _save();
                  },
                ),
                SizedBox(height: 10 * scale),

                Text(
                  'TODO(BACKEND): persistir por usuário e respeitar no tracking.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 11 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
                SizedBox(height: 24 * scale),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 10 * scale),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.lightGray, width: 1 * scale),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.baseBlue,
          ),
        ],
      ),
    );
  }
}
