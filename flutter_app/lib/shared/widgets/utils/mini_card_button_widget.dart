import 'package:flutter/material.dart';

class MiniCardButtonWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color iconColor;

  const MiniCardButtonWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.textColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // 🔹 encolhe ao conteúdo
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1, // 🔹 garante uma linha
          overflow: TextOverflow.ellipsis, // 🔹 evita overflow
          softWrap: false,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ).copyWith(color: textColor),
        ),
      ],
    );
  }
}
