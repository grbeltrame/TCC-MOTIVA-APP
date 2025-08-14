import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

/// Campo numérico compacto (pode receber controller ou valor inicial).
class MiniNumberField extends StatefulWidget {
  const MiniNumberField({
    super.key,
    this.controller,
    this.value,
    this.suffix,
    required this.onChanged,
  });

  final TextEditingController? controller;
  final int? value;
  final String? suffix; // 'kg', 'reps' ou vazio
  final ValueChanged<int> onChanged;

  @override
  State<MiniNumberField> createState() => _MiniNumberFieldState();
}

class _MiniNumberFieldState extends State<MiniNumberField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl =
        widget.controller ??
        TextEditingController(text: '${widget.value ?? 1}');
    _ctrl.addListener(_notify);
  }

  @override
  void didUpdateWidget(covariant MiniNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.value != widget.value) {
      _ctrl.text = '${widget.value ?? 1}';
    }
  }

  void _notify() {
    final v = int.tryParse(_ctrl.text) ?? (widget.value ?? 1);
    widget.onChanged(v);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_notify);
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return SizedBox(
      width: 80 * scale,
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 8 * scale,
            vertical: 8 * scale,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8 * scale),
            borderSide: BorderSide(color: AppColors.mediumGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8 * scale),
            borderSide: BorderSide(color: AppColors.mediumGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8 * scale),
            borderSide: BorderSide(color: AppColors.baseBlue, width: 1.4),
          ),
          suffixText: widget.suffix,
        ),
        onChanged: (_) => _notify(),
      ),
    );
  }
}
