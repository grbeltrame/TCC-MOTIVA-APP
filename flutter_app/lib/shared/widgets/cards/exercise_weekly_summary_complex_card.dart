// lib/shared/widgets/exercise_weekly_summary_complex_card.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/exercise_weekly_summary_service.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart'
    show StimulusCount;

class ExerciseWeeklySummaryComplexCard extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  const ExerciseWeeklySummaryComplexCard({Key? key, this.from, this.to})
    : super(key: key);

  // Paleta com mais contraste, mantendo o eixo azul + magenta do app.
  // Ordem alterna azul forte e magenta forte para que fatias de tamanho
  // parecido fiquem visualmente distintas. Cinza fica reservado para
  // "Outros".
  static const _pieColors = [
    AppColors.baseBlue,
    AppColors.baseMagenta,
    AppColors.darkBlue,
    AppColors.lightMagenta,
    AppColors.mediumGray,
  ];

  /// Reduz a distribuição para Top 4 + Outros, mantendo o total original.
  /// Se houver 4 ou menos estímulos, devolve a lista intacta.
  /// Também devolve a lista dos estímulos agrupados em "Outros" (vazia
  /// quando não há agrupamento).
  static _ReducedDistribution _topNWithOthers(
    List<StimulusCount> data, {
    int n = 4,
  }) {
    if (data.length <= n) {
      return _ReducedDistribution(
        list: List<StimulusCount>.from(data),
        othersDetails: const [],
      );
    }
    final sorted = [...data]..sort((a, b) => b.count.compareTo(a.count));
    final top = sorted.take(n).toList();
    final remainder = sorted.skip(n).toList();
    final othersTotal =
        remainder.fold<int>(0, (sum, e) => sum + e.count);
    if (othersTotal > 0) {
      top.add(StimulusCount('Outros', othersTotal));
    }
    return _ReducedDistribution(list: top, othersDetails: remainder);
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final scale = screenW / 375.0;

    // Pizza menor pra manter o card compacto
    final pieSize = screenW * 0.25;

    return FutureBuilder<ComplexExerciseSummary>(
      future: ExerciseWeeklySummaryService.fetchComplexSummary(
        from: from,
        to: to,
      ),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            height: 140 * scale,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return _EmptyCard(scale: scale, message: 'Erro ao carregar resumo');
        }

        final summary = snap.data!;
        // Total calculado sobre a distribuição original — assim os
        // percentuais (incluindo "Outros") somam corretamente.
        final total = summary.distribution.fold<int>(
          0,
          (sum, d) => sum + d.count,
        );
        // Top 4 + "Outros" para evitar pizza ilegível com muitas fatias.
        final reduced = _topNWithOthers(summary.distribution);
        final reducedList = reduced.list;
        final othersDetails = reduced.othersDetails;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 3 * scale),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: AppColors.mediumGray),
            borderRadius: BorderRadius.circular(14 * scale),
          ),
          elevation: 0,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              10 * scale,
              8 * scale,
              10 * scale,
              9 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título padronizado
                Text(
                  'DISTRIBUIÇÃO DE ESTÍMULOS',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: FontWeight.bold,
                    fontSize: 9.5 * scale,
                    color: AppColors.darkBlue,
                    letterSpacing: 0.7,
                  ),
                ),
                SizedBox(height: 6 * scale),

                if (reducedList.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8 * scale),
                    child: Text(
                      'Nenhum estímulo registrado no período.',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 11.5 * scale,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  )
                else ...[
                  // ── Conteúdo: pizza (esq) + bloco estruturado (dir) ──────
                  SizedBox(
                    height: pieSize,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: pieSize,
                          height: pieSize,
                          child: SfCircularChart(
                            margin: EdgeInsets.zero,
                            palette: _pieColors,
                            tooltipBehavior: TooltipBehavior(
                              enable: true,
                              builder: (data, point, series, pointIndex,
                                  seriesIndex) {
                                if (data is! StimulusCount) {
                                  return const SizedBox.shrink();
                                }
                                final pct = total > 0
                                    ? ((data.count / total) * 100).round()
                                    : 0;
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10 * scale,
                                    vertical: 6 * scale,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkText,
                                    borderRadius:
                                        BorderRadius.circular(6 * scale),
                                  ),
                                  child: Text(
                                    '${data.name}: $pct%',
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.5 * scale,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                            series:
                                <DoughnutSeries<StimulusCount, String>>[
                              DoughnutSeries<StimulusCount, String>(
                                dataSource: reducedList,
                                xValueMapper: (d, _) => d.name,
                                yValueMapper: (d, _) => d.count,
                                innerRadius: '60%',
                                radius: '100%',
                                enableTooltip: true,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 12 * scale),

                        // Bloco à direita: tudo top-aligned com hierarquia clara
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              // Rótulo de seção (mesmo estilo do card title)
                              Text(
                                'ESTÍMULO PRINCIPAL',
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 8.5 * scale,
                                  color: AppColors.darkBlue,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              SizedBox(height: 2 * scale),

                              // Nome em destaque
                              Text(
                                summary.predominantStimulus,
                                style: TextStyle(
                                  fontFamily: AppFonts.montserrat,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17 * scale,
                                  color: AppColors.darkBlue,
                                  height: 1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Separador sutil
                              SizedBox(height: 6 * scale),
                              Container(
                                height: 1,
                                width: 24 * scale,
                                color: AppColors.mediumGray
                                    .withValues(alpha: 0.35),
                              ),
                              SizedBox(height: 6 * scale),

                              // Insight curto
                              Expanded(
                                child: Text(
                                  summary.shortInsight,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontSize: 9.5 * scale,
                                    color: AppColors.darkText,
                                    height: 1.25,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8 * scale),

                  // Legenda compacta — Top 4 + "Outros" (quando houver).
                  // O chip "Outros" é tappable e abre um bottom sheet com
                  // os estímulos agrupados e suas porcentagens.
                  Wrap(
                    spacing: 7 * scale,
                    runSpacing: 3 * scale,
                    children: reducedList.asMap().entries.map((e) {
                      final color = _pieColors[e.key % _pieColors.length];
                      final pct = total > 0
                          ? ((e.value.count / total) * 100).round()
                          : 0;
                      final isOthers = e.value.name == 'Outros';

                      final chip = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6 * scale,
                            height: 6 * scale,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 3 * scale),
                          Text(
                            '${e.value.name} $pct%',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontSize: 9 * scale,
                              color: AppColors.darkText,
                              fontStyle: isOthers
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              decoration: isOthers
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                          if (isOthers) ...[
                            SizedBox(width: 2 * scale),
                            Icon(
                              Icons.info_outline,
                              size: 10 * scale,
                              color: AppColors.mediumGray,
                            ),
                          ],
                        ],
                      );

                      if (isOthers) {
                        return InkWell(
                          onTap: () => _showOthersSheet(
                            context,
                            othersDetails,
                            total,
                          ),
                          borderRadius: BorderRadius.circular(4 * scale),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2 * scale,
                              vertical: 1 * scale,
                            ),
                            child: chip,
                          ),
                        );
                      }
                      return Tooltip(
                        message: e.value.name,
                        child: chip,
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReducedDistribution {
  final List<StimulusCount> list;
  final List<StimulusCount> othersDetails;
  const _ReducedDistribution({
    required this.list,
    required this.othersDetails,
  });
}

void _showOthersSheet(
  BuildContext context,
  List<StimulusCount> details,
  int total,
) {
  final scale = MediaQuery.of(context).size.width / 375.0;
  final sorted = [...details]..sort((a, b) => b.count.compareTo(a.count));

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20 * scale),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20 * scale,
          12 * scale,
          20 * scale,
          24 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40 * scale,
                height: 4 * scale,
                margin: EdgeInsets.only(bottom: 12 * scale),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2 * scale),
                ),
              ),
            ),
            Text(
              'Outros estímulos',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 4 * scale),
            Text(
              'Estímulos agrupados em "Outros" e suas porcentagens no período.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 11 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 12 * scale),
            for (final s in sorted)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 4 * scale),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 13 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),
                    Text(
                      '${total > 0 ? ((s.count / total) * 100).round() : 0}%',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: FontWeight.bold,
                        fontSize: 13 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _EmptyCard extends StatelessWidget {
  final double scale;
  final String message;
  const _EmptyCard({required this.scale, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 3 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(14 * scale),
        child: Text(
          message,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 11.5 * scale,
            color: AppColors.mediumGray,
          ),
        ),
      ),
    );
  }
}
