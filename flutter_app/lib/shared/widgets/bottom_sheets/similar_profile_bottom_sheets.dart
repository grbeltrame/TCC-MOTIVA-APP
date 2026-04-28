// lib/shared/widgets/bottom_sheets/similar_profile_bottom_sheets.dart

import 'package:flutter/material.dart';
// Oculta ChartPoint do Syncfusion para evitar colisão com o nosso
import 'package:syncfusion_flutter_charts/charts.dart' hide ChartPoint;

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';

// Profile (para “Perfil de Referência”)
import 'package:flutter_app/core/services/users/athlete/athlete_service.dart';
import 'package:flutter_app/shared/models/athlete_profile.dart';

// Service de perfis semelhantes (alias sps)
import 'package:flutter_app/core/services/similar_profiles_service.dart' as sps;

/// Abra com:
/// await showSimilarProfilesBottomSheet(
///   context,
///   benchmarkName: 'Fran', // ou movementName: 'Back Squat'
///   onTapRegister: () async { /* abrir registrar PR/Resultado */ },
/// );
Future<void> showSimilarProfilesBottomSheet(
  BuildContext context, {
  String? benchmarkName,
  String? movementName,
  required Future<void> Function() onTapRegister,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => _SimilarProfilesSheet(
          benchmarkName: benchmarkName,
          movementName: movementName,
          onTapRegister: onTapRegister,
        ),
  );
}

class _SimilarProfilesSheet extends StatefulWidget {
  final String? benchmarkName;
  final String? movementName;
  final Future<void> Function() onTapRegister;

  const _SimilarProfilesSheet({
    this.benchmarkName,
    this.movementName,
    required this.onTapRegister,
  });

  @override
  State<_SimilarProfilesSheet> createState() => _SimilarProfilesSheetState();
}

class _SimilarProfilesSheetState extends State<_SimilarProfilesSheet> {
  final _simSvc = sps.SimilarProfilesService();

  late Future<AthleteProfile> _profileFut;
  late Future<String> _predictionFut;
  late Future<sps.ChartSeriesBundle> _resultsFut;
  late Future<sps.ChartSeriesBundle> _loadsFut;

  @override
  void initState() {
    super.initState();
    // método estático:
    _profileFut = AthleteService.fetchAthleteProfile();

    _predictionFut = _simSvc.fetchPredictedResultText(
      benchmarkName: widget.benchmarkName,
      movementName: widget.movementName,
    );
    _resultsFut = _simSvc.fetchSimilarResultsSeries(
      lastDays: 30,
      benchmarkName: widget.benchmarkName,
      movementName: widget.movementName,
    );
    _loadsFut = _simSvc.fetchSimilarLoadsSeries(
      lastDays: 30,
      benchmarkName: widget.benchmarkName,
      movementName: widget.movementName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return AppBottomSheet(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          14 * scale,
          16 * scale,
          20 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Esses são os resultados de pessoas com\nperfis semelhantes ao seu:',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
                height: 1.2,
              ),
            ),
            SizedBox(height: 12 * scale),

            // Linha com 2 blocos
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FutureBuilder<AthleteProfile>(
                    future: _profileFut,
                    builder: (ctx, snap) {
                      final reference = snap.data?.reference;
                      return _InfoBlock(
                        chipIcon: Icons.search,
                        chipLabel: 'Perfil de Referência:',
                        children:
                            reference == null
                                ? [
                                  Text(
                                    'Complete seu perfil',
                                    style: TextStyle(
                                      color: AppColors.darkText,
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                ]
                                : [
                                  Text(
                                    reference.gender,
                                    style: TextStyle(
                                      color: AppColors.darkText,
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                  Text(
                                    reference.ageRange,
                                    style: TextStyle(
                                      color: AppColors.darkText,
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                  Text(
                                    reference.weight,
                                    style: TextStyle(
                                      color: AppColors.darkText,
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                  Text(
                                    reference.practiceYears,
                                    style: TextStyle(
                                      color: AppColors.darkText,
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                  Text(
                                    reference.height,
                                    style: TextStyle(
                                      color: AppColors.darkText,
                                      fontSize: 12 * scale,
                                    ),
                                  ),
                                ],
                      );
                    },
                  ),
                ),
                SizedBox(width: 14 * scale),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _predictionFut,
                    builder: (ctx, snap) {
                      final text = snap.data ?? '—';
                      return _InfoBlock(
                        chipIcon: Icons.place_outlined,
                        chipLabel: 'Possível Resultado:',
                        children: [
                          Text(
                            text,
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: AppFontWeight.bold,
                              fontSize: 12 * scale,
                              color: AppColors.darkText,
                              height: 1.2,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 14 * scale),

            // Carrossel de gráficos
            SizedBox(
              height: 215 * scale,
              child: PageView(
                children: [
                  _ChartCard(
                    title: 'Resultados',
                    trailing: _DaysChip(scale: scale),
                    futureBundle: _resultsFut,
                  ),
                  _ChartCard(
                    title: 'Cargas',
                    trailing: _DaysChip(scale: scale),
                    futureBundle: _loadsFut,
                  ),
                ],
              ),
            ),

            SizedBox(height: 18 * scale),

            // Botões
            Padding(
              padding: EdgeInsets.only(bottom: 8 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: AppTheme.secondaryButtonStyle(
                      AppColors.darkBlue,
                      AppColors.baseBlue,
                    ),
                    onPressed: () async {
                      await widget.onTapRegister();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Registrar'),
                  ),
                  OutlinedButton(
                    style: AppTheme.tertiaryButtonStyle(AppColors.baseMagenta),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.chipIcon,
    required this.chipLabel,
    required this.children,
  });

  final IconData chipIcon;
  final String chipLabel;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8 * scale,
            vertical: 3 * scale,
          ),
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withAlpha(50),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(chipIcon, size: 16 * scale, color: AppColors.darkBlue),
              SizedBox(width: 4 * scale),
              Text(
                chipLabel,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 12 * scale,
                  color: AppColors.darkBlue,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 6 * scale),
        ...children.map(
          (w) => Padding(padding: EdgeInsets.only(bottom: 2 * scale), child: w),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.futureBundle,
    this.trailing,
  });

  final String title;
  final Widget? trailing;
  final Future<sps.ChartSeriesBundle> futureBundle;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.mediumGray),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        padding: EdgeInsets.all(10 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 16 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: 6 * scale),
            Expanded(
              child: FutureBuilder<sps.ChartSeriesBundle>(
                future: futureBundle,
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final b = snap.data!;

                  return SfCartesianChart(
                    primaryXAxis: CategoryAxis(
                      majorGridLines: const MajorGridLines(width: 0),
                      labelStyle: TextStyle(
                        fontSize: 10 * scale,
                        color: AppColors.darkText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    primaryYAxis: NumericAxis(
                      majorGridLines: const MajorGridLines(width: 0.5),
                      axisLine: const AxisLine(width: 0),
                      labelStyle: TextStyle(
                        fontSize: 10 * scale,
                        color: AppColors.darkText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // ⇩⇩⇩ Trocado para curvas (SplineSeries) e null-safe nos mapeadores
                    series: <SplineSeries<sps.ChartPoint?, String>>[
                      SplineSeries<sps.ChartPoint?, String>(
                        dataSource: b.serieA,
                        xValueMapper: (d, _) => d?.x ?? '',
                        yValueMapper: (d, _) => d?.y,
                        markerSettings: const MarkerSettings(isVisible: true),
                        enableTooltip: true,
                      ),
                      SplineSeries<sps.ChartPoint?, String>(
                        dataSource: b.serieB,
                        xValueMapper: (d, _) => d?.x ?? '',
                        yValueMapper: (d, _) => d?.y,
                        markerSettings: const MarkerSettings(isVisible: true),
                        enableTooltip: true,
                      ),
                      SplineSeries<sps.ChartPoint?, String>(
                        dataSource: b.serieC,
                        xValueMapper: (d, _) => d?.x ?? '',
                        yValueMapper: (d, _) => d?.y,
                        markerSettings: const MarkerSettings(isVisible: true),
                        enableTooltip: true,
                      ),
                    ],
                    tooltipBehavior: TooltipBehavior(enable: true, header: ''),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '30 dias',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.bold,
            fontSize: 12 * scale,
            color: AppColors.mediumGray,
          ),
        ),
        SizedBox(width: 2 * scale),
        Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18 * scale,
          color: AppColors.mediumGray,
        ),
      ],
    );
  }
}
