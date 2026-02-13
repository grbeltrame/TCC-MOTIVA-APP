import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <--- 1. Importante
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/routes/app_routes.dart';
// Removido o ProfileService antigo
import 'package:flutter_app/features/auth/presentation/providers/user_provider.dart'; // <--- 2. Importante

class BottomNavBar extends StatelessWidget {
  // <--- 3. Virou StatelessWidget (mais leve)
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 4. Conectando ao cérebro do App (UserProvider)
    final userProvider = Provider.of<UserProvider>(context);
    final isCoachView =
        userProvider.isCoachView; // A verdade absoluta vem daqui

    final scale = MediaQuery.of(context).size.width / 375.0;

    // Lista de rotas configurada
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
        routeCoach: AppRoutes.coachInsights,
      ),
      _NavItem(
        icon: Icons.fitness_center,
        label: 'Treinos',
        routeAthlete: AppRoutes.athleteTraining,
        routeCoach:
            AppRoutes
                .coachTrainings, // Atenção ao plural/singular nas suas rotas
      ),
      _NavItem(
        icon: Icons.bar_chart,
        label: 'Evolução',
        routeAthlete: AppRoutes.athleteEvolution,
        routeCoach: AppRoutes.coachEvolutions,
      ),
      _NavItem(
        icon: Icons.account_circle_outlined,
        label: 'Perfil',
        routeAthlete: AppRoutes.athleteProfile,
        routeCoach: AppRoutes.coachProfile,
      ),
    ];

    // Descobre a rota atual
    final currentRoute = ModalRoute.of(context)?.settings.name;

    // Lógica corrigida: usa o isCoachView do Provider
    final idx = items.indexWhere(
      (i) => (isCoachView ? i.routeCoach : i.routeAthlete) == currentRoute,
    );

    final selectedIndex = idx >= 0 ? idx : -1;

    void onTap(int index) {
      final item = items[index];
      // Decide o destino baseado no Provider
      final destination = isCoachView ? item.routeCoach : item.routeAthlete;

      if (destination == currentRoute) return;

      // Navega substituindo a tela atual (sem animação de pilha)
      Navigator.pushReplacementNamed(context, destination);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.mediumGray, width: 0.5 * scale),
        ),
      ),
      padding: EdgeInsets.only(top: 6 * scale, bottom: 20 * scale),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) {
          final item = items[i];
          final selected = i == selectedIndex;

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
