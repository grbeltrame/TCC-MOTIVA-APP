import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

/// Um BottomSheet estilizado para todo o app.
/// Recebe qualquer widget de conteúdo através de `child`.
class AppBottomSheet extends StatelessWidget {
  final Widget child;

  const AppBottomSheet({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Garante que o teclado não sobreponha o conteúdo
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: child,
      ),
    );
  }
}

/// Função auxiliar para exibir qualquer BottomSheet com o estilo do app.
Future<T?> showAppBottomSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AppBottomSheet(child: child),
  );
}
