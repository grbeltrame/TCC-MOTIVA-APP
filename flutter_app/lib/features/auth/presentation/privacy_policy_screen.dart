// lib/features/auth/presentation/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Tela de Política de Privacidade
class PrivacyPolicyScreen extends StatelessWidget {
  static const String routeName = '/privacy_policy';
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Política de Privacidade',
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.darkBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: AppColors.offWhite,
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text('''
Política de Privacidade do Motiva

Coletamos dados necessários para criar sua conta, identificar seu perfil, registrar treinos, resultados, PRs, preferências, notificações e informações usadas para gerar análises do aplicativo.

Quando a personalização por IA estiver ativa, seus dados de treino e evolução poderão ser usados para gerar insights semanais, análises de evolução e informações pré-treino. Você pode desativar novas análises personalizadas nas configurações de privacidade.

Dados técnicos de diagnóstico podem ser usados para melhorar estabilidade e corrigir problemas, conforme sua preferência nas configurações.

Suporte, feedback e relatos de erro enviados pelo app podem ser encaminhados ao email de suporte do projeto e armazenados para acompanhamento.

Você pode solicitar o download dos seus dados, desativar temporariamente sua conta ou solicitar exclusão permanente pelas configurações do aplicativo.

Não vendemos seus dados pessoais. O uso de provedores como Firebase, serviços de autenticação, armazenamento, notificações e funções em nuvem ocorre para operar o aplicativo.
''', style: TextStyle(fontFamily: AppFonts.roboto, fontSize: 16)),
      ),
    );
  }
}
