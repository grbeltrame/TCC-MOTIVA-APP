// lib/features/auth/presentation/verify_otp_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';

/// -----FORGOT PASSWORD FLOW - STEP 2-----
/// Tela para o usuário inserir o código OTP recebido por e-mail.
class VerifyOtpScreen extends StatefulWidget {
  static const String routeName = '/verifyOtp';

  /// Recebe o e-mail da etapa anterior via argumentos
  final String email;
  const VerifyOtpScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// BACKEND TODO: validar OTP com AuthService.verifyOtp(email, code)
  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // TODO: inserir chamada real ao backend
      await Future.delayed(const Duration(seconds: 1)); // simula delay
      if (!mounted) return;
      // -----------------------Navegar para redefinir senha----------------------
      Navigator.pushNamed(
        context,
        AppRoutes.resetPassword,
        arguments: widget.email,
      );
    } catch (e) {
      setState(() => _errorMessage = 'Código inválido');
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
              // --------------------------Botão de voltar----------------------
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back,
                  color: AppColors.darkBlue,
                  size: 20 * scale,
                ),
                label: Text(
                  'Voltar',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 14 * scale,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),

              SizedBox(height: vSpace(32)), // espaço após voltar
              // -------------------------Cabeçalho-----------------------
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

              // --------------------------Formulário de código-------------------------
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Código',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: '000000',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8 * scale),
                          borderSide: BorderSide(color: AppColors.mediumGray),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: vSpace(12),
                          horizontal: vSpace(12),
                        ),
                        errorText: _errorMessage,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe o código';
                        }
                        if (value.length != 6) {
                          return 'Código deve ter 6 dígitos';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: vSpace(24)),

                    // -----------------------------Botão Verificar--------------------------
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: AppColors.darkBlue,
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: vSpace(48),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8 * scale),
                            ),
                          ),
                          onPressed: _verifyCode,
                          child: Text(
                            'Verificar código',
                            style: TextStyle(
                              fontFamily: AppFonts.montserrat,
                              fontWeight: AppFontWeight.bold,
                              fontSize: 16 * scale,
                              color: Colors.white,
                            ),
                          ),
                        ),
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
