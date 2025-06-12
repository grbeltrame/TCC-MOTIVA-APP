// lib/features/auth/presentation/signup_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/form_fields.dart';
import 'package:flutter_app/shared/widgets/primary_button.dart';
import 'package:flutter_app/shared/widgets/radio_option_tile.dart';
import 'package:flutter_app/shared/widgets/text_action_button.dart';

/// Perfis básicos disponíveis para cadastro.
enum ProfileOption { athlete, coach, intern, athleteCoach, athleteIntern }

class SignupScreen extends StatefulWidget {
  static const String routeName = '/signup';
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  ProfileOption? _selectedProfile;
  bool _agreeTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProfile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione seu perfil')));
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve concordar com os termos')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // BACKEND TODO: implementar AuthService.signUp(
      //   name: _nameController.text,
      //   email: _emailController.text,
      //   password: _passwordController.text,
      //   profile: _selectedProfile,
      // );
      await Future.delayed(const Duration(seconds: 1)); // simula delay

      // navegação condicional:
      // se atletaeCoach/intern -> coach home
      // se coach/intern -> coach home
      // else atleta
      final isCoach =
          _selectedProfile == ProfileOption.coach ||
          _selectedProfile == ProfileOption.athleteCoach ||
          _selectedProfile == ProfileOption.athleteIntern ||
          _selectedProfile == ProfileOption.intern;
      if (isCoach) {
        Navigator.pushReplacementNamed(context, AppRoutes.coachHome);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.athleteHome);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isSubmitting = false);
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
              Text(
                'Vamos criar sua conta?',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 26 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: vSpace(24)),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Nome
                    NameInputField(controller: _nameController),
                    SizedBox(height: vSpace(16)),

                    // Email
                    EmailInputField(
                      controller: _emailController,
                      requireExists: false,
                    ),
                    SizedBox(height: vSpace(16)),

                    // Senha
                    PasswordInputField(
                      controller: _passwordController,
                      requireRules: true,
                      hint: '*********',
                    ),
                    SizedBox(height: vSpace(16)),

                    // Perfil
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Como você se define?',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 18 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    SizedBox(height: vSpace(4)),
                    RadioOptionTile<ProfileOption>(
                      value: ProfileOption.athlete,
                      groupValue: _selectedProfile,
                      label: 'Sou apenas praticante de Crossfit',
                      onChanged: (v) => setState(() => _selectedProfile = v),
                    ),
                    RadioOptionTile<ProfileOption>(
                      value: ProfileOption.coach,
                      groupValue: _selectedProfile,
                      label: 'Sou apenas coach de Crossfit',
                      onChanged: (v) => setState(() => _selectedProfile = v),
                    ),
                    RadioOptionTile<ProfileOption>(
                      value: ProfileOption.intern,
                      groupValue: _selectedProfile,
                      label: 'Sou apenas estagiário de Crossfit',
                      onChanged: (v) => setState(() => _selectedProfile = v),
                    ),
                    RadioOptionTile<ProfileOption>(
                      value: ProfileOption.athleteCoach,
                      groupValue: _selectedProfile,
                      label: 'Sou praticante e professor de Crossfit',
                      onChanged: (v) => setState(() => _selectedProfile = v),
                    ),
                    RadioOptionTile<ProfileOption>(
                      value: ProfileOption.athleteIntern,
                      groupValue: _selectedProfile,
                      label: 'Sou praticante e estagiário de Crossfit',
                      onChanged: (v) => setState(() => _selectedProfile = v),
                    ),
                    SizedBox(height: vSpace(20)),

                    // Termos
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeTerms,
                          onChanged: (v) => setState(() => _agreeTerms = v!),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'Li e concordo com os ',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontWeight: AppFontWeight.light,
                                fontSize: 12 * scale,
                                color: AppColors.darkText,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Termos de Serviço',
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: 12 * scale,
                                    color: AppColors.darkBlue,
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
                                  text: 'Política do Aplicativo',
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: 12 * scale,
                                    color: AppColors.darkBlue,
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
                        ),
                      ],
                    ),
                    SizedBox(height: vSpace(24)),

                    // Botão Cadastrar
                    PrimaryButton(
                      label: 'Cadastrar',
                      isLoading: _isSubmitting,
                      onPressed: _submitForm,
                    ),

                    SizedBox(height: vSpace(16)),

                    // Já tem conta?
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Já tem uma conta? ',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.regular,
                            fontSize: 14 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                        TextActionButton(
                          text: 'Entre aqui',
                          onPressed:
                              () => Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.login,
                              ),
                        ),
                      ],
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
