// lib/features/auth/presentation/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Tela de Cadastro (Signup)
class SignupScreen extends StatefulWidget {
  static const String routeName = '/signup';
  const SignupScreen({Key? key}) : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cadastre-se',
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
          'Signup Screen (minimo scaffold)',
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
