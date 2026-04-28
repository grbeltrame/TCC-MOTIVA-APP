// lib/features/user/athlete/athlete_evolution_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/features/user/athlete/athlete_evolution_insights_detail_screen.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/athlete_insights_carousel_loader.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/evolution_charts_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/exercise_weekly_summary_widget.dart';
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
    _to = now;
    // Padrão: últimas 12 semanas — mostra evolução real ao invés de só o mês atual.
    _from = now.subtract(const Duration(days: 84));
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
            // ── Título + seletor de período ─────────────────────────────────
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
                  _DateChip(
                    label: fmt.format(_from),
                    onTap: () => _pickDate(isFrom: true),
                    scale: scale,
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
                  _DateChip(
                    label: fmt.format(_to),
                    onTap: () => _pickDate(isFrom: false),
                    scale: scale,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * scale),

            // ── Resumo semanal de exercícios (gráfico de pizza) ──────────────
            ExerciseWeeklySummaryWidget(from: _from, to: _to),

            SizedBox(height: 4 * scale),

            // ── Estatísticas de treino ───────────────────────────────────────
            WeeklyStatisticsWidget(from: _from, to: _to),

            SizedBox(height: 12 * scale),

            // ── Insights de evolução (onCall automático, respeita cache 4d) ─
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Insights de Evolução',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 13 * scale,
                    color: AppColors.darkText,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AthleteEvolutionInsightsDetailScreen.routeName,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6 * scale,
                      vertical: 2 * scale,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver todos',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 11 * scale,
                            fontWeight: FontWeight.w600,
                            color: AppColors.baseBlue,
                          ),
                        ),
                        SizedBox(width: 2 * scale),
                        Icon(
                          Icons.chevron_right,
                          size: 14 * scale,
                          color: AppColors.baseBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4 * scale),

            AthleteInsightsCarouselLoader(
              mode: AthleteInsightsMode.evolutionOnly,
              onTap: () => Navigator.pushNamed(
                context,
                AthleteEvolutionInsightsDetailScreen.routeName,
              ),
            ),

            SizedBox(height: 4 * scale),

            // ── Gráficos de evolução (PRs + Volume) ─────────────────────────
            EvolutionChartsSection(from: _from, to: _to),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de data — estilo consistente com o filtro das estatísticas
// ─────────────────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double scale;

  const _DateChip({
    required this.label,
    required this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * scale,
          vertical: 4 * scale,
        ),
        decoration: BoxDecoration(
          color: AppColors.baseBlue.withValues(alpha: 0.08),
          border: Border.all(
            color: AppColors.baseBlue.withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(18 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 11 * scale,
              color: AppColors.darkBlue,
            ),
            SizedBox(width: 4 * scale),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 11 * scale,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
