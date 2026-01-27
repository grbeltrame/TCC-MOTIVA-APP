import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/users/coach/daily_insights_service.dart';
import 'package:flutter_app/shared/models/coach_cycle_topic_insights.dart';
import 'package:flutter_app/shared/widgets/utils/month_selector.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

class CoachCycleInsightTopicDetailScreen extends StatefulWidget {
  static const routeName = '/coach_cycle_insight_topic_detail';

  const CoachCycleInsightTopicDetailScreen({super.key});

  @override
  State<CoachCycleInsightTopicDetailScreen> createState() =>
      _CoachCycleInsightTopicDetailScreenState();
}

class _CoachCycleInsightTopicDetailScreenState
    extends State<CoachCycleInsightTopicDetailScreen> {
  final _service = CoachDailyInsightsService();

  late String _boxId;
  late String _categoryKey;
  late String _categoryTitle;
  late String _topicKey;
  late String _topicTitle;

  late DateTime _month;
  Future<List<CoachCycleInsightItem>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};

    _boxId = (args['boxId'] ?? 'DEFAULT_BOX') as String;
    _categoryKey = (args['categoryKey'] ?? '') as String;
    _categoryTitle = (args['categoryTitle'] ?? 'Insights') as String;
    _topicKey = (args['topicKey'] ?? '') as String;
    _topicTitle = (args['topicTitle'] ?? 'Detalhes') as String;

    final DateTime? initialMonthArg = args['month'] as DateTime?;
    final now = DateTime.now();
    final initialMonth = initialMonthArg ?? DateTime(now.year, now.month);
    _month = DateTime(initialMonth.year, initialMonth.month);

    _future ??= _service.fetchCycleTopicInsights(
      boxId: _boxId,
      month: _month,
      categoryKey: _categoryKey,
      topicKey: _topicKey,
    );
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _month = DateTime(newMonth.year, newMonth.month);
      _future = _service.fetchCycleTopicInsights(
        boxId: _boxId,
        month: _month,
        categoryKey: _categoryKey,
        topicKey: _topicKey,
      );
    });
  }

  String _formatMonthLabel(DateTime m) {
    final months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return '${months[m.month - 1]} de ${m.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(
        onRegisterBox: () {}, // (você já trocou isso globalmente depois)
      ),
      bottomNavigationBar: const BottomNavBar(),
      body: Stack(
        children: [
          // Conteúdo da página (com espaço no topo pra não ficar por baixo do botão)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 8 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 52 * scale), // espaço do botão voltar no canto
                // Header principal
                Text(
                  _topicTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 6 * scale),
                Text(
                  _formatMonthLabel(_month),
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                    fontFamily: AppFonts.roboto,
                  ),
                ),
                SizedBox(height: 10 * scale),

                // Chip categoria
                Align(
                  alignment: Alignment.centerLeft,
                  child: _CategoryChip(
                    categoryKey: _categoryKey,
                    title: _categoryTitle,
                    scale: scale,
                  ),
                ),

                SizedBox(height: 12 * scale),

                // Month selector
                MonthSelector(
                  initialMonth: _month,
                  onMonthChanged: _onMonthChanged,
                ),

                SizedBox(height: 12 * scale),

                // Conteúdo
                Expanded(
                  child: FutureBuilder<List<CoachCycleInsightItem>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final list =
                          snapshot.data ?? const <CoachCycleInsightItem>[];
                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhum insight disponível para este tópico no ciclo selecionado.',
                            style: TextStyle(
                              fontSize: 12 * scale,
                              color: AppColors.mediumGray,
                              fontFamily: AppFonts.roboto,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      final grouped = <String, List<CoachCycleInsightItem>>{};
                      for (final item in list) {
                        final k = DateFormat('dd/MM/yyyy').format(item.date);
                        grouped.putIfAbsent(k, () => []);
                        grouped[k]!.add(item);
                      }

                      final keys =
                          grouped.keys.toList()..sort((a, b) {
                            final da = DateFormat('dd/MM/yyyy').parse(a);
                            final db = DateFormat('dd/MM/yyyy').parse(b);
                            return db.compareTo(da);
                          });

                      return ListView.builder(
                        itemCount: keys.length,
                        itemBuilder: (ctx, i) {
                          final dayKey = keys[i];
                          final dayItems = grouped[dayKey] ?? const [];

                          return Padding(
                            padding: EdgeInsets.only(bottom: 14 * scale),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _DayHeader(dayKey: dayKey, scale: scale),
                                SizedBox(height: 8 * scale),
                                ...dayItems.map(
                                  (it) => Padding(
                                    padding: EdgeInsets.only(bottom: 8 * scale),
                                    child: _InsightCard(
                                      message: it.message,
                                      scale: scale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Botão voltar fixo no canto superior esquerdo
          Positioned(
            left: 12 * scale,
            top: 8 * scale,
            child: const AppBackButton(),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String dayKey;
  final double scale;

  const _DayHeader({required this.dayKey, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6 * scale,
          height: 18 * scale,
          decoration: BoxDecoration(
            color: AppColors.baseBlue,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        SizedBox(width: 8 * scale),
        Text(
          dayKey,
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
            fontSize: 14 * scale,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String message;
  final double scale;

  const _InsightCard({required this.message, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 13 * scale,
          color: AppColors.darkText,
          height: 1.3,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String categoryKey;
  final String title;
  final double scale;

  const _CategoryChip({
    required this.categoryKey,
    required this.title,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        _cycleCategoryStyles[categoryKey] ??
        const _CycleCategoryStyle(
          background: AppColors.baseBlue,
          foreground: Colors.white,
          icon: Icons.info_outline,
        );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 6 * scale,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 16 * scale, color: style.foreground),
          SizedBox(width: 6 * scale),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * scale,
              color: style.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _CycleCategoryStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _CycleCategoryStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}

const Map<String, _CycleCategoryStyle> _cycleCategoryStyles = {
  'technical_alerts': _CycleCategoryStyle(
    background: Colors.red,
    foreground: Colors.white,
    icon: Icons.warning_amber_rounded,
  ),
  'positive_points': _CycleCategoryStyle(
    background: AppColors.baseBlue,
    foreground: Colors.white,
    icon: Icons.emoji_events_outlined,
  ),
  'smart_recommendations': _CycleCategoryStyle(
    background: AppColors.darkBlue,
    foreground: Colors.white,
    icon: Icons.lightbulb_outline,
  ),
  'cycle_comparison': _CycleCategoryStyle(
    background: AppColors.baseBlue,
    foreground: Colors.white,
    icon: Icons.compare_arrows_rounded,
  ),
};
