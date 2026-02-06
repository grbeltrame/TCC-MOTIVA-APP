import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/coach_profile.dart'; // Importante: Onde estão o Model e o Service
import 'package:flutter_app/shared/widgets/sections/coach/coach_info_section.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_recent_cycles_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
// Mantive os imports que você já tinha, caso precise de outros widgets
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';

class CoachProfileScreen extends StatefulWidget {
  static const routeName = '/coach_profile';
  const CoachProfileScreen({Key? key}) : super(key: key);

  @override
  State<CoachProfileScreen> createState() => _CoachProfileScreenState();
}

class _CoachProfileScreenState extends State<CoachProfileScreen> {
  // Variável que guarda o "futuro" (o carregamento dos dados)
  late Future<CoachProfileEditable> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Inicia o carregamento assim que a tela abre
  }

  // Função para buscar os dados (usada no início e para recarregar depois de editar)
  void _loadProfile() {
    setState(() {
      _profileFuture = CoachProfileService.instance.fetchCoachProfileEditable();
    });
  }

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),
      bottomNavigationBar: const BottomNavBar(),

      // Usamos FutureBuilder para gerenciar os estados: Carregando, Erro e Sucesso
      body: FutureBuilder<CoachProfileEditable>(
        future: _profileFuture,
        builder: (context, snapshot) {
          // 1. ESTADO DE CARREGAMENTO
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. ESTADO DE ERRO
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Erro ao carregar perfil'),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _loadProfile,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          // 3. ESTADO DE SUCESSO (Dados carregados)
          // Aqui pegamos os dados reais do banco
          final profileData = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: 16 * scale,
              horizontal: 8 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ CORREÇÃO: Passamos os dados para a seção e a função de recarregar
                CoachInfoSection(
                  profile: profileData,
                  onRefreshRequest: _loadProfile,
                ),

                // Resumo dos ciclos (Mantido)
                CoachRecentCyclesSection(boxId: '1'),
              ],
            ),
          );
        },
      ),
    );
  }
}
