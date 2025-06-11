// lib/features/auth/presentation/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/back_button.dart';
import 'package:flutter_app/shared/widgets/form_fields.dart';
import 'package:flutter_app/shared/widgets/primary_button.dart';

/// -----FORGOT PASSWORD FLOW - STEP 1-----
/// Solicita o e-mail do usuário e envia código de recuperação.
class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgotPassword';
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Envia e-mail de reset e navega para tela de código.
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // BACKEND TODO: chamar AuthService.sendResetEmail(email: _emailController.text)
      await Future.delayed(const Duration(seconds: 1)); // simula delay

      Navigator.pushNamed(
        context,
        AppRoutes.verifyOtp,
        arguments: _emailController.text,
      );
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao enviar código')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375.0;
    double vSpace(double val) => val * scale;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            top: 32.0 * scale,
            left: 24.0 * scale,
            right: 24.0 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voltar para Login
              AppBackButton(),
              SizedBox(height: vSpace(64)),

              // Título
              Text(
                'Esqueceu sua senha?',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 26 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: vSpace(8)),
              Text(
                'Nós enviaremos um email com instruções para trocar sua senha',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.regular,
                  fontSize: 16 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: vSpace(53)),

              // Formulário de e-mail
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    EmailInputField(
                      controller: _emailController,
                      requireExists: true,
                    ),
                    SizedBox(height: vSpace(32)),

                    // Botão Enviar email
                    PrimaryButton(
                      label: 'Enviar email',
                      isLoading: _isLoading,
                      onPressed: _sendResetEmail,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
