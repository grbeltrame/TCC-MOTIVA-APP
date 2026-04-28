// lib/shared/widgets/sections/athlete/pre_workout_insights_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/features/user/athlete/athlete_pre_workout_insights_detail_screen.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/athlete_insights_carousel_loader.dart';

/// Cabeçalho + carrossel de insights pré-treino para o treino do dia.
/// Resolve o `workoutId` via [date] e exibe o carrossel + link "Ver todos"
/// que navega para a tela de detalhe.
///
/// Foco no atleta naquele tipo de treino (histórico, horário ótimo,
/// PRs recentes, estado atual) — nunca opina sobre a montagem do treino.
///
/// Se não houver treino publicado para a data ou o atleta ainda não tem
/// insights gerados, a seção fica oculta (não mostra título sozinho).
class PreWorkoutInsightsSection extends StatefulWidget {
  /// Data do treino para resolver o workoutId.
  /// Default: hoje.
  final DateTime? date;

  const PreWorkoutInsightsSection({Key? key, this.date}) : super(key: key);

  @override
  State<PreWorkoutInsightsSection> createState() =>
      _PreWorkoutInsightsSectionState();
}

class _PreWorkoutInsightsSectionState extends State<PreWorkoutInsightsSection> {
  String? _workoutId;
  bool _resolving = true;
  DateTime? _resolvedFor;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(PreWorkoutInsightsSection old) {
    super.didUpdateWidget(old);
    if (old.date != widget.date) _resolve();
  }

  Future<void> _resolve() async {
    final target = widget.date ?? DateTime.now();
    setState(() {
      _resolving = true;
      _resolvedFor = target;
    });
    final id = await TrainingService.fetchWorkoutIdForDate(target);
    if (!mounted) return;
    // Evita race se o usuário trocar a data enquanto a query roda.
    if (_resolvedFor != target) return;
    setState(() {
      _workoutId = id;
      _resolving = false;
    });
  }

  void _openDetail() {
    if (_workoutId == null) return;
    Navigator.pushNamed(
      context,
      AthletePreWorkoutInsightsDetailScreen.routeName,
      arguments: {'workoutId': _workoutId},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving || _workoutId == null) return const SizedBox.shrink();

    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Insights do Treino',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.bold,
                  fontSize: 13 * scale,
                  color: AppColors.darkText,
                ),
              ),
              InkWell(
                onTap: _openDetail,
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
        ),
        SizedBox(height: 4 * scale),
        AthleteInsightsCarouselLoader(
          mode: AthleteInsightsMode.preWorkoutOnly,
          workoutId: _workoutId,
          onTap: _openDetail,
        ),
      ],
    );
  }
}
