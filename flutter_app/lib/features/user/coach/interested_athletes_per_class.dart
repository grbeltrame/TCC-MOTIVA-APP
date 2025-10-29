import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

class InterestedAthletesScreen extends StatefulWidget {
  static const routeName = '/interested_atlhetes';
  const InterestedAthletesScreen({Key? key}) : super(key: key);

  @override
  State<InterestedAthletesScreen> createState() =>
      _InterestedAthletesScreenState();
}

class _InterestedAthletesScreenState extends State<InterestedAthletesScreen> {
  void _openRegisterBoxSheet() {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // ───── Leitura segura dos argumentos ─────
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final DateTime date =
        (args != null && args['date'] is DateTime)
            ? args!['date'] as DateTime
            : DateTime.now();

    final String boxId =
        (args != null && args['boxId'] is String)
            ? args!['boxId'] as String
            : '';

    final String category =
        (args != null && args['category'] is String)
            ? args!['category'] as String
            : 'WOD';

    final String hour =
        (args != null && args['hour'] is String)
            ? args!['hour'] as String
            : '--';

    final int count =
        (args != null && args['count'] is int) ? args!['count'] as int : 0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: _openRegisterBoxSheet),
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

          // Cabeçalho com contexto (data / categoria / horário)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 8 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alunos interessados por turma',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 6 * scale),
                Text(
                  '${_fmtDate(date)} · $category · Horário: $hour',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  '$count aluno(s) interessado(s)',
                  style: TextStyle(
                    fontSize: 14 * scale,
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Conteúdo (lista de alunos) — placeholder por enquanto
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * scale),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12 * scale),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10 * scale),
                  border: Border.all(color: AppColors.lightGray),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 3 * scale,
                      offset: Offset(0, 1 * scale),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'TODO(back): carregar lista de alunos interessados\n'
                    '(boxId: $boxId, categoria: $category, data: ${_fmtDate(date)}, horário: $hour)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
