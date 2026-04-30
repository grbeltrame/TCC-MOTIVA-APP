import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/features/auth/presentation/providers/user_provider.dart';
import 'package:animations/animations.dart'; // FadeThrough — Material Design 3

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isCoachView = userProvider.isCoachView;
    final scale =
        (MediaQuery.of(context).size.width / 375.0)
            .clamp(0.88, 1.12)
            .toDouble();

    final items = <_NavItem>[
      _NavItem(
        icon: Icons.home_outlined,
        label: 'Início',
        routeAthlete: AppRoutes.athleteHome,
        routeCoach: AppRoutes.coachHome,
      ),
      _NavItem(
        icon: Icons.calendar_today_outlined,
        iconCoach: Icons.lightbulb_outline,
        label: 'Semana',
        labelCoach: 'Análise',
        routeAthlete: AppRoutes.athleteInsight,
        routeCoach: AppRoutes.coachInsights,
      ),
      _NavItem(
        icon: Icons.fitness_center,
        label: 'Treinos',
        routeAthlete: AppRoutes.athleteTraining,
        routeCoach: AppRoutes.coachTrainings,
      ),
      _NavItem(
        icon: Icons.bar_chart,
        label: 'Evolução',
        labelCoach: 'Ciclo',
        routeAthlete: AppRoutes.athleteEvolution,
        routeCoach: AppRoutes.coachTrainingInsights,
      ),
      _NavItem(
        icon: Icons.account_circle_outlined,
        label: 'Perfil',
        routeAthlete: AppRoutes.athleteProfile,
        routeCoach: AppRoutes.coachProfile,
      ),
    ];

    final currentRoute = ModalRoute.of(context)?.settings.name;

    final idx = items.indexWhere(
      (i) => (isCoachView ? i.routeCoach : i.routeAthlete) == currentRoute,
    );
    final selectedIndex = idx >= 0 ? idx : -1;

    void onTap(int index) {
      final item = items[index];
      final destination = isCoachView ? item.routeCoach : item.routeAthlete;

      if (destination == currentRoute) return;

      // Direção do slide: para a direita se o índice destino for maior,
      // para a esquerda se for menor.
      // Busca o onGenerateRoute do Navigator pai para construir a página
      // correta dentro do pageBuilder.
      final routeFactory = Navigator.of(context).widget.onGenerateRoute;

      if (routeFactory == null) {
        // Fallback sem animação caso o Navigator não tenha onGenerateRoute
        Navigator.pushReplacementNamed(context, destination);
        return;
      }

      Navigator.pushReplacement(
        context,
        _NavPageRoute(destination: destination, routeFactory: routeFactory),
      );
    }

    return SafeArea(
      top: false,
      minimum: EdgeInsets.only(bottom: 4 * scale),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.mediumGray, width: 0.5 * scale),
          ),
        ),
        padding: EdgeInsets.only(top: 6 * scale, bottom: 6 * scale),
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == selectedIndex;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.translucent,
                child: SizedBox(
                  height: 58 * scale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Fundo do ícone anima suavemente ao selecionar
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scale,
                          vertical: 5 * scale,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? AppColors.baseBlue.withOpacity(0.15)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(16 * scale),
                        ),
                        child: Icon(
                          isCoachView
                              ? (item.iconCoach ?? item.icon)
                              : item.icon,
                          size: 23 * scale,
                          color:
                              selected
                                  ? AppColors.baseBlue
                                  : AppColors.darkText,
                        ),
                      ),
                      SizedBox(height: 3 * scale),
                      // Texto anima peso e cor ao selecionar
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        style: TextStyle(
                          fontSize: 11.5 * scale,
                          fontWeight:
                              selected ? FontWeight.bold : FontWeight.w400,
                          color:
                              selected
                                  ? AppColors.baseBlue
                                  : AppColors.darkText,
                        ),
                        child: Text(
                          isCoachView
                              ? (item.labelCoach ?? item.label)
                              : item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// =============================================================================
// _NavPageRoute — FadeThrough (Material Design 3)
// =============================================================================

/// FadeThrough é a transição oficial do Material Design 3 para bottom
/// navigation bars. Usada por Instagram, YouTube, Spotify e Google apps.
///
/// Comportamento:
///   - Tela atual: fade out + scale de 1.0 → 0.92
///   - Tela nova:  fade in  + scale de 0.92 → 1.0
///   - Duração: 300ms
///
/// Não precisa de goingRight pois FadeThrough é direcional-neutro — ideal
/// para abas que são irmãs, não filhas umas das outras.
class _NavPageRoute extends PageRouteBuilder {
  _NavPageRoute({
    required String destination,
    required RouteFactory routeFactory,
  }) : super(
         settings: RouteSettings(name: destination),
         // 300ms é a duração recomendada pelo Material Design 3
         transitionDuration: const Duration(milliseconds: 300),
         reverseTransitionDuration: const Duration(milliseconds: 300),

         pageBuilder: (context, animation, secondaryAnimation) {
           final generatedRoute = routeFactory(
             RouteSettings(name: destination),
           );
           if (generatedRoute is PageRoute) {
             return generatedRoute.buildPage(
               context,
               animation,
               secondaryAnimation,
             );
           }
           return const Scaffold(
             body: Center(child: CircularProgressIndicator()),
           );
         },

         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // FadeThroughTransition do pacote oficial flutter/animations
           return FadeThroughTransition(
             animation: animation,
             secondaryAnimation: secondaryAnimation,
             child: child,
           );
         },
       );
}

// =============================================================================
// _NavItem
// =============================================================================

class _NavItem {
  final IconData icon;
  final IconData? iconCoach; // se null, usa icon para ambos os perfis
  final String label;
  final String? labelCoach; // se null, usa label para ambos os perfis
  final String routeAthlete;
  final String routeCoach;

  const _NavItem({
    required this.icon,
    this.iconCoach,
    required this.label,
    this.labelCoach,
    required this.routeAthlete,
    required this.routeCoach,
  });
}
