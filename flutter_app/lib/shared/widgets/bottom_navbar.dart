// lib/shared/widgets/bottom_navbar.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/core/services/profile_service.dart';

/// Bottom navigation bar fixa no rodapé, com 5 botões.
/// Descobre internamente se é coach ou atleta a partir do ProfileService,
/// igual ao TopNavbar.
class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  final ProfileService _profileService = ProfileService();

  /// true se o usuário atual tiver a role 'coach'
  late final bool _isCoach;

  /// índice do item selecionado (home=0, insights=1, ...)
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Sincrono por enquanto; quando tiver API, troque por chamada async:
    _isCoach = _profileService.hasRole('athlete');
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final items = <_NavItem>[
      _NavItem(
        icon: Icons.home_outlined,
        label: 'Início',
        routeAthlete: AppRoutes.athleteHome,
        routeCoach: AppRoutes.coachHome,
      ),
      _NavItem(
        icon: Icons.lightbulb_outline,
        label: 'Insights',
        routeAthlete: AppRoutes.athleteInsight,
        routeCoach: '/coach_insights', // TODO: ajustar rota real do coach
      ),
      _NavItem(
        icon: Icons.fitness_center,
        label: 'Treinos',
        routeAthlete: '/athlete_trainings',
        routeCoach: '/coach_trainings',
      ),
      _NavItem(
        icon: Icons.bar_chart,
        label: 'Evolução',
        routeAthlete: '/athlete_progress',
        routeCoach: '/coach_progress',
      ),
      _NavItem(
        icon: Icons.account_circle_outlined,
        label: 'Perfil',
        routeAthlete: '/athlete_profile',
        routeCoach: '/coach_profile',
      ),
    ];

    // Descobre a rota atual (para marcar o botão ativo)
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final idx = items.indexWhere(
      (i) => (_isCoach ? i.routeCoach : i.routeAthlete) == currentRoute,
    );
    _selectedIndex = idx >= 0 ? idx : 0;

    void onTap(int idx) {
      final item = items[idx];
      final destination = _isCoach ? item.routeCoach : item.routeAthlete;
      if (destination == currentRoute) return;
      // TODO: você pode informar o backend sobre a navegação aqui, se necessário
      Navigator.pushReplacementNamed(context, destination);
      setState(() => _selectedIndex = idx);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.mediumGray, // borda cinza superior
            width: 0.5 * scale,
          ),
        ),
      ),
      padding: EdgeInsets.only(top: 6 * scale, bottom: 20 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = i == _selectedIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.translucent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 6 * scale,
                  ),
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? AppColors.baseBlue.withOpacity(0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(16 * scale),
                  ),
                  child: Icon(
                    item.icon,
                    size: 24 * scale,
                    color: selected ? AppColors.baseBlue : AppColors.darkText,
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w400,
                    color: selected ? AppColors.baseBlue : AppColors.darkText,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

/// Agrupa ícone, label e rotas de atleta/coach.
class _NavItem {
  final IconData icon;
  final String label;
  final String routeAthlete;
  final String routeCoach;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.routeAthlete,
    required this.routeCoach,
  });
}
