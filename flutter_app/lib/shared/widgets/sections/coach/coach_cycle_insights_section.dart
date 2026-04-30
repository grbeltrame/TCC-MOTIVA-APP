import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/users/coach/daily_insights_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/coach_cycle_insights.dart';
import 'package:flutter_app/shared/widgets/utils/month_selector.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';

/// Section principal da tela de "Insights do Ciclo".
/// - Permite escolher o mês (MonthSelector).
/// - Carrega insights do ciclo via CoachDailyInsightsService (mock).
/// - Exibe categorias empilhadas, cada uma com tópicos e carrossel de textos.
class CoachCycleInsightsSection extends StatefulWidget {
  final String boxId;

  /// Mês inicial (se vier de outra tela). Usa apenas ano/mês.
  final DateTime? initialMonth;

  const CoachCycleInsightsSection({
    super.key,
    required this.boxId,
    this.initialMonth,
  });

  @override
  State<CoachCycleInsightsSection> createState() =>
      _CoachCycleInsightsSectionState();
}

class _CoachCycleInsightsSectionState extends State<CoachCycleInsightsSection> {
  late DateTime _month;
  late Future<CoachCycleOverviewInsights> _future;
  final _service = CoachDailyInsightsService();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initial = widget.initialMonth ?? DateTime(now.year, now.month);
    _month = _safeMonth(initial);
    _future = _service.fetchCycleOverviewInsights(
      boxId: widget.boxId,
      month: _month,
    );
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      _month = _safeMonth(newMonth);
      _future = _service.fetchCycleOverviewInsights(
        boxId: widget.boxId,
        month: _month,
      );
    });
  }

  DateTime _safeMonth(DateTime date) {
    final now = DateTime.now();
    final normalized = DateTime(date.year, date.month);
    if (normalized.year < 2020 || normalized.year > now.year + 2) {
      return DateTime(now.year, now.month);
    }
    return normalized;
  }

  String _formatMonthLabel(DateTime m) {
    // Ex.: "Abril de 2025"
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
    final name = months[m.month - 1];
    return '$name de ${m.year}';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título da página/section
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Text(
            'Análise do ciclo',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        SizedBox(height: 8 * scale),

        // Subtítulo com mês atual
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Text(
            _formatMonthLabel(_month),
            style: TextStyle(
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
              fontFamily: AppFonts.roboto,
            ),
          ),
        ),
        SizedBox(height: 8 * scale),

        // MonthSelector em estilo similar ao DateSelector
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: MonthSelector(
            initialMonth: _month,
            onMonthChanged: _onMonthChanged,
          ),
        ),
        SizedBox(height: 12 * scale),

        FutureBuilder<CoachCycleOverviewInsights>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 160 * scale,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data;
            if (data == null || data.categories.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                child: Text(
                  'Nenhuma análise disponível para o ciclo selecionado.',
                  style: TextStyle(
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                    fontFamily: AppFonts.roboto,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [..._buildCategories(context, data, scale)],
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildCategories(
    BuildContext context,
    CoachCycleOverviewInsights overview,
    double scale,
  ) {
    final children = <Widget>[];

    for (var i = 0; i < overview.categories.length; i++) {
      final cat = overview.categories[i];
      if (i > 0) {
        children.add(SizedBox(height: 16 * scale));
      }
      children.add(
        _CycleCategorySection(
          category: cat,
          boxId: widget.boxId,
          month: _month,
          scale: scale,
        ),
      );
    }

    return children;
  }
}

// ---------- Categoria inteira (chip + tópicos) ----------

class _CycleCategorySection extends StatelessWidget {
  final CoachCycleCategoryInsights category;
  final String boxId;
  final DateTime month;
  final double scale;

  const _CycleCategorySection({
    required this.category,
    required this.boxId,
    required this.month,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        _cycleCategoryStyles[category.key] ??
        const _CycleCategoryStyle(
          background: AppColors.baseBlue,
          foreground: Colors.white,
          icon: Icons.info_outline,
        );

    return Container(
      padding: EdgeInsets.all(10 * scale),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chip da categoria
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * scale,
              vertical: 4 * scale,
            ),
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(20 * scale),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, size: 14 * scale, color: style.foreground),
                SizedBox(width: 4 * scale),
                Text(
                  category.title,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 12 * scale,
                    color: style.foreground,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8 * scale),

          // Tópicos
          ..._buildTopics(context),
        ],
      ),
    );
  }

  List<Widget> _buildTopics(BuildContext context) {
    final items = <Widget>[];

    for (var i = 0; i < category.topics.length; i++) {
      final topic = category.topics[i];

      if (i > 0) {
        items.add(
          Divider(height: 16 * scale, thickness: 1, color: AppColors.lightGray),
        );
      }

      items.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    topic.title,
                    style: TextStyle(
                      fontSize: 11 * scale,
                      color: AppColors.darkText,
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
                TextActionButton(
                  text: 'Ver todos',
                  icon: Icons.add,
                  color: AppColors.baseBlue,
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.coachCycleInsightTopicDetail,
                      arguments: {
                        'boxId': boxId,
                        'month': month,
                        'categoryKey': category.key,
                        'categoryTitle': category.title,
                        'topicKey': topic.key,
                        'topicTitle': topic.title,
                      },
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 4 * scale),

            _TopicCarousel(messages: topic.messages, scale: scale),
          ],
        ),
      );
    }

    return items;
  }
}

// ---------- Estilo por categoria ----------

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

// ---------- Carrossel de textos por tópico (setas + altura adaptável) ----------

class _TopicCarousel extends StatefulWidget {
  final List<String> messages;
  final double scale;

  const _TopicCarousel({required this.messages, required this.scale});

  @override
  State<_TopicCarousel> createState() => _TopicCarouselState();
}

class _TopicCarouselState extends State<_TopicCarousel>
    with TickerProviderStateMixin {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final msgs = widget.messages;
    final scale = widget.scale;

    if (msgs.isEmpty) {
      return Text(
        'Nenhuma análise disponível.',
        style: TextStyle(
          fontSize: 12 * scale,
          color: AppColors.mediumGray,
          fontFamily: AppFonts.roboto,
        ),
      );
    }

    final current = msgs[_index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Conteúdo com altura adaptável
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(8 * scale),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8 * scale),
              color: Colors.white.withValues(alpha: 0.02),
            ),
            child: Text(
              current,
              style: TextStyle(
                fontSize: 12 * scale,
                color: AppColors.darkText,
                fontFamily: AppFonts.roboto,
              ),
            ),
          ),
        ),
        SizedBox(height: 4 * scale),

        if (msgs.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: 28 * scale,
                  height: 28 * scale,
                ),
                icon: Icon(
                  Icons.navigate_before,
                  size: 22 * scale,
                  color: _index > 0 ? AppColors.baseBlue : AppColors.mediumGray,
                ),
                onPressed:
                    _index > 0
                        ? () {
                          setState(() {
                            _index--;
                          });
                        }
                        : null,
              ),
              Text(
                '${_index + 1}/${msgs.length}',
                style: TextStyle(
                  fontSize: 11 * scale,
                  color: AppColors.mediumGray,
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: BoxConstraints.tightFor(
                  width: 28 * scale,
                  height: 28 * scale,
                ),
                icon: Icon(
                  Icons.navigate_next,
                  size: 22 * scale,
                  color:
                      _index < msgs.length - 1
                          ? AppColors.baseBlue
                          : AppColors.mediumGray,
                ),
                onPressed:
                    _index < msgs.length - 1
                        ? () {
                          setState(() {
                            _index++;
                          });
                        }
                        : null,
              ),
            ],
          ),
      ],
    );
  }
}
