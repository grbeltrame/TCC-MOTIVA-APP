import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/features/auth/presentation/providers/user_provider.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:provider/provider.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSystemBack;

  const TopNavbar({super.key, this.showSystemBack = false});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isCoachView = userProvider.isCoachView;
    final canSwitch = userProvider.canToggleView;
    final currentLabel = isCoachView ? 'Coach' : 'Atleta';
    final scale = MediaQuery.of(context).size.width / 375.0;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: showSystemBack ? const BackButton() : null,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16.0 * scale,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(0.5 * scale),
        child: Container(height: 0.5 * scale, color: AppColors.mediumGray),
      ),
      title:
          canSwitch
              ? _buildMenu(
                context: context,
                currentLabel: currentLabel,
                scale: scale,
                userProvider: userProvider,
              )
              : Text(
                currentLabel,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18 * scale,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
    );
  }

  Widget _buildMenu({
    required BuildContext context,
    required String currentLabel,
    required double scale,
    required UserProvider userProvider,
  }) {
    return PopupMenuButton<String>(
      initialValue: currentLabel,
      onSelected: (value) {
        if (value == currentLabel) return;
        userProvider.toggleViewMode();
        Navigator.pushNamedAndRemoveUntil(
          context,
          userProvider.isCoachView
              ? AppRoutes.coachHome
              : AppRoutes.athleteHome,
          (route) => false,
        );
      },
      itemBuilder:
          (context) => [
            PopupMenuItem<String>(
              value: 'Atleta',
              child: Text(
                'Atleta',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            PopupMenuItem<String>(
              value: 'Coach',
              child: Text(
                'Coach',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18 * scale,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
