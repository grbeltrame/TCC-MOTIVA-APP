// lib/features/user/athlete/athlete_classes_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/class.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

import 'athlete_class_details_screen.dart';

class ClassesOfDayScreen extends StatefulWidget {
  static const routeName = '/classes_of_day';
  const ClassesOfDayScreen({Key? key}) : super(key: key);

  @override
  State<ClassesOfDayScreen> createState() => _ClassesOfDayScreenState();
}

class _ClassesOfDayScreenState extends State<ClassesOfDayScreen> {
  late DateTime _date;
  late Future<List<DayClass>> _fut;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _date = (args['date'] as DateTime?) ?? DateTime.now();

    _fut = DayClasses.fetchDayClassesWithCoach(_date);
    _bootstrapped = true;
  }

  Color _chipColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'wod':
        return AppColors.baseBlue;
      case 'lpo':
        return AppColors.baseMagenta;
      case 'ginastica':
        return AppColors.darkBlue;
      case 'endurance':
        return AppColors.lightBlue;
      default:
        return AppColors.mediumGray;
    }
  }

  /// Garante extrair apenas "HH:mm" mesmo que o label venha com texto extra.
  String _justTime(String s) {
    final m = RegExp(r'(\d{1,2}:\d{2})').firstMatch(s);
    return (m?.group(1) ?? s).trim();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final dateFmt = DateFormat('EEEE, d/MM', 'pt_BR');

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
          Padding(
            padding: EdgeInsets.fromLTRB(
              12 * scale,
              4 * scale,
              12 * scale,
              8 * scale,
            ),
            child: Text(
              'Turmas de ${dateFmt.format(_date)}',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DayClass>>(
              future: _fut,
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final classes = snap.data!;
                if (classes.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma turma para este dia.',
                      style: TextStyle(color: AppColors.mediumGray),
                    ),
                  );
                }

                // Ordena pelo horário (string "HH:mm" funciona bem)
                classes.sort((a, b) => a.timeLabel.compareTo(b.timeLabel));

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 8 * scale,
                  ),
                  itemBuilder: (_, i) {
                    final c = classes[i];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          ClassDetailScreen.routeName,
                          arguments: {
                            'classId': c.id,
                            'date': _date,
                            'category': c.category,
                            'start': c.timeLabel, // string "HH:mm"
                            'coachName': c.coachName,
                          },
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppColors.mediumGray),
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        child: Row(
                          children: [
                            // ===== ESQUERDA: SÓ o horário (sem reticências)
                            SizedBox(
                              width: 64 * scale,
                              child: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _justTime(c.timeLabel),
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: 16 * scale,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8 * scale),

                            // ===== DIREITA: chip da categoria + professor
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Chip de categoria (com cor por categoria)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8 * scale,
                                      vertical: 2 * scale,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _chipColor(
                                        c.category,
                                      ).withOpacity(.1),
                                      borderRadius: BorderRadius.circular(
                                        8 * scale,
                                      ),
                                      border: Border.all(
                                        color: _chipColor(c.category),
                                      ),
                                    ),
                                    child: Text(
                                      c.category.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: AppFonts.roboto,
                                        fontWeight: AppFontWeight.bold,
                                        fontSize: 11 * scale,
                                        color: _chipColor(c.category),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 4 * scale),
                                  Text(
                                    'Professor: ${c.coachName}',
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
                                      fontSize: 13 * scale,
                                      color: AppColors.darkText,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              Icons.chevron_right,
                              color: AppColors.mediumGray,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => SizedBox(height: 10 * scale),
                  itemCount: classes.length,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
