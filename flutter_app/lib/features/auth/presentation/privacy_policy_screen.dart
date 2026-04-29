// lib/features/auth/presentation/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Tela de Política de Privacidade
class PrivacyPolicyScreen extends StatelessWidget {
  static const String routeName = '/privacy_policy';
  const PrivacyPolicyScreen({super.key});

  static const _sections = <_PolicySection>[
    _PolicySection(
      title: 'Quais dados coletamos',
      body:
          'Para criar sua conta, identificar seu perfil e operar o app, coletamos: '
          'dados cadastrais, treinos, resultados, PRs, preferências, notificações '
          'e informações usadas para gerar as análises do aplicativo.',
    ),
    _PolicySection(
      title: 'Personalização por IA',
      body:
          'Quando a personalização por IA estiver ativa, seus dados de treino e '
          'evolução podem ser usados para gerar insights semanais, análises de '
          'evolução e informações pré-treino. Você pode desativar novas análises '
          'personalizadas nas configurações de privacidade do app.',
    ),
    _PolicySection(
      title: 'Diagnóstico e estabilidade',
      body:
          'Dados técnicos de diagnóstico podem ser usados para melhorar a '
          'estabilidade do app e corrigir problemas, sempre conforme sua '
          'preferência nas configurações.',
    ),
    _PolicySection(
      title: 'Suporte e feedback',
      body:
          'Suporte, feedback e relatos de erro enviados pelo app podem ser '
          'encaminhados ao email de suporte do projeto e armazenados para '
          'acompanhamento.',
    ),
    _PolicySection(
      title: 'Seus direitos',
      body:
          'Você pode solicitar o download dos seus dados, desativar temporariamente '
          'sua conta ou solicitar a exclusão permanente diretamente pelas '
          'configurações do aplicativo.',
    ),
    _PolicySection(
      title: 'Compartilhamento com terceiros',
      body:
          'Não vendemos seus dados pessoais. Utilizamos provedores como o Firebase '
          'para autenticação, armazenamento, notificações e funções em nuvem '
          'apenas para operar o aplicativo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Política de Privacidade',
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.baseBlue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.offWhite,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Política de Privacidade do Motiva',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              'Como tratamos seus dados ao usar o aplicativo.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 16 * scale),
            for (final s in _sections) ...[
              Text(
                s.title,
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 14 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                s.body,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 14 * scale,
                  height: 1.45,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 16 * scale),
            ],
          ],
        ),
      ),
    );
  }
}

class _PolicySection {
  final String title;
  final String body;
  const _PolicySection({required this.title, required this.body});
}
