// lib/features/auth/presentation/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/core/services/settings/accaount_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/utils/form_fields.dart';
import 'package:flutter_app/shared/widgets/utils/primary_button.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:provider/provider.dart'; // <--- O pacote que instalamos
import 'package:flutter_app/features/auth/presentation/providers/user_provider.dart'; // <--- O arquivo que criamos

/// -----LOGIN SCREEN-----
/// Tela de Login com inputs de email e senha, botões de ação e opções de login social.
class LoginScreen extends StatefulWidget {
  static const String routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
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

  Future<void> _performLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // 1. Login no Auth (Igual antes)
      final UserCredential userCredential = await AuthService.instance
          .signInWithEmailAndPassword(
            email: _emailController.text,
            password: _passwordController.text,
          );

      final User? user = userCredential.user;

      if (user != null) {
        final canContinue = await _ensureAccountActive(user);
        if (!canContinue) return;
        if (!mounted) return;

        // 2. A MÁGICA: Carrega os dados no Provider (Memória Global)
        // Usamos listen: false porque estamos numa função, não desenhando tela
        await Provider.of<UserProvider>(
          context,
          listen: false,
        ).loadUserData(user);

        if (!mounted) return;

        // 3. Verifica o estado que o Provider definiu
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // 4. Navega baseando-se no que o Provider decidiu
        if (userProvider.isCoachView) {
          Navigator.pushReplacementNamed(context, AppRoutes.coachHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.athleteHome);
        }
      }
    } catch (e) {
      String errorMessage = 'Ocorreu um erro ao fazer login.';
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          errorMessage = 'E-mail ou senha inválidos.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'O formato do e-mail é inválido.';
        }
      }
      // Captura erros vindos do Provider (ex: usuário sem perfil)
      else if (e.toString().contains('sem perfil')) {
        errorMessage = 'Perfil de usuário não encontrado.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _ensureAccountActive(User user) async {
    final userData = await AuthService.instance.fetchUserData(user.uid);
    if (!AuthService.instance.isAccountDisabled(userData)) return true;
    if (!mounted) return false;

    final reactivate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reativar conta?'),
          content: const Text(
            'Sua conta está desativada. Deseja reativá-la para continuar usando o aplicativo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reativar'),
            ),
          ],
        );
      },
    );

    if (reactivate == true) {
      await AccountService().reactivateCurrentAccount();
      return true;
    }

    await AuthService.instance.signOut();
    return false;
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
                  // Trocado o onPressed "chumbado" para chamar a função de login
                  onPressed: _performLogin,
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
                SizedBox(height: vSpace(32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
