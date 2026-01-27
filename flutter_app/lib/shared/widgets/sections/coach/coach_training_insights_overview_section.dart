import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/users/coach/daily_insights_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/carousels/adaptative_insights_carousel.dart';
import 'package:flutter_app/shared/widgets/utils/date_selector.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';

/// Section que representa o card de "Insights dos Treinos"
/// da tela de Insights do Coach.
///
/// - Usa o DateSelector padrão do app.
/// - Mostra período semanal (segunda–domingo) com base na data selecionada.
/// - Exibe 4 blocos de insights (Análise / Alertas / Acertos / Sugestões)
///   em formato de “carrossel” horizontal de textos longos.
/// - No rodapé, botões "Todos os WODs" e "Análise por treino"
///   (sem navegação por enquanto).
class CoachTrainingInsightsOverviewSection extends StatefulWidget {
  final String boxId;

  const CoachTrainingInsightsOverviewSection({super.key, required this.boxId});

  @override
  State<CoachTrainingInsightsOverviewSection> createState() =>
      _CoachTrainingInsightsOverviewSectionState();
}

class _CoachTrainingInsightsOverviewSectionState
    extends State<CoachTrainingInsightsOverviewSection> {
  late DateTime _selectedDate;
  late Future<CoachDayOverviewInsights> _future;
  final _service = CoachDailyInsightsService();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _future = _service.fetchDayOverviewInsights(
      boxId: widget.boxId,
      date: _selectedDate,
    );
  }

  void _onDateChanged(DateTime d) {
    setState(() {
      _selectedDate = d;
      _future = _service.fetchDayOverviewInsights(
        boxId: widget.boxId,
        date: _selectedDate,
      );
    });
  }

  String _formatPeriod(DateTime start, DateTime end) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

    return 'Período atual - de ${fmt(start)} a ${fmt(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título + botão "Ver Insights do Ciclo"
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Insights dos Treinos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextActionButton(
                text: 'Ver Insights do Ciclo',
                icon: Icons.add,
                fontSize: 10 * scale,
                color: AppColors.baseBlue,
                onPressed: () {
                  // 🔹 Navega para a tela de insights de ciclo
                  //     já com o MÊS ATUAL selecionado.
                  final now = DateTime.now();
                  final currentMonth = DateTime(now.year, now.month);

                  Navigator.pushNamed(
                    context,
                    AppRoutes.coachTrainingInsights,
                    arguments: {
                      'month': currentMonth,
                      // se quiser depois passar boxId aqui, é só incluir:
                      // 'boxId': '1',
                    },
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 8 * scale),

        // DateSelector
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: DateSelector(
            initialDate: _selectedDate,
            onDateChanged: _onDateChanged,
          ),
        ),
        SizedBox(height: 12 * scale),

        // Card de insights
        FutureBuilder<CoachDayOverviewInsights>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 160 * scale,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final overview = snapshot.data;

            // Se não veio nada ou todos os buckets estão vazios,
            // mostra mensagem geral e não exibe o card.
            if (overview == null ||
                overview.buckets.isEmpty ||
                overview.buckets.every((b) => b.messages.isEmpty)) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                child: Text(
                  'Nenhum insight disponível para o período selecionado.',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              );
            }

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 6 * scale),
              padding: EdgeInsets.all(10 * scale),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Linha do período com ícone de calendário
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(4 * scale),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6 * scale),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: Icon(
                          Icons.calendar_today_outlined,
                          size: 14 * scale,
                          color: AppColors.baseBlue,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: Text(
                          _formatPeriod(
                            overview.periodStart,
                            overview.periodEnd,
                          ),
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 12 * scale,
                            fontWeight: AppFontWeight.bold,
                            color: AppColors.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * scale),

                  // Buckets de insights (Análise / Alertas / Acertos / Sugestões)
                  ..._buildBuckets(context, overview, scale),

                  SizedBox(height: 12 * scale),

                  // Rodapé com botões
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.coachTrainings,
                            );
                          },
                          icon: Icon(Icons.list_alt_outlined, size: 16 * scale),
                          label: const Text('Todos os WODs'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.baseBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 8 * scale),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20 * scale),
                            ),
                            textStyle: TextStyle(
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.coachEvolutions,
                            );
                          },
                          icon: Icon(
                            Icons.analytics_outlined,
                            size: 16 * scale,
                            color: AppColors.baseBlue,
                          ),
                          label: Text(
                            'Análise por treino',
                            style: TextStyle(
                              color: AppColors.baseBlue,
                              fontSize: 12 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.baseBlue,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20 * scale),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 8 * scale),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildBuckets(
    BuildContext context,
    CoachDayOverviewInsights overview,
    double scale,
  ) {
    final children = <Widget>[];

    for (var i = 0; i < overview.buckets.length; i++) {
      final bucket = overview.buckets[i];

      if (i > 0) {
        // Divider entre blocos
        children.add(
          Divider(height: 16 * scale, thickness: 1, color: AppColors.lightGray),
        );
      }

      children.add(_BucketInsights(bucket: bucket, scale: scale));
    }

    return children;
  }
}

/// Estilos para cada bucket (cores/ícones)
class _BucketStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _BucketStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}

const Map<String, _BucketStyle> _bucketStyles = {
  'analysis': _BucketStyle(
    background: AppColors.baseBlue,
    foreground: Colors.white,
    icon: Icons.analytics_outlined,
  ),
  'alerts': _BucketStyle(
    background: Colors.red,
    foreground: Colors.white,
    icon: Icons.warning_amber_rounded,
  ),
  'highlights': _BucketStyle(
    background: AppColors.darkBlue,
    foreground: Colors.white,
    icon: Icons.emoji_events_outlined,
  ),
  'suggestions': _BucketStyle(
    background: AppColors.mediumGray,
    foreground: Colors.white,
    icon: Icons.lightbulb_outline,
  ),
};

class _BucketInsights extends StatelessWidget {
  final CoachDayOverviewInsightsBucket bucket;
  final double scale;

  const _BucketInsights({required this.bucket, required this.scale});

  @override
  Widget build(BuildContext context) {
    final style =
        _bucketStyles[bucket.key] ??
        const _BucketStyle(
          background: AppColors.baseBlue,
          foreground: Colors.white,
          icon: Icons.info_outline,
        );

    // Usa o carrossel adaptativo que criamos
    return AdaptiveInsightsCarousel(
      title: bucket.title,
      icon: style.icon,
      pillColor: style.background,
      pillTextColor: style.foreground,
      messages: bucket.messages,
    );
  }
}
