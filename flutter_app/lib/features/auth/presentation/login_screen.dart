// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/form_fields.dart';
import 'package:flutter_app/shared/widgets/primary_button.dart';
import 'package:flutter_app/shared/widgets/text_action_button.dart';

/// -----LOGIN SCREEN-----
/// Tela de Login com inputs de email e senha, botões de ação e opções de login social.
class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Chama a API de login e navega conforme perfil.
  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // BACKEND TODO: implementar AuthService.login(email, password)
      // final result = await AuthService.login(
      //   email: _emailController.text,
      //   password: _passwordController.text,
      // );
      // if (!result.success) throw Exception(result.message);
      // if (result.role == UserRole.athlete) Navigator.pushReplacementNamed(context, AppRoutes.athleteHome);
      // else Navigator.pushReplacementNamed(context, AppRoutes.coachHome);

      // Simulação de delay para demonstração
      await Future.delayed(const Duration(seconds: 1));
      throw Exception('Usuário ou senha inválidos');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: vSpace(80)),
                Text(
                  'MOTIVA',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 30 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: vSpace(4)),
                Text(
                  'Treine. Registre. Evolua',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 20 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                SizedBox(height: vSpace(32)),

                // Email input
                EmailInputField(
                  controller: _emailController,
                  requireExists: true,
                ),
                SizedBox(height: vSpace(16)),

                // Password input
                PasswordInputField(
                  controller: _passwordController,
                  requireAssociation: true,
                ),
                SizedBox(height: vSpace(8)),

                // Forgot password
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextActionButton(
                    text: 'Esqueci minha senha',
                    icon: Icons.help_outline,
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.forgotPassword,
                        ),
                  ),
                ),
                SizedBox(height: vSpace(56)),

                // ---------------LOGIN BUTTON----------------
                PrimaryButton(
                  label: 'Entrar',
                  isLoading: _isLoading,
                  onPressed:
                      () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.athleteHome,
                      ), //leva direto pra pagina de atleta pra teste
                  // onPressed: () { ///DESCOMENTAR QUANDO TIVER VALIDAÇÃO DO BACKEND
                  //   // if (_formKey.currentState!.validate()) {
                  //   //   _performLogin();
                  //   // }
                  // },
                ),
                SizedBox(height: vSpace(8)),

                // LGPD Text – substitua o trecho anterior pelo abaixo:
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.light,
                      fontSize: 8 * scale,
                      color: AppColors.darkText,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Ao continuar, você concorda com nossos ',
                      ),
                      TextSpan(
                        text: 'Termos de Serviço',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 8 * scale,
                          color: AppColors.darkText,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap =
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.terms,
                                  ),
                      ),
                      const TextSpan(text: ' e '),
                      TextSpan(
                        text: 'Política de Privacidade',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 8 * scale,
                          color: AppColors.darkText,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer:
                            TapGestureRecognizer()
                              ..onTap =
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.privacyPolicy,
                                  ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: vSpace(16)),

                // Sign up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem uma conta? ',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.regular,
                        fontSize: 14 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                    TextActionButton(
                      text: 'Cadastre-se',
                      onPressed:
                          () => Navigator.pushNamed(context, AppRoutes.signup),
                    ),
                  ],
                ),
                SizedBox(height: vSpace(40)),

                // Social login
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.mediumGray, thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0 * scale),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.regular,
                          fontSize: 12 * scale,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.mediumGray, thickness: 1),
                    ),
                  ],
                ),
                SizedBox(height: vSpace(16)),
                SizedBox(
                  width: double.infinity,
                  height: vSpace(48),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.mediumGray),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      width: 24 * scale,
                      height: 24 * scale,
                    ),
                    label: Text(
                      'Entrar com Google',
                      style: TextStyle(
                        fontFamily: AppFonts.montserrat,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 16 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                    onPressed: () {
                      // BACKEND TODO: implementar login via Google
                    },
                  ),
                ),
                SizedBox(height: vSpace(32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
