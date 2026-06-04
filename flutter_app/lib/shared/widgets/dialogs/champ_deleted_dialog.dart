import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

Future<void> showChampDeletedDialog(BuildContext context, String name) {
  return showDialog<void>(
    context: context,
    builder:
        (_) => AppDialog(
          icon: Icons.info_outline,
          iconColor: AppColors.darkBlue,
          title: 'Campeonato removido',
          message: 'O campeonato "$name" foi removido da sua lista.',
          primaryAction: TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
            child: const Text('OK'),
          ),
        ),
  );
}
