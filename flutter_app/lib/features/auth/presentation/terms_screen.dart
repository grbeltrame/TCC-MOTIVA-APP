// lib/features/auth/presentation/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';

/// Tela de Termos de Serviço
class TermsScreen extends StatelessWidget {
  static const String routeName = '/terms';
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Termos de Serviço',
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
            'Conteúdo dos Termos de Serviço aqui...',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: AppFonts.roboto, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
