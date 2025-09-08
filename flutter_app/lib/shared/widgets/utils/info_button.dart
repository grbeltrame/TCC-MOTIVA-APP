// lib/shared/widgets/info_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Um botão de informação que, ao ser clicado,
/// exibe uma caixinha com a mensagem passada.
class InfoButton extends StatelessWidget {
  /// Mensagem a ser exibida no diálogo
  final String message;

  /// Opcional: tamanho do ícone, padrão 20*scale
  final double? iconSize;

  const InfoButton({Key? key, required this.message, this.iconSize})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: (iconSize ?? 20 * scale),
        minHeight: (iconSize ?? 20 * scale),
      ),
      icon: Icon(
        Icons.info_outline,
        size: iconSize ?? 20 * scale,
        color: Theme.of(context).colorScheme.primary,
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 300 * scale, // ajuste à vontade
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: AppFontWeight.bold,
                    ),
                    softWrap: true,
                    textAlign: TextAlign.left, // alinhamento à esquerda
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('OK', style: TextStyle(fontSize: 14 * scale)),
                  ),
                ],
              ),
        );
      },
    );
  }
}
