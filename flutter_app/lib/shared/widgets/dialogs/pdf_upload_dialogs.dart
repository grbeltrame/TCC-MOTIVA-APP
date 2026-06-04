import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
// AppDialog fica em mocks (mantendo seu padrão)
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';

/// Sucesso no envio do PDF — fecha apenas o dialog.
/// O bottom sheet decide se deve fechar e qual resultado retornar.
Future<void> showPdfUploadSuccessDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AppDialog(
        icon: Icons.check_circle_outline,
        iconColor: AppColors.darkBlue,
        title: 'PDF enviado com sucesso!',
        message:
            'Recebemos o seu arquivo. Os treinos serão importados como rascunho para revisão do coach.',
        primaryAction: TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      );
    },
  );
}

/// Erro no envio do PDF — fecha só o dialog (sheet continua aberto).
Future<void> showPdfUploadErrorDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return AppDialog(
        icon: Icons.error_outline,
        iconColor: AppColors.baseMagenta,
        title: 'Falha ao enviar PDF',
        message:
            'Não foi possível concluir o envio agora. Verifique sua conexão e tente novamente.',
        primaryAction: TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Tentar novamente'),
        ),
      );
    },
  );
}
