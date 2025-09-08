import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/activity_log_services.dart';

import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';

/// Abre o dialog para o caso "fez outra atividade física".
/// Dispara o registro no backend em background (não trava a UI).
Future<void> showOtherActivityDialog(
  BuildContext context, {
  DateTime? date,
  String? description,
}) async {
  // dispara o registro sem bloquear a abertura do diálogo
  ActivityLogService.logOtherActivity(
    date: date ?? DateTime.now(),
    description: description,
  ).catchError((_) {
    /* opcional: log */
  });

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AppDialog(
        icon: Icons.auto_awesome, // ícone "estrela/sol" do mock
        iconColor: AppColors.darkBlue,
        title: 'Parabéns por se manter em movimento',
        message:
            'Seu momento esportivo diário é importante para manter sua saúde mental e física.\n\n'
            'Que bom que manteve o foco, esse é o caminho!',
        primaryAction: TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      );
    },
  );
}

/// Abre o dialog para o caso "não treinou".
/// Dispara o registro no backend em background (não trava a UI).
Future<void> showDidNotTrainDialog(
  BuildContext context, {
  DateTime? date,
}) async {
  ActivityLogService.logDidNotTrain(date: date ?? DateTime.now()).catchError((
    _,
  ) {
    /* opcional: log */
  });

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AppDialog(
        icon: Icons.wb_sunny_outlined, // ícone "sol" do mock de descanso
        iconColor: AppColors.darkBlue,
        title: 'Descanso também faz parte da evolução',
        message:
            'Dias sem treino são importantes para manter o corpo e a mente bem!\n\n'
            'Estaremos aqui quando voltar para mais dias de movimento.\n\n'
            'Aproveite sua folga',
        primaryAction: TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      );
    },
  );
}
