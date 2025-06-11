// lib/features/auth/presentation/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/back_button.dart';
import 'package:flutter_app/shared/widgets/form_fields.dart';
import 'package:flutter_app/shared/widgets/primary_button.dart';
import 'package:flutter_app/shared/widgets/app_dialog.dart';

/// -----FORGOT PASSWORD FLOW - STEP 3-----
/// Tela para o usuário inserir e confirmar a nova senha após verificar o código.
class ResetPasswordScreen extends StatefulWidget {
  static const String routeName = '/resetPassword';

  /// E-mail recebido na etapa anterior.
  final String email;
  const ResetPasswordScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Chama API para reset de senha e exibe dialog de sucesso.
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // BACKEND TODO: AuthService.resetPassword(email: widget.email, newPassword: _passwordController.text)
      await Future.delayed(const Duration(seconds: 1)); // simula delay

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AppDialog(
              icon: Icons.check_sharp,
              title: 'Sua senha foi alterada',
              message: 'Você será redirecionado para a página de login.',
              primaryAction: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.darkBlue,
                ),
                child: const Text('OK'),
              ),
            ),
      );
      // Volta para a tela de login
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Falha ao redefinir senha')));
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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: vSpace(32)),

              // Voltar para Login
              AppBackButton(),
              SizedBox(height: vSpace(48)),

              // Título e subtítulo
              Text(
                'Nova senha',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 26 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: vSpace(8)),
              Text(
                'Redefina sua senha para:',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.regular,
                  fontSize: 16 * scale,
                  color: AppColors.darkText,
                ),
              ),
              Text(
                widget.email,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 16 * scale,
                  color: AppColors.darkBlue,
                ),
              ),
              SizedBox(height: vSpace(24)),

              // Formulário de senhas
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PasswordInputField(
                      controller: _passwordController,
                      requireRules: true,
                      hint: 'Nova senha',
                    ),
                    SizedBox(height: vSpace(16)),
                    PasswordInputField(
                      controller: _confirmPasswordController,
                      confirmController: _passwordController,
                      hint: 'Confirmar senha',
                    ),
                    SizedBox(height: vSpace(24)),

                    // Botão Trocar senha
                    PrimaryButton(
                      label: 'Trocar senha',
                      isLoading: _isLoading,
                      onPressed: _resetPassword,
                    ),
                    SizedBox(height: vSpace(32)),
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
