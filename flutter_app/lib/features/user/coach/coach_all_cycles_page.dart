import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_training_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/cards/coach_cycle_month_card.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/year_selector.dart';
import 'package:intl/intl.dart';

class CoachAllCyclesScreen extends StatefulWidget {
  static const routeName = '/coach_all_cycles';

  const CoachAllCyclesScreen({super.key});

  @override
  State<CoachAllCyclesScreen> createState() => _CoachAllCyclesScreenState();
}

class _CoachAllCyclesScreenState extends State<CoachAllCyclesScreen> {
  // TODO(back): trocar pelo boxId real vindo do contexto/auth
  final String _boxId = '1';

  late int _selectedYear;
  bool _bootstrapped = false;

  late Future<List<int>> _monthsFut;
  late Future<DateTime?> _currentCycleFut;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;

    _selectedYear = DateTime.now().year;

    _monthsFut = CycleAll.fetchRegisteredCycleMonthsForYear(
      boxId: _boxId,
      year: _selectedYear,
    );

    _currentCycleFut = CycleAll.fetchCurrentCycleMonth(boxId: _boxId);

    _bootstrapped = true;
  }

  void _onYearChanged(int year) {
    setState(() {
      _selectedYear = year;
      _monthsFut = CycleAll.fetchRegisteredCycleMonthsForYear(
        boxId: _boxId,
        year: _selectedYear,
      );
    });
  }

  String _monthLabelPtBr(int year, int month) {
    final dt = DateTime(year, month, 1);
    final raw = DateFormat('MMMM', 'pt_BR').format(dt); // janeiro
    final cap = raw.isNotEmpty ? raw[0].toUpperCase() + raw.substring(1) : raw;
    return cap;
  }

  String _currentCycleLabel(DateTime month) {
    final rawMonth = DateFormat('MMMM', 'pt_BR').format(month);
    final monthLabel =
        rawMonth.isNotEmpty
            ? rawMonth[0].toUpperCase() + rawMonth.substring(1)
            : rawMonth;
    return '$monthLabel/${month.year}';
  }

  Future<void> _handleTapMonth(int year, int month) async {
    final exists = await CycleAll.isCycleRegistered(
      boxId: _boxId,
      year: year,
      month: month,
    );

    if (!mounted) return;

    if (!exists) {
      // Se não existe ciclo, abre bottom sheet de cadastrar treino
      showRegisterTrainingBottomSheet(context);
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.coachCycleDetail,
      arguments: {'year': year, 'month': month},
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // back
          Padding(
            padding: EdgeInsets.only(
              top: 8 * scale,
              left: 6 * scale,
              right: 6 * scale,
            ),
            child: const AppBackButton(),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 10 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ciclo atual: label + container ao lado (igual referência)
                  Row(
                    children: [
                      Text(
                        'Ciclo Atual:',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 16 * scale,
                          fontWeight: AppFontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      SizedBox(width: 10 * scale),
                      FutureBuilder<DateTime?>(
                        future: _currentCycleFut,
                        builder: (ctx, snap) {
                          final current = snap.data;
                          final text =
                              current == null
                                  ? '—'
                                  : _currentCycleLabel(current);

                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12 * scale,
                              vertical: 6 * scale,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4 * scale),
                              border: Border.all(color: AppColors.baseBlue),
                            ),
                            child: Text(
                              text,
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontSize: 14 * scale,
                                fontWeight: AppFontWeight.bold,
                                color: AppColors.darkText,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 22 * scale),

                  // Texto + YearSelector
                  Text(
                    'Esses são todos os seu ciclos registrados em:',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 14 * scale,
                      color: AppColors.darkText,
                      fontWeight: AppFontWeight.regular,
                    ),
                  ),

                  SizedBox(height: 10 * scale),

                  YearSelector(
                    initialYear: _selectedYear,
                    onYearChanged: _onYearChanged,
                  ),

                  SizedBox(height: 16 * scale),

                  FutureBuilder<List<int>>(
                    future: _monthsFut,
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return SizedBox(
                          height: 120 * scale,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final months = snap.data ?? const <int>[];
                      if (months.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(top: 8 * scale),
                          child: Text(
                            'Nenhum ciclo cadastrado nesse ano.',
                            style: TextStyle(
                              fontFamily: AppFonts.roboto,
                              fontSize: 12 * scale,
                              color: AppColors.mediumGray,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children:
                            months.map((m) {
                              final label = _monthLabelPtBr(_selectedYear, m);
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12 * scale),
                                child: CycleMonthCard(
                                  label: label,
                                  onTap:
                                      () => _handleTapMonth(_selectedYear, m),
                                ),
                              );
                            }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
