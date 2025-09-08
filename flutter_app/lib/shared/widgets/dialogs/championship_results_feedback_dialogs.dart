import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

/// Mostra o dialog "Tudo bem..." (quando satisfação <= 6).
Future<void> showChampKeepGoingDialog(BuildContext context, String champName) {
  return showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder:
        (dialogCtx) => AppDialog(
          icon: Icons.sentiment_satisfied_alt,
          iconColor: AppColors.darkBlue,
          title: 'Um resultado não esperado não te define!',
          message:
              'Resultados não esperados podem ser muito frustrantes mas fazem parte da história de todo grande atleta!\n\n'
              'Agora é hora de descansar, avaliar o que não funcionou, o que deu certo e ajustar a rota para os próximos.\n\n'
              'Estamos torcendo por você!',
          primaryAction: TextButton(
            onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ),
  );
}

/// Mostra o dialog "Parabéns..." (quando satisfação >= 7).
Future<void> showChampCongratsDialog(BuildContext context, String champName) {
  return showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder:
        (dialogCtx) => AppDialog(
          icon: Icons.emoji_events,
          iconColor: AppColors.darkBlue,
          title: 'Parabéns pela excelente colocação!',
          message:
              'Todo seu trabalho bem feito surtiu o efeito desejado.\n\n'
              'Parabéns por mais essa conquista.\n\n'
              'Estaremos torcendo por você em todas as suas próximas etapas.',
          primaryAction: TextButton(
            onPressed: () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
            child: const Text('OK'),
          ),
        ),
  );
}
