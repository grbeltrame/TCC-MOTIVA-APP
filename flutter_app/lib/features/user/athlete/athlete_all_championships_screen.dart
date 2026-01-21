// lib/features/user/athlete/athlete_all_championships_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/championship_service.dart';
import 'package:flutter_app/shared/models/championship.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

// itens de lista
import 'package:flutter_app/shared/widgets/championships/upcoming_champ_list_item.dart';
import 'package:flutter_app/shared/widgets/championships/concluded_champ_list_item.dart';

// bottom sheet de registrar resultado
import 'package:flutter_app/shared/widgets/bottom_sheets/register_champ_result_bottom_sheet.dart';

// dialogs
import 'package:flutter_app/shared/widgets/dialogs/confirm_delete_champ_dialog.dart';
import 'package:flutter_app/shared/widgets/dialogs/champ_deleted_dialog.dart';

class AllChampionshipsScreen extends StatefulWidget {
  static const routeName = '/championships_all';
  const AllChampionshipsScreen({super.key});

  @override
  State<AllChampionshipsScreen> createState() => _AllChampionshipsScreenState();
}

class _AllChampionshipsScreenState extends State<AllChampionshipsScreen> {
  late Future<List<Championship>> _futureUpcoming;
  late Future<List<Championship>> _futureConcluded;

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _futureUpcoming = ChampionshipService.fetchUpcomingChampionships();
      _futureConcluded = ChampionshipService.fetchConcludedChampionships();
    });
  }

  Future<void> _handleRegisterResult(Championship c) async {
    final ok = await showRegisterChampResultBottomSheet(
      context,
      championship: c,
    );
    if (ok == true && mounted) {
      _reload(); // move de Próximos → Concluídos
    }
  }

  Future<void> _handleDelete(Championship c) async {
    final confirm = await showConfirmDeleteChampDialog(context, c.name);
    if (confirm != true) return;

    await ChampionshipService.deleteUpcomingChampionship(c.id);
    if (!mounted) return;
    _reload();
    await showChampDeletedDialog(context, c.name);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),
      body: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // back
            Padding(
              padding: EdgeInsets.only(
                top: 8.0 * scale,
                left: 6.0 * scale,
                right: 6.0 * scale,
              ),
              child: const AppBackButton(),
            ),
            SizedBox(height: 12 * scale),

            // Tabs (centralizadas) + linha cinza inferior
            Container(
              padding: EdgeInsets.only(top: 6 * scale, bottom: 0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.mediumGray, width: 1),
                ),
              ),
              child: Center(
                child: TabBar(
                  isScrollable: false,
                  labelColor: AppColors.baseBlue,
                  unselectedLabelColor: AppColors.mediumGray,
                  indicatorColor: AppColors.baseBlue,
                  labelStyle: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 14 * scale,
                  ),
                  tabs: const [Tab(text: 'Próximos'), Tab(text: 'Concluídos')],
                ),
              ),
            ),

            // Conteúdo das abas
            Expanded(
              child: TabBarView(
                children: [
                  // ----- Lista Próximos -----
                  FutureBuilder<List<Championship>>(
                    future: _futureUpcoming,
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final list =
                          (snap.data ?? [])..sort(
                            (a, b) => a.startDate.compareTo(b.startDate),
                          );

                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            'Nenhum campeonato nos próximos dias.',
                            style: TextStyle(
                              color: AppColors.mediumGray,
                              fontFamily: AppFonts.roboto,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * scale,
                          vertical: 8 * scale,
                        ),
                        itemCount: list.length,
                        separatorBuilder:
                            (_, __) =>
                                Divider(height: 1, color: AppColors.mediumGray),
                        itemBuilder: (_, i) {
                          final c = list[i];
                          return UpcomingChampListItem(
                            champ: c,
                            onTapRegister: () => _handleRegisterResult(c),
                            onTapDelete: () => _handleDelete(c),
                          );
                        },
                      );
                    },
                  ),

                  // ----- Lista Concluídos -----
                  FutureBuilder<List<Championship>>(
                    future: _futureConcluded,
                    builder: (ctx, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final list =
                          (snap.data ?? [])
                            ..sort((a, b) => b.endDate.compareTo(a.endDate));

                      if (list.isEmpty) {
                        return Center(
                          child: Text(
                            'Sem campeonatos concluídos ainda.',
                            style: TextStyle(
                              color: AppColors.mediumGray,
                              fontFamily: AppFonts.roboto,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * scale,
                          vertical: 8 * scale,
                        ),
                        itemCount: list.length,
                        separatorBuilder:
                            (_, __) =>
                                Divider(height: 1, color: AppColors.mediumGray),
                        itemBuilder: (_, i) {
                          final c = list[i];
                          return ConcludedChampListItem(
                            champ: c,
                            onTapRegister: () => _handleRegisterResult(c),
                          );
                        },
                      );
                    },
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
