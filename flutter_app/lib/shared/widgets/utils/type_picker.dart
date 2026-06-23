import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Picker de tipo (WOD/LPO/Ginastica/Endurance) visualmente parecido com o DatePicker compacto.
/// Mostra setas laterais para alternar o tipo.
class TypePicker extends StatefulWidget {
  final List<String> types;
  final String? initialType;
  final ValueChanged<String>? onChanged;

  const TypePicker({
    super.key,
    required this.types,
    this.initialType,
    this.onChanged,
  });

  @override
  State<TypePicker> createState() => _TypePickerState();
}

class _TypePickerState extends State<TypePicker> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index =
        widget.initialType != null
            ? widget.types.indexOf(widget.initialType!)
            : 0;
    if (_index < 0) _index = 0;
  }

  void _shift(int delta) {
    setState(() {
      _index = (_index + delta) % widget.types.length;
      if (_index < 0) _index = widget.types.length - 1;
    });
    widget.onChanged?.call(widget.types[_index]);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(50 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(
              width: 24 * scale,
              height: 24 * scale,
            ),
            icon: Icon(Icons.navigate_before, size: 24 * scale),
            onPressed: () => _shift(-1),
          ),
          SizedBox(width: 6 * scale),
          Text(
            widget.types[_index],
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 14 * scale,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(width: 6 * scale),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: BoxConstraints.tightFor(
              width: 24 * scale,
              height: 24 * scale,
            ),
            icon: Icon(Icons.navigate_next, size: 24 * scale),
            onPressed: () => _shift(1),
          ),
        ],
      ),
    );
  }
}
