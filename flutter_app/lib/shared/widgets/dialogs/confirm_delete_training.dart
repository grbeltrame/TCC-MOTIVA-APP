import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

/// Dialog de confirmação para exclusão de treino.
/// Retorna `true` se o usuário confirmou, `false` se cancelou.
Future<bool?> showConfirmDeleteTrainingDialog(
  BuildContext context, {
  required String trainingTitle,
  String? dateLabel, // opcional: "12/10/2025"
  String? categoryLabel, // opcional: "WOD"
}) {
  final details = [
    if (categoryLabel != null && categoryLabel.isNotEmpty) categoryLabel,
    if (dateLabel != null && dateLabel.isNotEmpty) dateLabel,
  ].join(' • ');

  final fullMessage =
      details.isEmpty
          ? 'Tem certeza que deseja excluir "$trainingTitle"?'
          : 'Tem certeza que deseja excluir "$trainingTitle"?\n($details)';

  return showDialog<bool>(
    context: context,
    builder:
        (_) => AppDialog(
          icon: Icons.delete_outline,
          iconColor: Colors.red.shade600,
          title: 'Excluir treino?',
          message: fullMessage,
          secondaryAction: TextButton(
            onPressed:
                () => Navigator.of(context, rootNavigator: true).pop(false),
            style: TextButton.styleFrom(foregroundColor: AppColors.lightBlue),
            child: const Text('Cancelar'),
          ),
          primaryAction: TextButton(
            onPressed:
                () => Navigator.of(context, rootNavigator: true).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Excluir'),
          ),
        ),
  );
}

/// Dialog informando que a exclusão foi concluída.
Future<void> showTrainingDeletedDialog(
  BuildContext context, {
  required String trainingTitle,
  String? dateLabel,
  String? categoryLabel,
}) {
  final details = [
    if (categoryLabel != null && categoryLabel.isNotEmpty) categoryLabel,
    if (dateLabel != null && dateLabel.isNotEmpty) dateLabel,
  ].join(' • ');

  final fullMessage =
      details.isEmpty
          ? 'O treino "$trainingTitle" foi excluído com sucesso.'
          : 'O treino "$trainingTitle" ($details) foi excluído com sucesso.';

  return showDialog<void>(
    context: context,
    builder:
        (_) => AppDialog(
          icon: Icons.check_circle_outline,
          iconColor: Colors.green.shade600,
          title: 'Treino excluído',
          message: fullMessage,
          primaryAction: TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.lightBlue),
            child: const Text('OK'),
          ),
        ),
  );
}
