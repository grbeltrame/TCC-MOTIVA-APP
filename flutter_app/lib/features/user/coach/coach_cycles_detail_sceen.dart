// lib/features/user/coach/coach_cycle_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/mini_card_service.dart';
import 'package:flutter_app/core/services/workout/cycle_service.dart';
import 'package:flutter_app/shared/charts/cycle_stimulus_pie_chart.dart';
import 'package:flutter_app/shared/widgets/cards/mini_card_widget.dart';
import 'package:flutter_app/shared/widgets/carousels/alerts_carousel.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/cycle_models.dart';

import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

import 'package:flutter_app/shared/widgets/cards/cycle_training_type_card.dart';

class CoachCycleDetailScreen extends StatefulWidget {
  static const routeName = '/coach_cycle_detail';
  const CoachCycleDetailScreen({Key? key}) : super(key: key);

  @override
  State<CoachCycleDetailScreen> createState() => _CoachCycleDetailScreenState();
}

class _CoachCycleDetailScreenState extends State<CoachCycleDetailScreen> {
  bool _bootstrapped = false;
  late int _year;
  late int _month; // 1-12
  late String _boxId;

  late Future<CycleDetailBundle> _bundleFut;

  DateTime _lastFetchedAt = DateTime.now();
  static const Duration _refreshInterval = Duration(hours: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};
    _year = (args['year'] ?? DateTime.now().year) as int;
    _month = (args['month'] ?? DateTime.now().month) as int;

    // TODO(back): trocar pelo boxId real vindo do contexto/auth
    _boxId = (args['boxId'] ?? '1') as String;

    _bundleFut = _fetch();
    _scheduleRefresh();

    _bootstrapped = true;
  }

  Future<CycleDetailBundle> _fetch() async {
    final b = await CycleService.fetchCycleDetail(
      boxId: _boxId,
      year: _year,
      month: _month,
    );
    _lastFetchedAt = DateTime.now();
    return b;
  }

  void _scheduleRefresh() {
    Future.delayed(_refreshInterval, () async {
      if (!mounted) return;
      setState(() {
        _bundleFut = _fetch();
      });
      _scheduleRefresh();
    });
  }

  void _openRegisterBoxSheet() {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  String _titleMonth() {
    final m = CycleService.monthTitlePtBR(_month);
    return 'Mensal - $m';
  }

  String _formatUpdatedAt(DateTime d) {
    final date = DateFormat('dd/MM/yyyy', 'pt_BR').format(d);
    final hour = DateFormat('H', 'pt_BR').format(d);
    final minute = DateFormat('mm', 'pt_BR').format(d);
    return '$date às ${hour}h$minute';
  }

  void _goToInsights() {
    Navigator.pushNamed(
      context,
      AppRoutes.coachTrainingInsights,
      arguments: {'month': DateTime(_year, _month, 1), 'boxId': _boxId},
    );
  }

  void _openTrainingTypeDetail(String typeKey, String label) {
    Navigator.pushNamed(
      context,
      AppRoutes.coachCycleTrainingTypeDetail,
      arguments: {
        'year': _year,
        'month': _month,
        'typeKey': typeKey,
        'typeLabel': label,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),
      bottomNavigationBar: const BottomNavBar(),

      // ✅ Agora o back button NÃO é sticky: ele rola junto e some quando desce.
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 8 * scale,
        ),
        child: FutureBuilder<CycleDetailBundle>(
          future: _bundleFut,
          builder: (ctx, snap) {
            if (!snap.hasData) {
              return SizedBox(
                height: 240 * scale,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final bundle = snap.data!;
            final overview = bundle.overview;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // back (rola junto)
                const AppBackButton(),
                SizedBox(height: 10 * scale),

                Text(
                  'Esse é o seu ciclo:',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 14 * scale,
                    color: AppColors.darkText,
                    fontWeight: AppFontWeight.regular,
                  ),
                ),
                Text(
                  _titleMonth(),
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontSize: 22 * scale,
                    fontWeight: AppFontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),

                SizedBox(height: 10 * scale),

                // Última atualização
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16 * scale,
                      color: AppColors.baseBlue,
                    ),
                    SizedBox(width: 6 * scale),
                    Expanded(
                      child: Text(
                        'Última atualização: ${_formatUpdatedAt(overview.updatedAt)}',
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
                SizedBox(height: 4 * scale),
                Text(
                  'Análise gerada com base nos seus últimos 30 dias de treino.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 11 * scale,
                    color: AppColors.mediumGray,
                    fontWeight: AppFontWeight.regular,
                  ),
                ),

                SizedBox(height: 10 * scale),

                // Mini cards
                Row(
                  children: [
                    Expanded(
                      child: MiniCardWidget(
                        iconWidget: SvgPicture.asset(
                          'assets/icons/exercise.svg',
                          width: 16,
                          height: 16,
                          color: AppColors.darkText,
                        ),
                        title: 'Treinos',
                        valueFontSize: 12,
                        tipo: CardInfoType.cycleTrainings,
                        backgroundColor: AppColors.baseBlue,
                        borderColor: AppColors.baseBlue,
                        iconColor: AppColors.darkText,
                        titleFontSize: 13,
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: MiniCardWidget(
                        iconWidget: const Icon(Icons.edit_outlined),
                        title: 'Registros',
                        valueFontSize: 12,
                        tipo: CardInfoType.cycleRegistros,
                        backgroundColor: AppColors.baseBlue,
                        borderColor: AppColors.baseBlue,
                        iconColor: AppColors.darkText,
                        titleFontSize: 13,
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: MiniCardWidget(
                        iconWidget: const Icon(Icons.people_outline),
                        title: 'Alunos Ativos',
                        valueFontSize: 12,
                        tipo: CardInfoType.cycleActiveStudents,
                        backgroundColor: AppColors.baseBlue,
                        borderColor: AppColors.baseBlue,
                        iconColor: AppColors.darkText,
                        titleFontSize: 12,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 18 * scale),

                Text(
                  'Treinos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 10 * scale),

                ...bundle.trainingTypes.map((t) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 10 * scale),
                    child: CycleTrainingTypeCard(
                      label: t.typeLabel,
                      count: t.count,
                      onTap:
                          () => _openTrainingTypeDetail(t.typeKey, t.typeLabel),
                    ),
                  );
                }),

                SizedBox(height: 14 * scale),

                // Alertas do Ciclo
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Alertas do Ciclo',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    InkWell(
                      onTap: _goToInsights,
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            size: 18 * scale,
                            color: AppColors.baseBlue,
                          ),
                          SizedBox(width: 4 * scale),
                          Text(
                            'Ver todos Insights',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontSize: 12 * scale,
                              fontWeight: AppFontWeight.bold,
                              color: AppColors.baseBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10 * scale),

                AlertsCarousel(
                  allAlerts: bundle.alerts,
                  enabledTypes: const {'cycle'},
                ),

                SizedBox(height: 16 * scale),

                Text(
                  'Distribuição de Estímulos',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 10 * scale),

                CycleStimulusPieCard(
                  data: bundle.stimulus,
                  biggestLabel: bundle.biggestStimulusLabel,
                ),

                SizedBox(height: 30 * scale),
              ],
            );
          },
        ),
      ),
    );
  }
}
