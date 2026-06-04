// lib/shared/screens/athlete_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

// ===== ADIÇÕES =====
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/goal_service.dart';
import 'package:flutter_app/shared/widgets/cards/goal_card_widget.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
// ===================

class AthleteAllGoalsScreen extends StatefulWidget {
  static const routeName = '/athlete_all_goals';
  const AthleteAllGoalsScreen({Key? key}) : super(key: key);

  @override
  State<AthleteAllGoalsScreen> createState() => _AthleteAllGoalsScreenState();
}

class _AthleteAllGoalsScreenState extends State<AthleteAllGoalsScreen> {
  // ===== ADIÇÕES =====
  String? _highlightGoalId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['highlightGoalId'] is String) {
      _highlightGoalId = args['highlightGoalId'] as String;
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, Goal g) async {
    final ok = await showDialog<bool>(
      context: ctx,
      useRootNavigator: true,
      barrierDismissible: false,
      builder:
          (dCtx) => AppDialog(
            icon: Icons.delete_outline,
            iconColor: AppColors.baseMagenta,
            title: 'Tem certeza que deseja excluir essa meta?',
            message: 'Essa ação não poderá ser desfeita',
            secondaryAction: TextButton(
              onPressed:
                  () => Navigator.of(dCtx, rootNavigator: true).pop(false),
              style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
              child: const Text('Cancelar'),
            ),
            primaryAction: TextButton(
              onPressed:
                  () => Navigator.of(dCtx, rootNavigator: true).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.baseMagenta,
              ),
              child: const Text('Remover'),
            ),
          ),
    );

    if (ok == true) {
      try {
        await GoalService.deleteGoal(g.id);
        if (!mounted) return;
        setState(() {}); // força recarregar os FutureBuilders
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meta removida.')));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível remover a meta.')),
        );
      }
    }
  }

  int _resolveInitialIndex(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      final t = args['initialTab'];
      if (t == 'system' || t == 'sistema') return 1; // segunda aba
      if (t == 'user' || t == 'cadastradas') return 0; // primeira aba
      final idx = args['initialIndex'];
      if (idx is int && (idx == 0 || idx == 1)) return idx;
    }
    return 0; // padrão: Cadastradas
  }

  Widget _buildGoalsList({
    required Future<List<Goal>> Function() loader,
    required String emptyText,
  }) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<List<Goal>>(
      future: loader(),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        var goals = snap.data ?? [];

        // coloca a recém-criada no topo e destaca
        final h = _highlightGoalId;
        if (h != null) {
          final idx = goals.indexWhere((g) => g.id == h);
          if (idx >= 0) {
            final g = goals.removeAt(idx);
            goals = [g, ...goals];
          }
        }

        if (goals.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24 * scale),
              child: Text(
                emptyText,
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

        return ListView.separated(
          padding: EdgeInsets.all(12 * scale),
          itemCount: goals.length,
          separatorBuilder: (_, __) => SizedBox(height: 12 * scale),
          itemBuilder: (ctx, i) {
            final g = goals[i];
            final isHL = g.id == _highlightGoalId;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOut,
              padding: EdgeInsets.all(isHL ? 4 * scale : 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18 * scale),
                border:
                    isHL
                        ? Border.all(color: AppColors.baseBlue, width: 2)
                        : null,
              ),
              child: GoalCardWidget(
                badgeAsset: g.badgeAsset,
                title: g.title,
                deadlineWeeks: g.deadlineWeeks,
                startDate: g.startDate,
                unitsPerWeek: g.unitsPerWeek,
                completedUnits: g.completedUnits,
                showDeleteButton: true,
                onDelete: () => _confirmDelete(context, g),
              ),
            );
          },
        );
      },
    );
  }
  // ===================

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),

      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 8.0 * scale,
          left: 6.0 * scale,
          right: 6.0 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppBackButton(),
            SizedBox(height: 12 * scale),

            // ===== ADIÇÃO: Tabs "Cadastradas" / "Sistema" =====
            DefaultTabController(
              length: 2,
              initialIndex: _resolveInitialIndex(context), // <<<<<<<<<< AQUI
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: AppColors.baseBlue,
                    labelColor: AppColors.baseBlue,
                    unselectedLabelColor: AppColors.mediumGray,
                    labelStyle: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 16 * scale,
                    ),
                    tabs: const [
                      Tab(text: 'Cadastradas'),
                      Tab(text: 'Sistema'),
                    ],
                  ),
                  SizedBox(height: 8 * scale),

                  // Como estamos em um SingleChildScrollView, precisamos fixar altura.
                  // Usamos ~70% da altura da tela para o conteúdo das listas.
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.70,
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // Cadastradas: todas as metas do usuário (user + system)
                        _buildGoalsList(
                          loader: GoalService.fetchUserGoals,
                          emptyText: 'Você ainda não cadastrou metas.',
                        ),

                        // Sistema: metas de origem "system" já adicionadas à lista do usuário
                        _buildGoalsList(
                          loader: GoalService.fetchUserSystemGoals,
                          emptyText: 'Nenhuma meta de sistema na sua lista.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ================================================
          ],
        ),
      ),
    );
  }
}
