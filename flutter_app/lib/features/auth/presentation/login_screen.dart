// lib/features/auth/presentation/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/utils/form_fields.dart';
import 'package:flutter_app/shared/widgets/utils/primary_button.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
// TODO(google): Importar o seu GoogleSignInService quando for implementar
import 'google_auth.dart'; // Mantido como você importou

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
  // final _emailController = TextEditingController();
  // final _passwordController = TextEditingController();
  final _emailController = TextEditingController(text: "teste@gmail.com");
  final _passwordController = TextEditingController(text: "Abcd1234");
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
      // --- Início da Lógica de Login Firebase ---

      // 1. Tentar fazer login no Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      final User? user = userCredential.user;

      if (user != null) {
        // 2. Login bem-sucedido, buscar perfil no Firestore
        final DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final Map<String, dynamic> data =
              userDoc.data() as Map<String, dynamic>;
          final String? profile = data['profile']; // 'athlete', 'coach', etc.

          if (profile != null) {
            // 3. Navegação condicional (mesma lógica do signup_screen)
            final isCoach =
                profile == 'coach' ||
                profile == 'athleteCoach' ||
                profile == 'athleteIntern' ||
                profile == 'intern';

            if (isCoach) {
              Navigator.pushReplacementNamed(context, AppRoutes.coachHome);
            } else {
              Navigator.pushReplacementNamed(context, AppRoutes.athleteHome);
            }
          } else {
            // Usuário logado, mas sem perfil no Firestore.
            throw Exception('Erro ao carregar o perfil do usuário.');
          }
        } else {
          // Usuário logado no Auth, mas sem documento no Firestore.
          // Isso pode acontecer se o cadastro falhou na metade.
          throw Exception('Usuário não encontrado no banco de dados.');
        }
      }
      // --- Fim da Lógica de Login Firebase ---
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
      } else if (e is Exception) {
        // Captura os erros que nós mesmos lançamos (ex: 'Perfil não encontrado')
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- INÍCIO DA ADIÇÃO DE CÓDIGO ---

  /// Chama a API de login do Google e navega conforme perfil.
  Future<void> _performGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      // 1. Chamar o seu serviço de login do Google
      // (Assumindo que sua classe se chama GoogleSignInService)
      final UserCredential? userCredential =
          await GoogleSignInService.signInWithGoogle();

      if (userCredential == null || userCredential.user == null) {
        throw Exception('Login com Google cancelado ou falhou.');
      }
      final User user = userCredential.user!;

      // 2. Buscar o documento do usuário no Firestore
      // (O GoogleSignInService já criou um documento básico se for novo)
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      // 3. Lógica de Navegação
      if (userDoc.exists) {
        final Map<String, dynamic> data =
            userDoc.data() as Map<String, dynamic>;

        // Verifica se o campo 'profile' existe no documento
        final String? profile =
            data.containsKey('profile') ? data['profile'] as String? : null;

        if (profile != null && profile.isNotEmpty) {
          // CASO 1: Perfil existe. É um usuário antigo.
          // Navega para a home correta.
          final isCoach =
              profile == 'coach' ||
              profile == 'athleteCoach' ||
              profile == 'athleteIntern' ||
              profile == 'intern';

          if (isCoach) {
            Navigator.pushReplacementNamed(context, AppRoutes.coachHome);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.athleteHome);
          }
        } else {
          // CASO 2: Perfil NÃO existe (null ou ""). É um usuário novo do Google.
          // Redireciona para a tela de seleção de perfil que criamos.
          // TODO: Verifique se a rota '/select-profile' está em AppRoutes.dart
          Navigator.pushReplacementNamed(context, AppRoutes.selectProfile);
        }
      } else {
        // Fallback: O GoogleSignInService deveria ter criado o doc, mas se falhou.
        throw Exception('Erro ao obter os dados do usuário.');
      }
    } catch (e) {
      String errorMessage = 'Ocorreu um erro ao logar com o Google.';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- FIM DA ADIÇÃO DE CÓDIGO ---

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
                    // --- ALTERAÇÃO AQUI ---
                    // Conecta o botão à nova função de login do Google
                    // e desabilita durante o loading
                    onPressed: _isLoading ? null : _performGoogleLogin,
                    // --- FIM DA ALTERAÇÃO ---
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
