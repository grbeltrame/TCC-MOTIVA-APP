// lib/features/coach_home/presentation/coach_home_screen.dart
import 'package:flutter/material.dart';

class CoachHomeScreen extends StatelessWidget {
  static const routeName = '/coach_home';
  const CoachHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Coach')),
      body: const Center(child: Text('Bem-vindo coach!')),
    );
  }
}
