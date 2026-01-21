// lib/features/user/athlete/athlete_class_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

// Coach (modelo, card e service)
import 'package:flutter_app/shared/models/coach.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/cards/coach_summary_card.dart';
import 'package:flutter_app/core/services/users/coach/coach_service.dart';
import 'package:flutter_app/shared/widgets/dialogs/interest_registred_dialog.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';

// UI utilidades
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/primary_button.dart';

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
  late String _startLabel; // string "HH:mm"
  late String _coachName;

  // future do resumo do coach
  late Future<CoachProfileSummary> _coachSummaryFut;
  bool _bootstrapped = false;
  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _classId = args['classId'] as String;
    _date = (args['date'] as DateTime?) ?? DateTime.now();
    _category = (args['category'] as String?) ?? 'WOD';
    _startLabel = (args['start'] as String?) ?? '--:--';
    _coachName = (args['coachName'] as String?) ?? 'Coach';

    // carrega resumo do professor a partir da turma
    _coachSummaryFut = CoachService.fetchCoachSummaryByClassId(_classId);

    _bootstrapped = true;
  }

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

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 10 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== Card resumo da turma =====
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
                        // Título: SOMENTE horário
                        Text(
                          'Turma $_startLabel',
                          style: TextStyle(
                            fontFamily: AppFonts.montserrat,
                            fontWeight: AppFontWeight.bold,
                            fontSize: 18 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                        SizedBox(height: 8 * scale),

                        // Professor
                        Text(
                          'Professor: $_coachName',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 14 * scale,
                            color: AppColors.darkText,
                          ),
                        ),

                        SizedBox(height: 12 * scale),

                        // Botão primário
                        PrimaryButton(
                          label: 'Tenho interesse na aula',
                          onPressed: () async {
                            try {
                              await DayClasses.registerInterestInClass(
                                classId: _classId,
                                date: _date,
                                category: _category,
                                coachName: _coachName,
                                timeLabel: _startLabel,
                              );

                              if (!mounted) return;
                              await showInterestRegisteredDialog(
                                context,
                                timeLabel: _startLabel,
                                category: _category,
                                coachName: _coachName,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Falha ao registrar interesse. Tente novamente.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 14 * scale),

                  // ===== Card resumo do professor (via service) =====
                  FutureBuilder<CoachProfileSummary>(
                    future: _coachSummaryFut,
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return Padding(
                          padding: EdgeInsets.all(12 * scale),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (!snap.hasData) {
                        return Container(
                          padding: EdgeInsets.all(14 * scale),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.mediumGray),
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                          child: Text(
                            'Não foi possível carregar o perfil do professor.',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontSize: 13 * scale,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        );
                      }
                      return CoachSummaryCard(summary: snap.data!);
                    },
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
