// lib/features/athlete_home/presentation/athlete_home_screen.dart
import 'package:flutter/material.dart';

class AthleteHomeScreen extends StatelessWidget {
  static const routeName = '/athlete_home';
  const AthleteHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Atleta')),
      body: const Center(child: Text('Bem-vindo atleta!')),
    );
  }
}
