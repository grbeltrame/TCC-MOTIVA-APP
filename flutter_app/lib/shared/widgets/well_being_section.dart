import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/well_being_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/text_action_button.dart';

/// Seção completa de “Bem‑estar” do usuário:
/// – título + card
/// – só aparece se existir pelo menos 1 registro na semana
/// – dentro do card: linha de 7 círculos coloridos + botões
class WellBeingSection extends StatelessWidget {
  const WellBeingSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<Map<DateTime, int?>>(
      future: WellBeingService.fetchWeeklyRatings(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          // placeholder com altura semelhante ao card
          return SizedBox(
            height: 120 * scale,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final ratings = snap.data ?? {};
        // não renderiza nada se todos os dias forem null
        if (ratings.values.every((v) => v == null)) {
          return const SizedBox.shrink();
        }

        // recalcula domingo para labels
        final now = DateTime.now();
        final daysFromSunday = now.weekday % 7;
        final sunday = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: daysFromSunday));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TÍTULO DA SEÇÃO
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Bem‑estar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            SizedBox(height: 8 * scale),

            // CARD
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              padding: EdgeInsets.all(12 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO
                  Text(
                    'Como você se sentiu essa semana?',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.medium,
                      fontSize: 16 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                  // SUBTÍTULO
                  SizedBox(height: 2 * scale),
                  Text(
                    'Uma visualização de como o esporte está relacionado com sua saúde mental',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.regular,
                      fontSize: 10 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                  SizedBox(height: 8 * scale),

                  // LINHA DE CÍRCULOS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (i) {
                      final day = sunday.add(Duration(days: i));
                      final rating =
                          ratings[DateTime(day.year, day.month, day.day)];

                      // escolhe cor conforme a faixa:
                      Color fill;
                      if (rating == null) {
                        // sem registro
                        fill = Colors.transparent;
                      } else if (rating <= 3) {
                        // 1,2,3 → 3 tons de vermelho
                        switch (rating) {
                          case 1:
                            fill = AppColors.darkMagenta;
                            break;
                          case 2:
                            fill = AppColors.baseMagenta;
                            break;
                          default: // rating == 3
                            fill = AppColors.lightMagenta;
                        }
                      } else if (rating == 4) {
                        // ainda ruim, usamos o tom mais claro de magenta
                        fill = AppColors.lightMagenta;
                      } else if (rating >= 7) {
                        // 7,8,9,10 → positivos, 3 tons de azul
                        switch (rating) {
                          case 7:
                            fill = AppColors.lightBlue;
                            break;
                          case 8:
                            fill = AppColors.baseBlue;
                            break;
                          default: // 9 ou 10
                            fill = AppColors.darkBlue;
                        }
                      } else {
                        // 5 e 6 → neutro
                        fill = AppColors.mediumGray;
                      }

                      // label (D, S, T, Q, Q, S, S)
                      final label = DateFormat.E(
                        'pt_BR',
                      ).format(day).substring(0, 1);

                      return Column(
                        children: [
                          Container(
                            width: 24 * scale,
                            height: 24 * scale,
                            decoration: BoxDecoration(
                              color: fill,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.mediumGray),
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            label.toUpperCase(),
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontWeight: AppFontWeight.regular,
                              fontSize: 12 * scale,
                              color: AppColors.darkText,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  SizedBox(height: 24 * scale),

                  // LINHA DIVISÓRIA
                  Divider(color: AppColors.lightGray),
                  SizedBox(height: 8 * scale),

                  // BOTÕES (flush nas bordas e maior espaçamento)
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween, // empurra para as extremidades
                    children: [
                      // 1) + Registrar bem‑estar
                      TextButton.icon(
                        onPressed: () {
                          // TODO: abrir bottom sheet de registro de bem‑estar
                        },
                        icon: Icon(
                          Icons.add,
                          size: 16 * scale,
                          color: AppColors.baseBlue,
                        ),
                        label: Text(
                          'Registrar bem‑estar',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.medium,
                            fontSize: 12 * scale, // fonte um pouco menor
                            color: AppColors.baseBlue,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scale,
                            vertical: 4 * scale,
                          ),

                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),

                      // 2) Ver todos os registros →
                      TextButton(
                        onPressed: () {
                          // TODO: navegar para página de histórico de bem‑estar
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scale,
                            vertical: 4 * scale,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ver todos os registros',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontWeight: AppFontWeight.medium,
                                fontSize: 12 * scale,
                                color: AppColors.baseBlue,
                              ),
                            ),
                            SizedBox(width: 4 * scale),
                            Icon(
                              Icons.navigate_next,
                              size: 16 * scale,
                              color: AppColors.baseBlue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 32 * scale),
          ],
        );
      },
    );
  }
}
