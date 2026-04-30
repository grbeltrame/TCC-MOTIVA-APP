// lib/shared/widgets/top_navbar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_app/features/auth/presentation/providers/user_provider.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_training_bottom_sheet.dart';

class TopNavbar extends StatelessWidget implements PreferredSizeWidget {
  final bool showSystemBack;

  // Mantido por compatibilidade
  final VoidCallback? onRegisterBox;

  const TopNavbar({Key? key, this.showSystemBack = false, this.onRegisterBox})
    : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _openRegisterTraining(BuildContext context) {
    showRegisterTrainingBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Conecta ao cérebro (Provider)
    final userProvider = Provider.of<UserProvider>(context);

    // Dados do estado atual
    final isCoachView = userProvider.isCoachView;
    final canSwitch = userProvider.canToggleView;

    // Rótulo do papel atual exibido no AppBar (e usado como value do menu).
    final String currentLabel = isCoachView ? 'Coach' : 'Atleta';

    final scale = MediaQuery.of(context).size.width / 375.0;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: showSystemBack ? const BackButton() : null,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16.0 * scale,

      // Borda inferior cinza (igual ao original)
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(0.5 * scale),
        child: Container(height: 0.5 * scale, color: AppColors.mediumGray),
      ),

      title: Row(
        children: [
          // 1) TÍTULO / DROPDOWN
          // Se puder trocar (Híbrido), mostra o menu com setinha.
          // Se não, mostra só o texto.
          if (canSwitch)
            _buildMenu(
              context: context,
              currentLabel: currentLabel,
              scale: scale,
              userProvider: userProvider,
            )
          else
            Text(
              currentLabel,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18 * scale,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

          // 2) BOTÃO CADASTRAR TREINO (Posição Original)
          // Só aparece se estiver no modo Coach
          if (isCoachView) ...[
            SizedBox(width: 16 * scale),
            TextActionButton(
              icon: Icons.add,
              text: 'Cadastrar Treino', // Texto original restaurado
              onPressed: () => _openRegisterTraining(context),
            ),
          ],

          const Spacer(),

          // 3) NOTIFICAÇÕES (Visual mantido)
          StreamBuilder<int>(
            stream: NotificationService.instance.watchUnreadCount(),
            initialData: 0,
            builder: (context, snapshot) {
              return _buildNotificationIcon(context, scale, snapshot.data ?? 0);
            },
          ),
        ],
      ),
    );
  }

  /// Recria o visual exato do Dropdown antigo
  Widget _buildMenu({
    required BuildContext context,
    required String currentLabel,
    required double scale,
    required UserProvider userProvider,
  }) {
    return PopupMenuButton<String>(
      initialValue: currentLabel,
      // Ao selecionar, verificamos se precisa trocar
      onSelected: (value) {
        if (value != currentLabel) {
          // Troca o estado
          userProvider.toggleViewMode();

          // Navega
          if (userProvider.isCoachView) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.coachHome,
              (r) => false,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.athleteHome,
              (r) => false,
            );
          }
        }
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<String>>[
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
      // O Child é o que aparece na Barra (Texto + Setinha para baixo)
      child: Row(
        children: [
          Text(
            currentLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18 * scale,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down, // Ícone original restaurado
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  /// Visual do ícone de notificação (Mantido)
  Widget _buildNotificationIcon(
    BuildContext context,
    double scale,
    int unreadCount,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            Icons.notifications_none,
            size: 24 * scale,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: EdgeInsets.all(4 * scale),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: 16 * scale,
                minHeight: 16 * scale,
              ),
              child: Text(
                '$unreadCount',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 10 * scale),
              ),
            ),
          ),
      ],
    );
  }
}
