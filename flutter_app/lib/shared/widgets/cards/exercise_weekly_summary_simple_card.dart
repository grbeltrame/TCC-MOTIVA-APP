// lib/shared/widgets/exercise_weekly_summary_simple_card.dart

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/exercise_weekly_summary_service.dart';

/// Card simples de resumo semanal de exercícios,
/// com duas colunas forçadas a ter a mesma altura:
///   • Coluna 1: anel de progresso
///   • Coluna 2: textos (quebrando linha) + botão enxuto
class ExerciseWeeklySummarySimpleCard extends StatelessWidget {
  const ExerciseWeeklySummarySimpleCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final scale = screenW / 375.0;

    // proporção do mock: 119/375 ≃ 0.32 da largura
    final indicatorW = screenW * 0.32;
    final gap = screenW * 0.06;

    return FutureBuilder<SimpleExerciseSummary>(
      future: ExerciseWeeklySummaryService.fetchSimpleSummary(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        final data = snap.data;
        if (snap.hasError || data == null)
          return const Center(child: Text('Erro ao carregar resumo'));

        final pct = (data.completedValue / data.targetValue).clamp(0.0, 1.0);

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8 * scale),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.lightGray, width: 1 * scale),
              borderRadius: BorderRadius.circular(16 * scale),
            ), // fundo transparente
            child: Padding(
              // padding interno do card
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scale,
                vertical: 12 * scale,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // COLUNA 1: indicador circular
                    SizedBox(
                      width: indicatorW,
                      height:
                          indicatorW, // adiciona altura fixa igual à largura
                      child: Center(
                        child: CircularPercentIndicator(
                          radius:
                              indicatorW / 2, // raio definido explicitamente
                          lineWidth: 6 * scale,
                          percent: pct,
                          center: Text(
                            '${data.completedValue.round()} ${data.completedValue.round() == 1 ? 'treino' : 'treinos'}\n'
                            '${data.completedValue.round() == 1 ? 'semanal' : 'semanais'}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: AppFontWeight.bold,
                              fontSize: 12 * scale,
                              color: AppColors.darkText,
                            ),
                          ),
                          progressColor: AppColors.baseBlue,
                          backgroundColor: AppColors.baseBlue.withOpacity(0.1),
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                      ),
                    ),

                    SizedBox(width: gap),

                    // COLUNA 2: textos quebrando linha + botão
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // bloco de textos (sem limite de linhas)
                          Text(
                            'Olá, ${data.userName}!',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: AppFontWeight.bold,
                              fontSize: 14 * scale,
                              color: AppColors.darkText,
                            ),
                          ),
                          SizedBox(height: 4 * scale),

                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: 12 * scale,
                                color: AppColors.darkText,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Seu objetivo: ',
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: data.goalName,
                                  style: TextStyle(
                                    fontWeight: AppFontWeight.regular,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 4 * scale),

                          Text(
                            'Falta ${(data.targetValue - data.completedValue).round()} ${((data.targetValue - data.completedValue) == 1) ? 'treino' : 'treinos'} para bater a meta!',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: AppFontWeight.medium,
                              fontSize: 12 * scale,
                              color: AppColors.darkText,
                            ),
                          ),

                          // botão “Registrar treino” no rodapé da coluna
                          Align(
                            alignment: Alignment.center,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                // TODO: abrir fluxo de registrar resultado
                              },
                              icon: Icon(
                                Icons.add,
                                size: 16 * scale,
                                color: AppColors.baseBlue,
                              ),
                              label: Text(
                                'Registrar treino',
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontWeight: AppFontWeight.medium,
                                  fontSize: 12 * scale,
                                  color: AppColors.baseBlue,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.symmetric(
                                  vertical: 4 * scale,
                                  horizontal: 18 * scale,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                side: BorderSide(
                                  color: AppColors.baseBlue,
                                  width: 1.5 * scale,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    8 * scale,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
