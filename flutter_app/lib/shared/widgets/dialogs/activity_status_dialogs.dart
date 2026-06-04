import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/services/activity_log_services.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/other_activity_bottom_sheet.dart';

/// "Fiz outra atividade" — mostra parabéns + botão para cadastrar.
/// Não salva nada aqui — o save acontece no bottom sheet.
Future<void> showOtherActivityDialog(
  BuildContext context, {
  DateTime? date,
  String? description,
}) async {
  final resolvedDate = date ?? DateTime.now();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (ctx) => AppDialog(
          icon: Icons.auto_awesome,
          iconColor: AppColors.darkBlue,
          title: 'Parabéns por se manter em movimento',
          message:
              'Seu momento esportivo diário é importante para manter sua saúde mental e física.\n\n'
              'Que bom que manteve o foco, esse é o caminho!',
          primaryAction: TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fechar'),
          ),
          secondaryAction: TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await showOtherActivityBottomSheet(context, date: resolvedDate);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.baseBlue),
            child: const Text('Cadastrar atividade'),
          ),
        ),
  );
}

/// "Não treinei hoje" — só salva quando o usuário confirma.
Future<void> showDidNotTrainDialog(
  BuildContext context, {
  DateTime? date,
}) async {
  final resolvedDate = date ?? DateTime.now();

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder:
        (ctx) => AppDialog(
          icon: Icons.wb_sunny_outlined,
          iconColor: AppColors.darkBlue,
          title: 'Descanso também faz parte da evolução',
          message:
              'Dias sem treino são importantes para manter o corpo e a mente bem!\n\n'
              'Estaremos aqui quando voltar para mais dias de movimento.\n\n'
              'Aproveite sua folga',
          primaryAction: TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Salva só após confirmação
              ActivityLogService.logDidNotTrain(
                date: resolvedDate,
              ).catchError((_) {});
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.baseBlue),
            child: const Text('Registrar descanso'),
          ),
          secondaryAction: TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Sair'),
          ),
        ),
  );
}
