import 'package:flutter/material.dart';

class MiniCardButtonWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color iconColor;
  final VoidCallback? onPressed;

  const MiniCardButtonWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.textColor,
    required this.iconColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ).copyWith(color: textColor),
        ),
      ],
    );

    // se tiver onPressed, vira botão; senão, só renderiza o conteúdo visual
    if (onPressed == null) return content;

    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: content,
    );
  }
}
