// lib/features/user/athlete/athlete_pre_workout_insights_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_insights_service.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

/// Detalhe dos insights pré-treino — espelha o padrão da tela de
/// insights da semana, mas listando os 5 itens gerados para um treino
/// específico.
///
/// Argumentos da rota: { 'workoutId': String }
class AthletePreWorkoutInsightsDetailScreen extends StatefulWidget {
  static const routeName = '/athlete_pre_workout_insights_detail';
  const AthletePreWorkoutInsightsDetailScreen({Key? key}) : super(key: key);

  @override
  State<AthletePreWorkoutInsightsDetailScreen> createState() =>
      _AthletePreWorkoutInsightsDetailScreenState();
}

class _AthletePreWorkoutInsightsDetailScreenState
    extends State<AthletePreWorkoutInsightsDetailScreen> {
  late Future<AthletePreWorkoutInsights?> _future;
  bool _bootstrapped = false;
  String? _workoutId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _workoutId = args['workoutId'] as String?;
    _future = _workoutId != null
        ? AthleteInsightsService.fetchPreWorkout(_workoutId!)
        : Future.value(null);
    _bootstrapped = true;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(showSystemBack: true),
      body: FutureBuilder<AthletePreWorkoutInsights?>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data;
          if (data == null || data.isEmpty) return _empty(scale);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              vertical: 16 * scale,
              horizontal: 16 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Insights do Treino',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 2 * scale),
                Text(
                  data.hasPattern
                      ? 'Baseado em ${data.historySize} treinos seus do mesmo tipo'
                      : 'Histórico ainda curto neste tipo de treino',
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 16 * scale),

                if (data.alertas.isNotEmpty) ...[
                  _sectionTitle('Atenção', scale),
                  SizedBox(height: 8 * scale),
                  ...data.alertas.values.map(
                    (m) => _InsightTile(
                      message: m,
                      kind: InsightKind.alert,
                      scale: scale,
                    ),
                  ),
                  SizedBox(height: 16 * scale),
                ],

                if (data.informacoes.isNotEmpty) ...[
                  _sectionTitle('Pontos a favor', scale),
                  SizedBox(height: 8 * scale),
                  ...data.informacoes.values.map(
                    (m) => _InsightTile(
                      message: m,
                      kind: InsightKind.info,
                      scale: scale,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String txt, double scale) => Text(
        txt,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: FontWeight.bold,
          fontSize: 15 * scale,
          color: AppColors.darkText,
        ),
      );

  Widget _empty(double scale) => Center(
        child: Padding(
          padding: EdgeInsets.all(24 * scale),
          child: Text(
            'Ainda não há insights pré-treino para este treino.\n'
            'Eles aparecem assim que o coach publica e seu histórico é processado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 14 * scale,
              color: AppColors.mediumGray,
            ),
          ),
        ),
      );
}

class _InsightTile extends StatelessWidget {
  final String message;
  final InsightKind kind;
  final double scale;
  const _InsightTile({
    required this.message,
    required this.kind,
    required this.scale,
  });

  static const _alertBg = Color(0xFFFFF6D6);
  static const _alertBorder = Color(0xFFE7B400);
  static const _alertText = Color(0xFF5C4300);

  @override
  Widget build(BuildContext context) {
    final isAlert = kind == InsightKind.alert;
    final bg = isAlert ? _alertBg : Colors.white;
    final border = isAlert ? _alertBorder : AppColors.baseBlue;
    final iconColor = isAlert ? _alertBorder : AppColors.baseBlue;
    final textColor = isAlert ? _alertText : AppColors.darkText;
    final icon =
        isAlert ? Icons.warning_amber_rounded : Icons.lightbulb_outline;

    return Container(
      margin: EdgeInsets.only(bottom: 8 * scale),
      padding: EdgeInsets.symmetric(
        vertical: 10 * scale,
        horizontal: 12 * scale,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22 * scale, color: iconColor),
          SizedBox(width: 10 * scale),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.w500,
                fontSize: 13 * scale,
                color: textColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
