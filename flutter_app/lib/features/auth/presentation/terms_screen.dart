// lib/features/auth/presentation/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Tela de Termos de Serviço
class TermsScreen extends StatelessWidget {
  static const String routeName = '/terms';
  const TermsScreen({Key? key}) : super(key: key);

  static const _sections = <_TermsSection>[
    _TermsSection(
      title: 'Sobre o Motiva',
      body:
          'Ao usar o Motiva, você concorda em utilizar o aplicativo para '
          'registrar treinos, acompanhar a evolução e acessar análises geradas '
          'a partir das informações fornecidas por você ou pelo seu coach.',
    ),
    _TermsSection(
      title: 'Limitações das análises de IA',
      body:
          'As análises de IA têm finalidade informativa e de apoio ao treino. '
          'Elas não substituem orientação médica, avaliação profissional '
          'presencial ou decisões de saúde tomadas com profissionais habilitados.',
    ),
    _TermsSection(
      title: 'Responsabilidades do usuário',
      body:
          'Você é responsável por manter suas credenciais seguras e por '
          'informar dados corretos ao registrar resultados, perfil e '
          'preferências. O uso indevido, tentativa de acesso não autorizado '
          'ou manipulação de dados pode resultar em bloqueio ou exclusão da conta.',
    ),
    _TermsSection(
      title: 'Atualizações',
      body:
          'O Motiva pode atualizar funcionalidades, corrigir erros e ajustar '
          'estes termos conforme o aplicativo evolui. O uso continuado após '
          'mudanças indica concordância com a versão atualizada.',
    ),
    _TermsSection(
      title: 'Conta e dados',
      body:
          'Você pode solicitar download, desativação ou exclusão da sua conta '
          'pelas configurações do aplicativo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Termos de Serviço',
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
              'Termos de Serviço do Motiva',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              'Regras de uso do aplicativo.',
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

class _TermsSection {
  final String title;
  final String body;
  const _TermsSection({required this.title, required this.body});
}
