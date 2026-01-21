import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/training.dart'; // DailyWorkoutSummary

/*
  Card “Treino de hoje” (professor)
  - Dropdown sem container (texto azul + seta)
  - “Estímulo do dia:” (cinza, bold) + valências separadas por “ + ”
  - “Objetivo:” (cinza) + objetivo
  - Divisor sutil
  - Dois botões com ícones (sem outline)
  - Borda azul arredondada no card
*/

class CoachTodayWorkoutCard extends StatefulWidget {
  final String boxId;
  final DateTime date;

  const CoachTodayWorkoutCard({
    super.key,
    required this.boxId,
    required this.date,
  });

  @override
  State<CoachTodayWorkoutCard> createState() => _CoachTodayWorkoutCardState();
}

class _CoachTodayWorkoutCardState extends State<CoachTodayWorkoutCard> {
  // Futuro “blindado”: sempre vira Future<List<String>> independente do que o Service retornar.
  late final Future<List<String>> _futCategories;

  String? _selectedCategoryLabel;
  Future<DailyWorkoutSummary?>? _futSummaryForSelected;

  // Cores/estilo
  static const Color kBlue = Color(0xFF224DFF);
  static const Color kBlueBorder = Color(0xFF224DFF);
  static const Color kGreyTitle = Color(0xFF8A8A8E);
  static const Color kGreyBody = Color(0xFF666666);
  static const double kRadius = 12;

  @override
  void initState() {
    super.initState();
    _futCategories = _loadCategoriesAsList();

    _futCategories.then((labels) {
      if (!mounted) return;
      final defaultLabel =
          labels.contains('WOD')
              ? 'WOD'
              : (labels.isNotEmpty ? labels.first : null);

      setState(() {
        _selectedCategoryLabel = defaultLabel;
        if (defaultLabel != null) {
          _futSummaryForSelected = _loadSummaryFor(defaultLabel);
        }
      });
    });
  }

  /// Converte a resposta do service (List<String> OU Map<String,String> OU outros)
  /// para uma List<String> consistente para o dropdown.
  Future<List<String>> _loadCategoriesAsList() async {
    // Chama o helper; se ele retornar Map, List, etc., normalizamos.
    final dynamic raw =
        await TodayWorkoutHelpers.fetchAvailableCategoriesForDate(
          boxId: widget.boxId,
          date: widget.date,
        );

    if (raw is List<String>) return raw;
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is Map<String, String>) return raw.keys.toList();
    if (raw is Map) return raw.keys.map((e) => e.toString()).toList();

    return <String>[];
  }

  Future<DailyWorkoutSummary?> _loadSummaryFor(String category) {
    // Mantém o helper existente; ele já normaliza “Ginástica”/“Ginastica”.
    return TodayWorkoutHelpers.fetchDailyWorkoutSummaryByCategory(
      boxId: widget.boxId,
      date: widget.date,
      category: category,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBlueBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kBlue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== DROPDOWN (sem container de fundo) =====
          FutureBuilder<List<String>>(
            future: _futCategories,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.connectionState == ConnectionState.active) {
                return Row(
                  children: [
                    Text(
                      'Carregando…',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.baseBlue,
                        fontSize: 18 * scale,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Falha ao carregar treinos do dia',
                  style: textTheme.bodyMedium?.copyWith(color: kGreyBody),
                );
              }

              final labels = snapshot.data ?? const <String>[];
              if (labels.isEmpty) {
                return Text(
                  'Nenhum treino disponível hoje',
                  style: textTheme.bodyMedium?.copyWith(color: kGreyBody),
                );
              }

              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategoryLabel,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: kBlue,
                    size: 20,
                  ),
                  isDense: true,
                  style: textTheme.titleMedium?.copyWith(
                    color: kBlue,
                    fontWeight: FontWeight.w700,
                  ),
                  items:
                      labels
                          .map(
                            (label) => DropdownMenuItem<String>(
                              value: label,
                              child: Text(
                                label,
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.baseBlue,
                                  fontSize: 18 * scale,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selectedCategoryLabel = val;
                      _futSummaryForSelected = _loadSummaryFor(val);
                    });
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ===== CONTEÚDO: Estímulo + Objetivo =====
          FutureBuilder<DailyWorkoutSummary?>(
            future: _futSummaryForSelected,
            builder: (context, snapshot) {
              if (_selectedCategoryLabel == null ||
                  snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.connectionState == ConnectionState.active) {
                return _skeletonContent(textTheme);
              }

              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stimulusRow(textTheme, '—'),
                    const SizedBox(height: 8),
                    Text(
                      'Não foi possível carregar o objetivo.',
                      style: textTheme.bodyMedium?.copyWith(color: kGreyBody),
                    ),
                    const SizedBox(height: 10),
                    Divider(
                      color: Colors.black.withValues(alpha: 0.12),
                      height: 16,
                    ),
                    const SizedBox(height: 6),
                    _buttonsRow(textTheme),
                  ],
                );
              }

              final summary = snapshot.data;
              final stimulusText = (summary?.stimuli ?? const <String>[])
                  .where((s) => s.trim().isNotEmpty)
                  .join(' + ');
              final objective = summary?.objectiveShort ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _stimulusRow(
                    textTheme,
                    stimulusText.isEmpty ? '—' : stimulusText,
                  ),
                  const SizedBox(height: 8),
                  _objectiveRow(textTheme, objective.isEmpty ? '—' : objective),
                  const SizedBox(height: 10),
                  Divider(
                    color: Colors.black.withValues(alpha: 0.12),
                    height: 16,
                  ),
                  const SizedBox(height: 6),
                  _buttonsRow(textTheme),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===== UI helpers =====

  Widget _skeletonContent(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stimulusRow(textTheme, '—'),
        const SizedBox(height: 8),
        _objectiveRow(textTheme, '—'),
        const SizedBox(height: 10),
        Divider(color: Colors.black.withValues(alpha: 0.12), height: 16),
        const SizedBox(height: 6),
        _buttonsRow(textTheme),
      ],
    );
  }

  Widget _stimulusRow(TextTheme textTheme, String value) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375.0;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Estímulo do dia: ',
            style: textTheme.titleMedium?.copyWith(
              color: AppColors.mediumGray,
              fontSize: 16 * scale,
              fontWeight: AppFontWeight.medium,
            ),
          ),
          TextSpan(
            text: value,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 16 * scale,
              color: AppColors.mediumGray,
              fontWeight: AppFontWeight.regular,
            ),
          ),
        ],
      ),
    );
  }

  Widget _objectiveRow(TextTheme textTheme, String value) {
    final width = MediaQuery.of(context).size.width;
    final scale = width / 375.0;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Objetivo: ',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.mediumGray,
              fontSize: 12 * scale,
              fontWeight: AppFontWeight.medium,
            ),
          ),
          TextSpan(
            text: value,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.mediumGray,
              fontSize: 12 * scale,
              fontWeight: AppFontWeight.regular,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttonsRow(TextTheme textTheme) {
    return Row(
      children: [
        _flatIconButton(
          icon: Icons.add,
          label: 'Ver treino',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.coachTrainings);
          },
        ),
        const SizedBox(width: 12),
        _flatIconButton(
          icon: Icons.bar_chart,
          label: 'Análise do Ciclo',
          onTap: () {
            Navigator.pushNamed(context, AppRoutes.coachEvolutions);
          },
        ),
      ],
    );
  }

  Widget _flatIconButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: kBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: kBlue, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
