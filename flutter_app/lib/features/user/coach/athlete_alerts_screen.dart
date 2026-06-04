import 'package:flutter/material.dart';

class AthleteAlertsScreen extends StatelessWidget {
  static const routeName = '/athlete_alerts';
  const AthleteAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Alertas sobre Alunos (em breve)')),
    );
  }
}
