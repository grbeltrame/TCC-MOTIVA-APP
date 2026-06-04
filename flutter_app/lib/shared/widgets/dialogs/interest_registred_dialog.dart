import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';

Future<void> showInterestRegisteredDialog(
  BuildContext context, {
  required String timeLabel,
  required String category,
  required String coachName,
}) {
  return showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder:
        (ctx) => AppDialog(
          icon: Icons.event_available_outlined,
          iconColor: AppColors.baseBlue,
          title: 'Interesse registrado!',
          message:
              'Você registrou interesse na turma das $timeLabel — $category\n'
              'com o professor $coachName.',
          primaryAction: TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
            child: const Text('OK'),
          ),
        ),
  );
}
