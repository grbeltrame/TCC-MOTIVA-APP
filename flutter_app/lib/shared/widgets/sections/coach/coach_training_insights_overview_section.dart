import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/shared/widgets/carousels/adaptative_insights_carousel.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:intl/intl.dart';

class CoachTrainingInsightsOverviewSection extends StatelessWidget {
  final Training? training;

  const CoachTrainingInsightsOverviewSection({
    super.key,
    required this.training,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    if (training == null || training!.analysis == null) {
      return Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48 * scale,
                color: AppColors.mediumGray,
              ),
              SizedBox(height: 8 * scale),
              Text(
                "Nenhuma análise disponível para este treino.",
                style: TextStyle(
                  color: AppColors.mediumGray,
                  fontSize: 14 * scale,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final analysis = training!.analysis!;
    final buckets = _generateBucketsFromAnalysis(analysis);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Insights do Treino',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextActionButton(
                text: 'Ver Insights do Ciclo',
                icon: Icons.add,
                fontSize: 10 * scale,
                color: AppColors.baseBlue,
                onPressed: () {
                  final now = DateTime.now();
                  final currentMonth = DateTime(now.year, now.month);
                  Navigator.pushNamed(
                    context,
                    AppRoutes.coachTrainingInsights,
                    arguments: {'month': currentMonth},
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * scale),
        Container(
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
                      DateFormat(
                        "EEEE, d 'de' MMMM",
                        'pt_BR',
                      ).format(training!.date).toUpperCase(),
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
              SizedBox(height: 12 * scale),
              ..._buildBucketWidgets(context, buckets, scale, training!.date),
              SizedBox(height: 12 * scale),
              // Row(
              //   children: [
              //     Expanded(
              //       child: ElevatedButton.icon(
              //         onPressed: () {
              //           Navigator.pop(context);
              //         },
              //         icon: Icon(Icons.arrow_back, size: 16 * scale),
              //         label: const Text('Voltar ao Treino'),
              //         style: ElevatedButton.styleFrom(
              //           backgroundColor: AppColors.baseBlue,
              //           foregroundColor: Colors.white,
              //           padding: EdgeInsets.symmetric(vertical: 8 * scale),
              //           shape: RoundedRectangleBorder(
              //             borderRadius: BorderRadius.circular(20 * scale),
              //           ),
              //           textStyle: TextStyle(
              //             fontSize: 12 * scale,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ),
      ],
    );
  }

  // --- AQUI ESTÁ A MÁGICA (Lógica alterada) ---

  List<_BucketData> _generateBucketsFromAnalysis(TrainingAnalysis analysis) {
    final List<_BucketData> buckets = [];

    // 1. Visão Geral + Focos (Juntos no mesmo card)
    if (analysis.overview.isNotEmpty) {
      String fullContent = analysis.overview;

      // Se tiver focos, adicionamos duas quebras de linha e formatamos bonitinho
      if (analysis.keyMetrics.isNotEmpty) {
        // Junta os focos com uma bolinha separadora
        final focosString = analysis.keyMetrics.join("  •  ");
        fullContent += "\n\n🎯 FOCO PRINCIPAL:\n$focosString";
      }

      buckets.add(
        _BucketData(
          key: 'analysis',
          title: 'VISÃO GERAL',
          // Agora mandamos apenas UMA mensagem contendo tudo
          messages: [fullContent],
        ),
      );
    }

    // 2. Alertas (Formatando Título)
    if (analysis.alerts.isNotEmpty) {
      final List<String> formattedAlerts = [];

      analysis.alerts.forEach((key, message) {
        // Formata a chave: "risco_ombro" -> "Risco Ombro"
        final title = _formatAlertTitle(key);
        // Cria uma string combinada
        formattedAlerts.add("$title\n$message");
      });

      buckets.add(
        _BucketData(
          key: 'alerts',
          title: 'ALERTAS & RISCOS',
          messages: formattedAlerts,
        ),
      );
    }

    // 3. Sugestões
    if (analysis.insights.isNotEmpty) {
      buckets.add(
        _BucketData(
          key: 'suggestions',
          title: 'DICAS TÉCNICAS',
          messages: analysis.insights.values.toList(),
        ),
      );
    }

    return buckets;
  }

  /// Auxiliar para transformar "risco_fadiga_extrema" em "Risco Fadiga Extrema"
  String _formatAlertTitle(String key) {
    if (key.isEmpty) return "";
    // Troca _ por espaço
    final noUnderscore = key.replaceAll('_', ' ');
    // Capitaliza a primeira letra
    return "${noUnderscore[0].toUpperCase()}${noUnderscore.substring(1)}";
  }

  List<Widget> _buildBucketWidgets(
    BuildContext context,
    List<_BucketData> buckets,
    double scale,
    DateTime trainingDate,
  ) {
    final children = <Widget>[];

    for (var i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      if (i > 0) {
        children.add(
          Divider(height: 24 * scale, thickness: 1, color: AppColors.lightGray),
        );
      }
      children.add(
        _BucketInsightsWidget(
          bucket: bucket,
          scale: scale,
          onViewAll: () {
            Navigator.pushNamed(
              context,
              AppRoutes.coachCycleInsightTopicDetail,
              arguments: {
                'categoryKey': bucket.key,
                'categoryTitle': bucket.title,
                'topicTitle': _detailTitleForBucket(bucket.key),
                'staticDate': trainingDate,
                'staticMessages': bucket.messages,
              },
            );
          },
        ),
      );
    }
    return children;
  }

  String _detailTitleForBucket(String bucketKey) {
    switch (bucketKey) {
      case 'analysis':
        return 'Visão Geral Completa';
      case 'alerts':
        return 'Todos os Alertas';
      case 'suggestions':
        return 'Todas as Dicas';
      default:
        return 'Todos os Insights';
    }
  }
}

// --- CLASSES PRIVADAS (Mantidas iguais) ---

class _BucketData {
  final String key;
  final String title;
  final List<String> messages;

  _BucketData({required this.key, required this.title, required this.messages});
}

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
  'suggestions': _BucketStyle(
    background: AppColors.mediumGray,
    foreground: Colors.white,
    icon: Icons.lightbulb_outline,
  ),
};

class _BucketInsightsWidget extends StatelessWidget {
  final _BucketData bucket;
  final double scale;
  final VoidCallback onViewAll;

  const _BucketInsightsWidget({
    required this.bucket,
    required this.scale,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        _bucketStyles[bucket.key] ??
        const _BucketStyle(
          background: AppColors.baseBlue,
          foreground: Colors.white,
          icon: Icons.info_outline,
        );

    return AdaptiveInsightsCarousel(
      title: bucket.title,
      icon: style.icon,
      pillColor: style.background,
      pillTextColor: style.foreground,
      messages: bucket.messages,
      onViewAll: onViewAll,
    );
  }
}
