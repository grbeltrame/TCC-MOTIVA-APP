// lib/features/user/athlete/athlete_general_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/settings/athlete_general_setting_service.dart';
import 'package:flutter_app/core/services/users/profile_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_training_bottom_sheet.dart';

class AthleteGeneralSettingsScreen extends StatefulWidget {
  static const routeName = '/athlete_general_settings';
  const AthleteGeneralSettingsScreen({super.key});

  @override
  State<AthleteGeneralSettingsScreen> createState() =>
      _AthleteGeneralSettingsScreenState();
}

class _AthleteGeneralSettingsScreenState
    extends State<AthleteGeneralSettingsScreen> {
  final ProfileService _profile = ProfileService();
  final AthleteSettingsService _service = AthleteSettingsService();

  late Future<AthleteGeneralSettings> _future;

  // Estado (carregado do service)
  AthleteGeneralSettings _settings = AthleteGeneralSettings.defaults();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AthleteGeneralSettings> _load() async {
    final s = await _service.fetchGeneralSettings();
    _settings = s;
    return s;
  }

  Future<void> _save() async {
    // TODO(BACKEND): salvar por usuário/role
    await _service.updateGeneralSettings(_settings);
  }

  void _openRegisterTraining(BuildContext context) {
    showRegisterTrainingBottomSheet(context);
  }

  bool get _isAdmin => _profile.hasRole('admin');

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterTraining(context)),
      bottomNavigationBar: const BottomNavBar(),
      body: FutureBuilder<AthleteGeneralSettings>(
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
                const AppBackButton(),
                SizedBox(height: 12 * scale),

                Text(
                  'Configurações',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 16 * scale),

                // =========================
                // NOTIFICAÇÕES (GERAL)
                // =========================
                _SectionTitle(title: 'Notificações', scale: scale),
                SizedBox(height: 8 * scale),

                _SwitchRow(
                  scale: scale,
                  title: 'Resumo Semanal',
                  value: _settings.weeklySummary,
                  onChanged: (v) async {
                    setState(() => _settings.weeklySummary = v);
                    await _save();
                  },
                ),
                _SwitchRow(
                  scale: scale,
                  title: 'Insights semanais e alertas',
                  value: _settings.weeklyInsightsAlerts,
                  onChanged: (v) async {
                    setState(() => _settings.weeklyInsightsAlerts = v);
                    await _save();
                  },
                ),

                SizedBox(height: 8 * scale),
                Text(
                  'Preferência de horário para receber notificações',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
                SizedBox(height: 8 * scale),

                Wrap(
                  spacing: 8 * scale,
                  runSpacing: 8 * scale,
                  children: [
                    _PreferenceChip(
                      label: 'Manhã',
                      selected: _settings.prefMorning,
                      onTap: () async {
                        setState(
                          () => _settings.prefMorning = !_settings.prefMorning,
                        );
                        await _save();
                      },
                    ),
                    _PreferenceChip(
                      label: 'Tarde',
                      selected: _settings.prefAfternoon,
                      onTap: () async {
                        setState(
                          () =>
                              _settings.prefAfternoon =
                                  !_settings.prefAfternoon,
                        );
                        await _save();
                      },
                    ),
                    _PreferenceChip(
                      label: 'Noite',
                      selected: _settings.prefNight,
                      onTap: () async {
                        setState(
                          () => _settings.prefNight = !_settings.prefNight,
                        );
                        await _save();
                      },
                    ),
                  ],
                ),

                SizedBox(height: 20 * scale),

                // =========================
                // PERSONALIZAÇÃO
                // =========================
                _SectionTitle(title: 'Personalização', scale: scale),
                SizedBox(height: 8 * scale),

                _InlineRadioRow(
                  scale: scale,
                  title: 'Unidade de medida',
                  options: const ['kg', 'lb'],
                  labels: const ['kilos', 'libras'],
                  value: _settings.unit,
                  onChanged: (v) async {
                    setState(() => _settings.unit = v);
                    await _save();
                  },
                ),
                SizedBox(height: 8 * scale),

                _DropdownRow(
                  scale: scale,
                  title: 'Idioma do aplicativo',
                  value: _settings.language,
                  items: const ['Português - BR'],
                  onChanged: (v) async {
                    setState(() => _settings.language = v);
                    await _save();
                  },
                ),

                SizedBox(height: 20 * scale),

                // =========================
                // PRIVACIDADE E SEGURANÇA
                // =========================
                _SectionTitle(title: 'Privacidade e Segurança', scale: scale),
                SizedBox(height: 8 * scale),

                _NavRow(
                  scale: scale,
                  title: 'Gerenciar compartilhamento de dados',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsDataSharing,
                      ),
                ),
                _NavRow(
                  scale: scale,
                  title: 'Solicitar download de dados',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsDataDownload,
                      ),
                ),
                _NavRow(
                  scale: scale,
                  title: 'Permissões do aplicativo',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsAppPermissions,
                      ),
                ),
                _NavRow(
                  scale: scale,
                  title: 'Termos de Serviço',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.terms),
                ),
                _NavRow(
                  scale: scale,
                  title: 'Política de Privacidade',
                  onTap:
                      () =>
                          Navigator.pushNamed(context, AppRoutes.privacyPolicy),
                ),

                SizedBox(height: 20 * scale),

                // =========================
                // CONTA
                // =========================
                _SectionTitle(title: 'Conta', scale: scale),
                SizedBox(height: 8 * scale),

                _NavRow(
                  scale: scale,
                  title: 'Redefinir senha',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsResetPassword,
                      ),
                ),
                _NavRow(
                  scale: scale,
                  title: 'Desativar conta temporariamente',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsDeactivateAccount,
                      ),
                ),
                _NavRow(
                  scale: scale,
                  title: 'Solicitar exclusão permanente da conta',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsDeleteAccount,
                      ),
                ),
                _NavRow(
                  scale: scale,
                  title: 'Sair',
                  isDestructive: true,
                  onTap: () {
                    // TODO(BACKEND/AUTH): logout real
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    );
                  },
                ),

                if (_isAdmin) ...[
                  SizedBox(height: 20 * scale),
                  _SectionTitle(title: 'Admin', scale: scale),
                  SizedBox(height: 8 * scale),
                  _NavRow(
                    scale: scale,
                    title: 'Gerenciar box',
                    onTap:
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.adminManageBox,
                        ),
                  ),
                ],

                SizedBox(height: 20 * scale),

                // =========================
                // SUPORTE E FEEDBACK
                // =========================
                _SectionTitle(title: 'Suporte e Feedback', scale: scale),
                SizedBox(height: 8 * scale),

                _NavRow(
                  scale: scale,
                  title: 'Fale com Suporte',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsSupport,
                      ),
                ),
                _NavRow(
                  scale: scale,
                  title: 'Enviar feedback sobre o app',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsFeedback,
                      ),
                ),
                _NavRow(
                  scale: scale,
                  title: 'Reportar erro',
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.settingsBugReport,
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

// =========================================================
// Model + Service (mock-friendly)
// Se você já tiver isso no projeto, pode remover daqui e manter só os imports.
// =========================================================

class AthleteGeneralSettings {
  bool weeklySummary;
  bool weeklyInsightsAlerts;

  bool prefMorning;
  bool prefAfternoon;
  bool prefNight;

  String unit; // 'kg' | 'lb'
  String language; // ex: 'Português - BR'

  AthleteGeneralSettings({
    required this.weeklySummary,
    required this.weeklyInsightsAlerts,
    required this.prefMorning,
    required this.prefAfternoon,
    required this.prefNight,
    required this.unit,
    required this.language,
  });

  factory AthleteGeneralSettings.defaults() => AthleteGeneralSettings(
    weeklySummary: true,
    weeklyInsightsAlerts: true,
    prefMorning: true,
    prefAfternoon: false,
    prefNight: true,
    unit: 'kg',
    language: 'Português - BR',
  );
}

/// ✅ Service separado do coach (para depois plugar backend sem misturar role)
class AthleteSettingsService {
  // TODO(BACKEND): persistir por userId/role
  static AthleteGeneralSettings _cache = AthleteGeneralSettings.defaults();

  Future<AthleteGeneralSettings> fetchGeneralSettings() async {
    // simula latência
    await Future.delayed(const Duration(milliseconds: 150));
    return _cache;
  }

  Future<void> updateGeneralSettings(AthleteGeneralSettings s) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _cache = s;
  }
}

// =========================================================
// Widgets auxiliares (iguais ao Coach)
// =========================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final double scale;

  const _SectionTitle({required this.title, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: AppFonts.montserrat,
        fontWeight: AppFontWeight.bold,
        fontSize: 16 * scale,
        color: AppColors.darkText,
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final double scale;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.scale,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2 * scale),
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

class _PreferenceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.baseBlue.withOpacity(0.12) : Colors.white,
          border: Border.all(
            color: selected ? AppColors.baseBlue : AppColors.mediumGray,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.bold,
            fontSize: 12,
            color: selected ? AppColors.baseBlue : AppColors.darkText,
          ),
        ),
      ),
    );
  }
}

class _InlineRadioRow extends StatelessWidget {
  final double scale;
  final String title;
  final List<String> options;
  final List<String> labels;
  final String value;
  final ValueChanged<String> onChanged;

  const _InlineRadioRow({
    required this.scale,
    required this.title,
    required this.options,
    required this.labels,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: List.generate(options.length, (i) {
              final opt = options[i];
              final lbl = labels[i];
              return Row(
                children: [
                  Radio<String>(
                    value: opt,
                    groupValue: value,
                    onChanged: (v) => onChanged(v ?? value),
                    activeColor: AppColors.baseBlue,
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    lbl,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 12 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DropdownRow extends StatelessWidget {
  final double scale;
  final String title;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _DropdownRow({
    required this.scale,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.mediumGray,
              size: 20 * scale,
            ),
            items:
                items
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(
                          e,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 13 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    )
                    .toList(),
            onChanged: (v) {
              if (v == null) return;
              onChanged(v);
            },
          ),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final double scale;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _NavRow({
    required this.scale,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade700 : AppColors.darkText;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12 * scale),
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
                  color: color,
                  fontWeight:
                      isDestructive
                          ? AppFontWeight.bold
                          : AppFontWeight.regular,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.mediumGray),
          ],
        ),
      ),
    );
  }
}
