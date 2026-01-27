import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/pr_service.dart';

import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class AthletePrListScreen extends StatefulWidget {
  static const routeName = '/athlete_pr_list';
  const AthletePrListScreen({Key? key}) : super(key: key);

  @override
  State<AthletePrListScreen> createState() => _AthletePrListScreenState();
}

class _AthletePrListScreenState extends State<AthletePrListScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<String>> _wodsFut; // nomes de benchmarks
  late Future<List<String>> _lpoFut;
  late Future<List<String>> _ginFut;
  late Future<List<String>> _endFut;

  @override
  void initState() {
    super.initState();

    _wodsFut = PRService.fetchBenchmarks().then(
      (list) => list.map((b) => b.name).toList(),
    );
    _lpoFut = PRService.fetchMovements(PrCategory.lpo);
    _ginFut = PRService.fetchMovements(PrCategory.gym);
    _endFut = PRService.fetchMovements(PrCategory.endurance);
  }

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  void _goToPrItem(String label, PrCategory category) {
    Navigator.of(context).pushNamed(
      AppRoutes.athletePrItem,
      arguments: {'label': label, 'category': category},
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: const TopNavbar(),

        bottomNavigationBar: const BottomNavBar(),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back
            Padding(
              padding: EdgeInsets.only(
                top: 8.0 * scale,
                left: 6.0 * scale,
                right: 6.0 * scale,
              ),
              child: const AppBackButton(),
            ),

            // Tabs (ocupam a largura toda, centralizando os títulos)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.0 * scale),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.mediumGray.withValues(alpha: .35),
                      width: 0.8 * scale,
                    ),
                  ),
                ),
                child: TabBar(
                  isScrollable: false,
                  labelPadding: EdgeInsets.zero,
                  indicatorPadding: EdgeInsets.zero,
                  labelColor: AppColors.baseBlue,
                  unselectedLabelColor: AppColors.mediumGray,
                  indicatorColor: AppColors.baseBlue,
                  labelStyle: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 16 * scale,
                  ),
                  tabs: const [
                    Tab(text: 'WOD'),
                    Tab(text: 'LPO'),
                    Tab(text: 'Ginastica'),
                    Tab(text: 'Endurance'),
                  ],
                ),
              ),
            ),

            SizedBox(height: 6 * scale),

            // Conteúdo das tabs
            Expanded(
              child: TabBarView(
                children: [
                  _TabList(
                    future: _wodsFut,
                    emptyText: 'Nenhum WOD encontrado.',
                    onTapAdd: (s) => _goToPrItem(s, PrCategory.wod),
                  ),
                  _TabList(
                    future: _lpoFut,
                    emptyText: 'Nenhum movimento de LPO encontrado.',
                    onTapAdd: (s) => _goToPrItem(s, PrCategory.lpo),
                  ),
                  _TabList(
                    future: _ginFut,
                    emptyText: 'Nenhum movimento de Ginástica encontrado.',
                    onTapAdd: (s) => _goToPrItem(s, PrCategory.gym),
                  ),
                  _TabList(
                    future: _endFut,
                    emptyText: 'Nenhum movimento de Endurance encontrado.',
                    onTapAdd: (s) => _goToPrItem(s, PrCategory.endurance),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabList extends StatelessWidget {
  const _TabList({
    Key? key,
    required this.future,
    required this.emptyText,
    required this.onTapAdd,
  }) : super(key: key);

  final Future<List<String>> future;
  final String emptyText;
  final ValueChanged<String> onTapAdd;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<List<String>>(
      future: future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: AppColors.mediumGray,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 6.0 * scale),
          itemBuilder: (_, i) {
            final label = items[i];
            return Container(
              height: 44 * scale,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.mediumGray.withValues(alpha: .4),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // margem interna à esquerda pro texto
                  Padding(
                    padding: EdgeInsets.only(left: 12 * scale),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.medium,
                        fontSize: 16 * scale,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.add, color: AppColors.mediumGray),
                    onPressed: () => onTapAdd(label),
                    splashRadius: 18 * scale,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox.shrink(),
          itemCount: items.length,
        );
      },
    );
  }
}
