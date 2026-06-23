import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

Future<bool?> showConfirmDeleteChampDialog(BuildContext context, String name) {
  return showDialog<bool>(
    context: context,
    builder:
        (_) => AppDialog(
          icon: Icons.delete_outline,
          iconColor: Colors.red.shade600,
          title: 'Remover campeonato?',
          message:
              'Tem certeza que deseja remover "$name" da sua lista de próximos?',
          secondaryAction: TextButton(
            onPressed:
                () => Navigator.of(context, rootNavigator: true).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.lightBlue),
            child: const Text('Não'),
          ),
          primaryAction: TextButton(
            onPressed:
                () => Navigator.of(context, rootNavigator: true).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.lightMagenta,
            ),
            child: const Text('Sim'),
          ),
        ),
  );
}
