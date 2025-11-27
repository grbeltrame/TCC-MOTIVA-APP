import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';

/// Section: "Últimos Ciclos"
/// - Mostra título + action "Ver todos os ciclos"
/// - 3 cards com os meses MAIS RECENTES (mock do TrainingService)
/// - Sem navegação por enquanto (cards são InkWell sem onTap real)
class CoachRecentCyclesSection extends StatefulWidget {
  final String boxId;
  final VoidCallback? onSeeAll; // manter preparado para o futuro

  const CoachRecentCyclesSection({
    super.key,
    required this.boxId,
    this.onSeeAll,
  });

  @override
  State<CoachRecentCyclesSection> createState() =>
      _CoachRecentCyclesSectionState();
}

class _CoachRecentCyclesSectionState extends State<CoachRecentCyclesSection> {
  late Future<List<DateTime>> _future;

  @override
  void initState() {
    super.initState();
    _future = CycleMonths.fetchRecentCycleMonths(boxId: widget.boxId);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título + botão
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Últimos Ciclos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextActionButton(
                text: 'Ver todos os ciclos',
                icon: Icons.add,
                color: AppColors.baseBlue,
                onPressed:
                    widget.onSeeAll ?? () {}, // por enquanto pode ser null
              ),
            ],
          ),
        ),
        SizedBox(height: 8 * scale),

        FutureBuilder<List<DateTime>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                height: 44 * scale,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            final months = snap.data ?? const [];
            if (months.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                child: Text(
                  'Nenhum ciclo disponível.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              );
            }

            // Garante 3 mais recentes (caso service mude)
            final top3 = months.take(3).toList();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Row(
                children: List.generate(top3.length, (i) {
                  final month = top3[i];
                  final label = CycleMonths.formatCycleMonthLabel(month);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < top3.length - 1 ? 8 * scale : 0,
                      ),
                      child: _CycleCard(label: label, scale: scale),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CycleCard extends StatelessWidget {
  final String label;
  final double scale;

  const _CycleCard({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: null, // sem navegação por enquanto
      borderRadius: BorderRadius.circular(8 * scale),
      child: Container(
        height: 36 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(color: AppColors.baseBlue, width: 1),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.bold,
            fontSize: 12 * scale,
            color: AppColors.baseBlue,
          ),
        ),
      ),
    );
  }
}
