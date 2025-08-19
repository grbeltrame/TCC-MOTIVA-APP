import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

class ClassDetailScreen extends StatefulWidget {
  static const routeName = '/class_detail';
  const ClassDetailScreen({Key? key}) : super(key: key);

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  late String _classId;
  late DateTime _date;
  late String _category;
  late String _startLabel; // <- agora é String (ex.: "07:00")
  late String _coachName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _classId = args['classId'] as String;
    _date = (args['date'] as DateTime?) ?? DateTime.now();
    _category = (args['category'] as String?) ?? 'WOD';
    _startLabel = (args['start'] as String?) ?? '--:--'; // <- lido como String
    _coachName = (args['coachName'] as String?) ?? 'Coach';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () {}),
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

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 10 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card resumo da turma
                  Container(
                    padding: EdgeInsets.all(14 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.mediumGray),
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Turma $_startLabel — ${_category.toUpperCase()}',
                          style: TextStyle(
                            fontFamily: AppFonts.montserrat,
                            fontWeight: AppFontWeight.bold,
                            fontSize: 18 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          'Professor: $_coachName',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 14 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                        SizedBox(height: 12 * scale),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              await DayClasses.registerInterestInClass(
                                classId: _classId,
                                date: _date,
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Interesse registrado!'),
                                ),
                              );
                            },
                            child: const Text('Tenho interesse na aula'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 14 * scale),

                  // Card resumo do professor (placeholder; você detalha depois)
                  Container(
                    padding: EdgeInsets.all(14 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.mediumGray),
                      borderRadius: BorderRadius.circular(12 * scale),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sobre o Professor',
                          style: TextStyle(
                            fontFamily: AppFonts.montserrat,
                            fontWeight: AppFontWeight.bold,
                            fontSize: 16 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                        SizedBox(height: 6 * scale),
                        Text(
                          _coachName,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.bold,
                            fontSize: 14 * scale,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          'Resumo do perfil em breve. '
                          'TODO(back): trazer foto, certificações e bio.',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 13 * scale,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
