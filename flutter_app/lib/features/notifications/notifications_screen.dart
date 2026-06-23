import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/features/auth/presentation/providers/user_provider.dart';
import 'package:flutter_app/shared/models/app_notification.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatelessWidget {
  static const routeName = '/notifications';

  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final profileType = context.watch<UserProvider>().profileType;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Notificações',
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
            fontSize: 18 * scale,
            color: AppColors.darkText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: NotificationService.instance.markAllAsRead,
            child: Text(
              'Marcar lidas',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                fontSize: 12 * scale,
                color: AppColors.darkBlue,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.instance.watchNotifications(),
        builder: (context, snapshot) {
          final notifications = snapshot.data ?? const <AppNotification>[];

          if (snapshot.connectionState == ConnectionState.waiting &&
              notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifications.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(24 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppBackButton(),
                  SizedBox(height: 40 * scale),
                  Text(
                    'Nenhuma notificação por enquanto.',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 14 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16 * scale,
              8 * scale,
              16 * scale,
              24 * scale,
            ),
            itemCount: notifications.length + 1,
            separatorBuilder: (_, __) => SizedBox(height: 8 * scale),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8 * scale),
                  child: const AppBackButton(),
                );
              }

              final notification = notifications[index - 1];
              return _NotificationTile(
                notification: notification,
                profileType: profileType,
                scale: scale,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final String? profileType;
  final double scale;

  const _NotificationTile({
    required this.notification,
    required this.profileType,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final unread = notification.isUnread;

    return InkWell(
      borderRadius: BorderRadius.circular(8 * scale),
      onTap: () async {
        await NotificationService.instance.markAsRead(notification.id);
        if (!context.mounted) return;
        final route = notification.routeName;
        if (route != null && route.isNotEmpty) {
          Navigator.pushNamed(
            context,
            route,
            arguments: notification.routeArgs,
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(12 * scale),
        decoration: BoxDecoration(
          color: unread ? Colors.white : AppColors.offWhite,
          borderRadius: BorderRadius.circular(8 * scale),
          border: Border.all(
            color: unread ? AppColors.darkBlue : AppColors.lightGray,
            width: unread ? 1.2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 8 * scale,
              height: 8 * scale,
              margin: EdgeInsets.only(top: 6 * scale, right: 10 * scale),
              decoration: BoxDecoration(
                color: unread ? Colors.red : AppColors.mediumGray,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.displayTitle(profileType),
                    style: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight:
                          unread ? AppFontWeight.bold : AppFontWeight.regular,
                      fontSize: 13 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                  if (notification.body.isNotEmpty) ...[
                    SizedBox(height: 4 * scale),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 12 * scale,
                        color: AppColors.mediumGray,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
