// lib/features/auth/presentation/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';

/// Tela de Política de Privacidade
class PrivacyPolicyScreen extends StatelessWidget {
  static const String routeName = '/privacy_policy';
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Política de Privacidade',
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.darkBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.offWhite,
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Conteúdo da Política de Privacidade aqui...',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: AppFonts.roboto, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
