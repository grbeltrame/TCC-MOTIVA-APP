import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

class CoachEvolutionsScreen extends StatefulWidget {
  static const routeName = '/coach_evolutions';
  const CoachEvolutionsScreen({Key? key}) : super(key: key);

  @override
  State<CoachEvolutionsScreen> createState() => _CoachEvolutionsScreenState();
}

class _CoachEvolutionsScreenState extends State<CoachEvolutionsScreen> {
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back
          Padding(
            padding: EdgeInsets.only(
              top: 8 * scale,
              left: 6 * scale,
              right: 6 * scale,
            ),
            child: const AppBackButton(),
          ),

          // Conteúdo
          Expanded(
            child: Center(
              child: Text(
                'Evoluções do Coach\n(estrutura mínima / placeholder)',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
