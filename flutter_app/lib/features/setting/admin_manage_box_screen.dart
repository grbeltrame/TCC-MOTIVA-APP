import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';

class AdminManageBoxScreen extends StatelessWidget {
  static const routeName = '/admin/manage_box';
  const AdminManageBoxScreen({super.key});

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
            const SettingsHeader(title: 'Gerenciar box (Admin)'),
            Text(
              'Área reservada para administradores.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 16 * scale),

            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              child: Text(
                'TODO(BACKEND): listar boxes, criar/editar, permissões e equipe.',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 12 * scale,
                  color: AppColors.darkText,
                ),
              ),
            ),
            SizedBox(height: 24 * scale),
          ],
        ),
      ),
    );
  }
}
