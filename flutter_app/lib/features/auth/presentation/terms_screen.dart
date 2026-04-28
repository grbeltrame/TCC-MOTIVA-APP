// lib/features/auth/presentation/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Tela de Termos de Serviço
class TermsScreen extends StatelessWidget {
  static const String routeName = '/terms';
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Termos de Serviço',
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
Termos de Serviço do Motiva

Ao usar o Motiva, você concorda em utilizar o aplicativo para registrar treinos, acompanhar evolução e acessar análises geradas a partir das informações fornecidas por você ou pelo seu coach.

As análises de IA têm finalidade informativa e de apoio ao treino. Elas não substituem orientação médica, avaliação profissional presencial ou decisões de saúde tomadas com profissionais habilitados.

Você é responsável por manter suas credenciais seguras e por informar dados corretos ao registrar resultados, perfil e preferências. O uso indevido, tentativa de acesso não autorizado ou manipulação de dados pode resultar em bloqueio ou exclusão da conta.

O Motiva pode atualizar funcionalidades, corrigir erros e ajustar estes termos conforme o aplicativo evolui. O uso continuado após mudanças indica concordância com a versão atualizada.

Você pode solicitar download, desativação ou exclusão da sua conta pelas configurações do aplicativo.
''', style: TextStyle(fontFamily: AppFonts.roboto, fontSize: 16)),
      ),
    );
  }
}
