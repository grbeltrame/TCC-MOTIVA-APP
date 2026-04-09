// lib/features/user/athlete/athlete_evolution_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/analysis_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/exercise_weekly_summary_widget.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/weekly_recomendation_section.dart';
import 'package:flutter_app/shared/widgets/weekly_statistics_widget.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:intl/intl.dart';

class AthleteEvolutionScreen extends StatefulWidget {
  static const routeName = '/athlete_evolution';
  const AthleteEvolutionScreen({Key? key}) : super(key: key);

  @override
  State<AthleteEvolutionScreen> createState() => _AthleteEvolutionScreenState();
}

class _AthleteEvolutionScreenState extends State<AthleteEvolutionScreen> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, 1);
    _to = now;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
        if (_from.isAfter(_to)) _to = _from;
      } else {
        _to = picked;
        if (_to.isBefore(_from)) _from = _to;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final fmt = DateFormat('dd/MM/yy');

    return Scaffold(
      appBar: const TopNavbar(),
      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 16 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Seletor de período global ────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      'Evolução',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  GestureDetector(
                    onTap: () => _pickDate(isFrom: true),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale,
                        vertical: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGray),
                        borderRadius: BorderRadius.circular(6 * scale),
                      ),
                      child: Text(
                        fmt.format(_from),
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 11 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4 * scale),
                    child: Text(
                      '–',
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _pickDate(isFrom: false),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * scale,
                        vertical: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.lightGray),
                        borderRadius: BorderRadius.circular(6 * scale),
                      ),
                      child: Text(
                        fmt.format(_to),
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 11 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16 * scale),

            // ── Resumo semanal de exercícios (gráfico de pizza) ──────────────
            ExerciseWeeklySummaryWidget(from: _from, to: _to),
            SizedBox(height: 24 * scale),

            // ── Estatísticas de treino ───────────────────────────────────────
            WeeklyStatisticsWidget(from: _from, to: _to),
            SizedBox(height: 24 * scale),

            // ── Análises ────────────────────────────────────────────────────
            const AnalysisSection(),

            // ── Destaques / Recomendações ────────────────────────────────────
            const WeeklyRecomendationSection(),
          ],
        ),
      ),
    );
  }
}
