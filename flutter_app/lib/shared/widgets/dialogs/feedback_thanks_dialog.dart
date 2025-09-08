import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';

/// Mostra um dialog de agradecimento pelo envio do feedback.
/// Use: await showFeedbackThanksDialog(context, coachName: 'Fulano', timeLabel: '07:00');
Future<void> showFeedbackThanksDialog(
  BuildContext context, {
  String? coachName,
  String? timeLabel,
}) async {
  final title = 'Obrigado pelo feedback!';
  final who =
      [
        if (coachName != null && coachName.trim().isNotEmpty)
          ' sobre a aula do Coach $coachName',
        if (timeLabel != null && timeLabel.trim().isNotEmpty) ' ($timeLabel)',
      ].join();

  final message =
      'Sua avaliação$who foi enviada com sucesso.\n\n'
      'Ela ajuda muito na evolução do box e também na sua própria jornada!';

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder:
        (dialogCtx) => AppDialog(
          icon: Icons.thumb_up_alt_rounded,
          iconColor: AppColors.darkBlue,
          title: title,
          message: message,
          primaryAction: TextButton(
            onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
            style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
            child: const Text('Fechar'),
          ),
        ),
  );
}
