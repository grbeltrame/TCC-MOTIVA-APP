// lib/shared/widgets/app_bottom_sheet.dart
import 'package:flutter/material.dart';

/// Wrapper de todo BottomSheet do app
class AppBottomSheet extends StatelessWidget {
  final Widget child;
  const AppBottomSheet({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      // empurra o conteúdo quando abre o teclado
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Helper para abrir qualquer bottom sheet com o estilo do app
Future<T?> showAppBottomSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => child,
  );
}
