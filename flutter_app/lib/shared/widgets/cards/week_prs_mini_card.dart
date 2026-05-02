// lib/shared/widgets/cards/week_prs_mini_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_prs_service.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart';
import 'package:flutter_app/shared/widgets/cards/week_prs_card.dart';

/// Card compacto de PRs.
///
/// Padrão visual alinhado a [WeekEffortCard] e [WeekPointsCard] para que os
/// três fiquem lado a lado em uma única grade. Mostra contagem de PRs da
/// semana e abre, ao toque, um bottom sheet com a experiência completa
/// (registrar / editar / apagar) preservada do [WeekPRsCard].
class WeekPrsMiniCard extends StatefulWidget {
  const WeekPrsMiniCard({Key? key}) : super(key: key);

  @override
  State<WeekPrsMiniCard> createState() => _WeekPrsMiniCardState();
}

class _WeekPrsMiniCardState extends State<WeekPrsMiniCard> {
  late Future<List<AthletePr>> _prsFut;

  @override
  void initState() {
    super.initState();
    _prsFut = _fetch();
  }

  Future<List<AthletePr>> _fetch() {
    final range = WeeklySummaryService().fetchCurrentWeekRange();
    return AthletePrsService.fetchWeekPrs(
      weekStart: range.start,
      weekEnd: range.end,
    );
  }

  Future<void> _openSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PrsBottomSheet(),
    );
    if (!mounted) return;
    final next = _fetch();
    setState(() {
      _prsFut = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 3 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      elevation: 0,
      child: InkWell(
        onTap: _openSheet,
        borderRadius: BorderRadius.circular(14 * scale),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12 * scale,
            10 * scale,
            8 * scale,
            11 * scale,
          ),
          child: FutureBuilder<List<AthletePr>>(
            future: _prsFut,
            builder: (context, snap) {
              final loading = snap.connectionState == ConnectionState.waiting;
              final count = (snap.data ?? const []).length;
              final hasData = count > 0;
              final color =
                  hasData ? AppColors.baseBlue : AppColors.mediumGray;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + ícone de "abrir"
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'PRS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: FontWeight.bold,
                            fontSize: 10 * scale,
                            color: AppColors.darkBlue,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(2 * scale),
                        child: Icon(
                          Icons.add_circle_outline,
                          size: 16 * scale,
                          color: AppColors.baseBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6 * scale),

                  // Número grande
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        loading ? '…' : count.toString(),
                        style: TextStyle(
                          fontFamily: AppFonts.montserrat,
                          fontWeight: FontWeight.bold,
                          fontSize: 26 * scale,
                          color: color,
                          height: 1,
                        ),
                      ),
                      if (!loading)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: 4 * scale,
                            left: 3 * scale,
                          ),
                          child: Text(
                            count == 1 ? 'PR' : 'PRs',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontSize: 12 * scale,
                              color: AppColors.mediumGray,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Chamado de ação
                  Text(
                    'Toque para cadastrar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 10.5 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PrsBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20 * scale),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8 * scale),
              Container(
                width: 40 * scale,
                height: 4 * scale,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(2 * scale),
                ),
              ),
              SizedBox(height: 8 * scale),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                child: Row(
                  children: [
                    Text(
                      'PRs da semana',
                      style: TextStyle(
                        fontFamily: AppFonts.montserrat,
                        fontWeight: FontWeight.bold,
                        fontSize: 16 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20 * scale,
                        color: AppColors.mediumGray,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    12 * scale,
                    4 * scale,
                    12 * scale,
                    24 * scale,
                  ),
                  child: const WeekPRsCard(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
