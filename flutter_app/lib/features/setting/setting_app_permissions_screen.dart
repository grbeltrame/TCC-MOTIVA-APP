import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';

class SettingsAppPermissionsScreen extends StatelessWidget {
  static const routeName = '/settings/app_permissions';
  const SettingsAppPermissionsScreen({super.key});

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
            const SettingsHeader(title: 'Permissões do aplicativo'),
            Text(
              'As permissões são gerenciadas nas configurações do sistema do seu celular.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 12 * scale),

            _InfoRow(
              title: 'Fotos',
              subtitle: 'Para escolher a foto do perfil',
            ),
            _InfoRow(
              title: 'Câmera',
              subtitle: 'Para capturar foto de perfil (se aplicável)',
            ),

            SizedBox(height: 16 * scale),
            SizedBox(height: 24 * scale),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12 * scale),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.lightGray, width: 1 * scale),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 13 * scale,
              fontWeight: AppFontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}
