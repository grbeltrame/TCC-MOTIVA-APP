// lib/features/auth/presentation/verify_otp_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/back_button.dart';
import 'package:flutter_app/shared/widgets/form_fields.dart';
import 'package:flutter_app/shared/widgets/primary_button.dart';

/// -----FORGOT PASSWORD FLOW - STEP 2-----
/// Tela para o usuário inserir o código OTP recebido por e-mail.
class VerifyOtpScreen extends StatefulWidget {
  static const String routeName = '/verifyOtp';

  /// E-mail recebido na etapa anterior via argumentos
  final String email;
  const VerifyOtpScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// Valida e envia o código para o backend
  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // BACKEND TODO: AuthService.verifyOtp(email: widget.email, code: _codeController.text)
      await Future.delayed(const Duration(seconds: 1)); // simula delay
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.resetPassword,
        arguments: widget.email,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Código inválido')));
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
          padding: EdgeInsets.symmetric(
            horizontal: 24.0 * scale,
            vertical: 24.0 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voltar para a tela anterior
              AppBackButton(),
              SizedBox(height: vSpace(32)),

              // Cabeçalho
              Text(
                'Confirme o código',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 26 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: vSpace(8)),
              Text(
                'Insira o código que enviamos para:',
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

              // Formulário de código OTP
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CodeInputField(controller: _codeController),
                    SizedBox(height: vSpace(24)),

                    // Botão Verificar código
                    PrimaryButton(
                      label: 'Verificar código',
                      isLoading: _isLoading,
                      onPressed: _verifyCode,
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
