// lib/features/auth/presentation/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Tela de Recuperação de Senha (Forgot Password)
class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgot_password';
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Esqueci minha senha',
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.darkBlue,
      ),
      backgroundColor: AppColors.offWhite,
      body: Center(
        child: Text(
          'Forgot Password Screen (minimo scaffold)',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 16,
            color: AppColors.darkText,
          ),
        ),
      ),
    );
  }
}
