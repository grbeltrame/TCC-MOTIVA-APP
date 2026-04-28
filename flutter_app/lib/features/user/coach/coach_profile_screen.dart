import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/coach_profile.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_info_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

// ✅ Imports novos necessários para o botão e para a navegação
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

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
          final profileData = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: 16 * scale,
              horizontal: 8 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info do Coach (Foto, Nome, Bio, etc)
                CoachInfoSection(
                  profile: profileData,
                  onRefreshRequest: _loadProfile,
                ),

                SizedBox(height: 32 * scale),

                // ✅ O NOVO BOTÃO DE VER TODOS OS CICLOS
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8 * scale),
                  child: OutlinedButton.icon(
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.coachAllCycles,
                        ),
                    icon: Icon(
                      Icons.calendar_month_outlined,
                      size: 20 * scale,
                      color: AppColors.baseBlue,
                    ),
                    label: Text(
                      'Ver todos os ciclos',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: FontWeight.bold,
                        fontSize: 14 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14 * scale),
                      side: const BorderSide(
                        color: AppColors.baseBlue,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16 * scale),
              ],
            ),
          );
        },
      ),
    );
  }
}
