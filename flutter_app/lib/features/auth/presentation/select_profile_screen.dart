// lib/features/auth/presentation/select_profile_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
// import 'package:flutter_app/shared/widgets/utils/form_fields.dart'; // Não é mais necessário
import 'package:flutter_app/shared/widgets/utils/primary_button.dart';
import 'package:flutter_app/shared/widgets/utils/radio_option_tile.dart';
// import 'package:flutter_app/shared/widgets/utils/text_action_button.dart'; // Não é mais necessário

// TODO: Mova este Enum para um arquivo compartilhado (ex: lib/core/models/profile_option.dart)
// para que tanto 'signup_screen.dart' quanto 'select_profile_screen.dart' possam usá-lo.
/// Perfis básicos disponíveis para cadastro.
enum ProfileOption { athlete, coach, intern, athleteCoach, athleteIntern }

class SelectProfileScreen extends StatefulWidget {
  // TODO: Adicione esta rota no seu arquivo AppRoutes
  static const String routeName = '/select-profile';
  const SelectProfileScreen({Key? key}) : super(key: key);

  @override
  State<SelectProfileScreen> createState() => _SelectProfileScreenState();
}

class _SelectProfileScreenState extends State<SelectProfileScreen> {
  // Não precisamos mais dos controllers de texto ou do _formKey
  ProfileOption? _selectedProfile;
  bool _agreeTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    // Não há mais controllers para 'disposar'
    super.dispose();
  }

  Future<void> _submitProfile() async {
    // Removemos a validação do _formKey
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
      // --- Início da Lógica de ATUALIZAÇÃO Firebase ---

      // 1. Pegar o usuário ATUAL (logado via Google)
      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // 2. Apenas ATUALIZAR o documento existente no Cloud Firestore
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);

        // Converte o enum para uma string (ex: "ProfileOption.athlete" -> "athlete")
        final String profileString =
            _selectedProfile.toString().split('.').last;

        await userDoc.update({
          'profile': profileString, // Salva APENAS o perfil
        });

        // 3. (Opcional) O 'name' e 'email' já foram salvos pelo GoogleSignInService
      } else {
        // Isso é um fallback, não deve acontecer no fluxo normal
        throw Exception('Usuário não está logado. Tente novamente.');
      }

      // navegação condicional:
      // (mesma lógica de antes)
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
      // Erro genérico, pois não estamos mais validando 'email-em-uso' etc.
      String errorMessage = 'Ocorreu um erro ao salvar seu perfil.';
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
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
                'Só mais um passo!', // <-- Título atualizado
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 26 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: vSpace(8)),
              Text(
                'Complete seu perfil para continuar.', // <-- Subtítulo
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.regular,
                  fontSize: 16 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: vSpace(24)),

              // O Form foi removido, pois não há campos de texto para validar
              Column(
                children: [
                  // Campos de Nome, Email e Senha REMOVIDOS

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
                  // A lógica dos RadioOptionTile é mantida 100% igual
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

                  // Termos (Lógica mantida 100% igual)
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
                    label: 'Concluir Cadastro', // <-- Texto do botão atualizado
                    isLoading: _isSubmitting,
                    onPressed: _submitProfile, // <-- Chama a nova função
                  ),

                  // A seção "Já tem conta?" foi REMOVIDA
                  SizedBox(height: vSpace(32)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
