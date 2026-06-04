import 'package:flutter/material.dart';

class AthleteProfileDetailScreen extends StatelessWidget {
  static const routeName = '/athlete_profile_detail';
  const AthleteProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    final athleteId = args['athleteId'] as String?;
    final athleteName = args['athleteName'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil do Aluno')),
      body: Center(
        child: Text('Aluno: ${athleteName ?? athleteId ?? '(desconhecido)'}'),
      ),
    );
  }
}
