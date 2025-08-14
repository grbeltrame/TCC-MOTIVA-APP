import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/routes/app_routes.dart'; // <- ADICIONADO

class SectionBadgesSummary extends StatefulWidget {
  const SectionBadgesSummary({super.key});

  @override
  State<SectionBadgesSummary> createState() => _SectionBadgesSummaryState();
}

class _SectionBadgesSummaryState extends State<SectionBadgesSummary> {
  late Future<_BadgesVm> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BadgesVm> _load() async {
    final all = await GoalService.fetchUserGoals();

    // concluídas
    final completed =
        all.where((g) => g.status == GoalStatus.completed).toList();

    // total (número grande)
    final count = completed.length;

    // data de conclusão (mock) = startDate + deadlineWeeks*7
    DateTime achievedAtOf(Goal g) =>
        g.startDate.add(Duration(days: g.deadlineWeeks * 7));

    // ordenar do mais recente p/ o mais antigo
    completed.sort((a, b) => achievedAtOf(b).compareTo(achievedAtOf(a)));

    // pegar até 3
    final take3 =
        completed.take(3).map((g) {
          return _BadgeVm(
            asset: g.badgeAsset,
            shortTitle: _shortenTitle(g.title),
            achievedAt: achievedAtOf(g),
            isPlaceholder: false,
          );
        }).toList();

    // se tiver menos de 3, completa com placeholders esmaecidos
    while (take3.length < 3) {
      take3.add(
        _BadgeVm(
          asset:
              (all.isNotEmpty
                  ? all.first.badgeAsset
                  : 'assets/icons/goal1.png'),
          shortTitle: '—',
          achievedAt: DateTime(1970, 1, 1),
          isPlaceholder: true,
        ),
      );
    }

    return _BadgesVm(count: count, last3: take3);
  }

  Future<void> _goToAllBadges(BuildContext context) async {
    try {
      await Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamed(AppRoutes.athleteAllGoals);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tela de metas ainda não disponível.')),
      );
    }
  }

  static String _shortenTitle(String title, {int maxWords = 3}) {
    final words = title.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return title;
    return words.take(maxWords).join(' ');
  }

  String _fmtDate(DateTime d) {
    if (d.year <= 1970) return '—/—/—';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<_BadgesVm>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Container(
            padding: EdgeInsets.all(16 * scale),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16 * scale),
              border: Border.all(color: AppColors.mediumGray),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!;

        // === Alteração: envolvemos o card em uma Column e adicionamos o botão fora dele, à direita ===
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // CARD
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 12 * scale,
                horizontal: 12 * scale,
              ),
              margin: EdgeInsets.symmetric(horizontal: 12 * scale),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16 * scale),
                border: Border.all(color: AppColors.mediumGray),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // número grande
                  Text(
                    '${data.count}',
                    style: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 32 * scale,
                      color: AppColors.baseBlue,
                    ),
                  ),
                  // texto fixo
                  Text(
                    'Selos Conquistados',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 20 * scale,
                      color: AppColors.baseBlue,
                    ),
                  ),
                  SizedBox(height: 12 * scale),

                  // linha com exatamente 3 selos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        data.last3.map((b) {
                          final alpha = b.isPlaceholder ? 0.35 : 1.0;
                          return SizedBox(
                            width: 90 * scale,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Opacity(
                                  opacity: alpha,
                                  child: Image.asset(
                                    b.asset,
                                    width: 56 * scale,
                                    height: 56 * scale,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                SizedBox(height: 6 * scale),
                                Text(
                                  b.shortTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: 12 * scale,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                Text(
                                  _fmtDate(b.achievedAt),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontWeight: AppFontWeight.regular,
                                    fontSize: 10 * scale,
                                    color: AppColors.mediumGray.withValues(
                                      alpha: alpha,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),

            // espaço entre card e botão
            SizedBox(height: 8 * scale),

            // BOTÃO fora do card, à direita (mesma margem horizontal do card)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * scale),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * scale,
                      vertical: 4 * scale,
                    ),
                    foregroundColor: AppColors.baseBlue,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 0),
                  ),
                  onPressed: () => _goToAllBadges(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Veja todas',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 14 * scale,
                        ),
                      ),
                      SizedBox(width: 4 * scale),
                      Icon(Icons.chevron_right, size: 18 * scale),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 32 * scale),
          ],
        );
      },
    );
  }
}

class _BadgesVm {
  final int count;
  final List<_BadgeVm> last3;
  _BadgesVm({required this.count, required this.last3});
}

class _BadgeVm {
  final String asset;
  final String shortTitle;
  final DateTime achievedAt;
  final bool isPlaceholder;
  _BadgeVm({
    required this.asset,
    required this.shortTitle,
    required this.achievedAt,
    required this.isPlaceholder,
  });
}
