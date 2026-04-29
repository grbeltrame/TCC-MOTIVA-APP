import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/core/services/settings/general_settings_service.dart';
import 'package:flutter_app/core/services/users/profile_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_training_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

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
  final UserSettingsService _settingsService = UserSettingsService.instance;

  late Future<AthleteGeneralSettings> _future;
  AthleteGeneralSettings _settings = AthleteGeneralSettings.defaults();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AthleteGeneralSettings> _load() async {
    final settings = await _settingsService.fetchAthleteSettings();
    _settings = settings;
    return settings;
  }

  Future<void> _save(AthleteGeneralSettings next) async {
    setState(() => _settings = next);
    await _settingsService.updateAthleteSettings(next);
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
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

                _SectionTitle(title: 'Notificações', scale: scale),
                SizedBox(height: 8 * scale),
                _SwitchRow(
                  scale: scale,
                  title: 'Resumo semanal da IA',
                  value: _settings.weeklyInsights,
                  onChanged:
                      (v) => _save(_settings.copyWith(weeklyInsights: v)),
                ),
                _SwitchRow(
                  scale: scale,
                  title: 'Análise de evolução',
                  value: _settings.evolutionInsights,
                  onChanged:
                      (v) => _save(_settings.copyWith(evolutionInsights: v)),
                ),
                _SwitchRow(
                  scale: scale,
                  title: 'Insights de treino publicado',
                  value: _settings.preWorkoutInsights,
                  onChanged:
                      (v) => _save(_settings.copyWith(preWorkoutInsights: v)),
                ),
                _SwitchRow(
                  scale: scale,
                  title: 'Lembretes de registro de treino',
                  value: _settings.trainingReminders,
                  onChanged:
                      (v) => _save(_settings.copyWith(trainingReminders: v)),
                ),

                SizedBox(height: 20 * scale),
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
                  isDestructive: true,
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
                  onTap: _signOut,
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
            activeThumbColor: AppColors.baseBlue,
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
    final color = isDestructive ? AppColors.baseMagenta : AppColors.darkText;

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
