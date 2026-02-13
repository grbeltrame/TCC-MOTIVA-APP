// lib/shared/widgets/sections/athlete/training_info_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/features/user/athlete/athlete_classes_screen.dart';
import 'package:flutter_app/shared/models/class.dart';
import 'package:flutter_app/shared/widgets/dialogs/activity_status_dialogs.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/category_training_section.dart';
import 'package:flutter_app/shared/widgets/utils/primary_button.dart';
import 'package:flutter_app/shared/widgets/utils/date_selector.dart';
import 'package:flutter_app/shared/widgets/cards/interested_class_card.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/rate_coach_bottom_sheet.dart';
import 'package:flutter_app/core/services/users/coach/coach_service.dart';

class TrainingInfoSection extends StatefulWidget {
  final ValueChanged<DateTime> onDateChanged;

  const TrainingInfoSection({Key? key, required this.onDateChanged})
    : super(key: key);

  @override
  _TrainingInfoSectionState createState() => _TrainingInfoSectionState();
}

class _TrainingInfoSectionState extends State<TrainingInfoSection> {
  late DateTime _selectedDate;

  // Interesses do dia
  List<InterestedClass> _interests = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateChanged(_selectedDate);
      _reloadInterests();
    });
  }

  Future<void> _reloadInterests() async {
    final list = await ClassInterestService.fetchInterestsForDate(
      _selectedDate,
    );
    if (!mounted) return;
    setState(() => _interests = list);
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    widget.onDateChanged(newDate);
    _reloadInterests();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ===== Linha de seleção de data =====
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: DateSelector(
            initialDate: _selectedDate,
            onDateChanged: _onDateChanged,
          ),
        ),

        SizedBox(height: 4 * scale),

        // ===== Tabs com categorias de treino =====
        CategoryTrainingSection(date: _selectedDate, boxId: ''),

        SizedBox(height: 12 * scale),

        // ===== Cards de interesse =====
        if (_interests.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * scale),
            child: Column(
              children:
                  _interests.map((it) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10 * scale),
                      child: InterestedClassCard(
                        timeLabel: it.timeLabel,
                        category: it.category,
                        coachName: it.coachName,
                        onChangeTime: () async {
                          await Navigator.of(context).pushNamed(
                            ClassesOfDayScreen.routeName,
                            arguments: {'date': _selectedDate},
                          );
                          await _reloadInterests();
                        },
                        onRegisterResult: () async {
                          await showRegisterResultBottomSheet(context);
                        },
                        onRateCoach: () async {
                          try {
                            final coach = await CoachService.fetchCoachForClass(
                              it.classId,
                            );

                            await showRateCoachBottomSheet(
                              context,
                              coachId: coach.id,
                              coachName: coach.name,
                              classId: it.classId,
                              date: _selectedDate,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Não foi possível abrir a avaliação.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          SizedBox(height: 4 * scale),
        ],

        // ===== Botão Ver turmas =====
        // Align(
        //   alignment: Alignment.center,
        //   child: PrimaryButton(
        //     label: 'Ver turmas do dia',
        //     onPressed: () async {
        //       await Navigator.of(context).pushNamed(
        //         ClassesOfDayScreen.routeName,
        //         arguments: {'date': _selectedDate},
        //       );
        //       await _reloadInterests();
        //     },
        //   ),
        // ),
        // SizedBox(height: 12 * scale),

        // ===== Status do dia =====
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () {
                showDidNotTrainDialog(context, date: _selectedDate);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.lightMagenta.withAlpha(50),
                side: BorderSide(color: AppColors.baseMagenta),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 8 * scale,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Não treinei hoje',
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  color: AppColors.baseMagenta,
                ),
              ),
            ),
            SizedBox(width: 16 * scale),
            OutlinedButton(
              onPressed: () {
                showOtherActivityDialog(
                  context,
                  date: _selectedDate,
                  description: 'Caminhada leve',
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.baseBlue.withAlpha(50),
                side: BorderSide(color: AppColors.baseBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 8 * scale,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Fiz outra atividade física',
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  color: AppColors.baseBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
