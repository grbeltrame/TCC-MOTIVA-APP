// lib/features/auth/presentation/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';

/// -----FORGOT PASSWORD FLOW - STEP 1-----
/// Tela para o usuário informar o e-mail e receber um código de reset.
class ForgotPasswordScreen extends StatefulWidget {
  static const String routeName = '/forgotPassword';
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>(); // FRONT-END: para validar e-mail
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage; // Mensagem de erro do backend

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// FRONT-END: envia e-mail ao backend e navega para VerifyOtpScreen
  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // BACKEND TODO: inserir chamada ao serviço de envio de código
      // await AuthService.sendResetEmail(email: _emailController.text);

      // Simulação de delay de rede
      await Future.delayed(const Duration(seconds: 1));
      // FRONT-END: navegar para a próxima etapa (verify OTP)
      Navigator.pushNamed(
        context,
        AppRoutes.verifyOtp,
        arguments: _emailController.text,
      );
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao enviar código');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375.0;
    double vSpace(double value) => value * scale;

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
              // ------------------Voltar para Login---------------------
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.navigate_before,
                  color: AppColors.baseBlue,
                  size: 20 * scale,
                ),
                label: Text(
                  'Voltar',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 16 * scale,
                    color: AppColors.baseBlue,
                  ),
                ),
              ),
              SizedBox(height: vSpace(64)),

              // ------------------------Título--------------------------
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

              // --------------------------Formulário de e-mail------------------------
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        hintText: 'Seu email cadastrado',
                        filled: true,
                        fillColor: AppColors.offWhite,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4 * scale),
                          borderSide: BorderSide(color: AppColors.mediumGray),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: vSpace(12),
                          horizontal: vSpace(12),
                        ),
                        errorText:
                            _errorMessage, // erro do backend-------------------------------------
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe seu email';
                        }
                        final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!regex.hasMatch(value)) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: vSpace(32)),

                    // ---------------------------Botão Enviar email-------------------------------
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
                          onPressed: _sendResetEmail,
                          child: Text(
                            'Enviar email',
                            style: TextStyle(
                              fontFamily: AppFonts.montserrat,
                              fontWeight: AppFontWeight.bold,
                              fontSize: 18 * scale,
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
