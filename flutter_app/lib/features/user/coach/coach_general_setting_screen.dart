import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/core/services/users/profile_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class CoachGeneralSettingsScreen extends StatelessWidget {
  static const routeName = '/coach_general_settings';
  const CoachGeneralSettingsScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final isAdmin = ProfileService().hasRole('admin');

    return Scaffold(
      appBar: const TopNavbar(),
      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
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
                  () => Navigator.pushNamed(context, AppRoutes.privacyPolicy),
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
              onTap: () => _signOut(context),
            ),
            if (isAdmin) ...[
              SizedBox(height: 20 * scale),
              _SectionTitle(title: 'Admin', scale: scale),
              SizedBox(height: 8 * scale),
              _NavRow(
                scale: scale,
                title: 'Gerenciar box',
                onTap:
                    () =>
                        Navigator.pushNamed(context, AppRoutes.adminManageBox),
              ),
            ],
            SizedBox(height: 24 * scale),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14 * scale),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.lightGray)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 15 * scale,
            color: isDestructive ? AppColors.darkMagenta : AppColors.darkText,
          ),
        ),
      ),
    );
  }
}
