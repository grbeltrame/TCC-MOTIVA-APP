// lib/shared/screens/athlete_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/top_navbar.dart';
import 'package:flutter_app/shared/widgets/weekly_summary_widget.dart';

class AthleteHomeScreen extends StatefulWidget {
  static const routeName = '/athlete_home';
  const AthleteHomeScreen({Key? key}) : super(key: key);

  @override
  State<AthleteHomeScreen> createState() => _AthleteHomeScreenState();
}

class _AthleteHomeScreenState extends State<AthleteHomeScreen> {
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
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 16 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Título do Resumo Semanal ---
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Resumo Semanal',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            SizedBox(height: 8 * scale),

            // --- Widget principal de Resumo Semanal ---
            const WeeklySummaryWidget(),
          ],
        ),
      ),
    );
  }
}
