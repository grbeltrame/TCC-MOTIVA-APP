// lib/features/athlete_home/presentation/athlete_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/top_navbar.dart';
import 'package:flutter_app/core/services/profile_service.dart';

/// Instância única de ProfileService (mock) criada fora do widget
final _profileService = ProfileService();

/// Tela inicial do atleta (ou coach, se estiver no perfil de coach).
class AthleteHomeScreen extends StatelessWidget {
  static const routeName = '/athlete_home';

  const AthleteHomeScreen({Key? key}) : super(key: key);

  // método para abrir o BottomSheet de cadastro de box
  void _openRegisterBoxSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (_) => Container(
            height: 200,
            alignment: Alignment.center,
            child: const Text('Formulário de cadastro de box aqui'),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1) Barra superior customizada — **sem** const, pois recebe callback não-const
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),

      // Corpo da tela
      body: Center(
        child: Text(
          'Bem-vindo, ${_profileService.currentRoleLabel}!',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
