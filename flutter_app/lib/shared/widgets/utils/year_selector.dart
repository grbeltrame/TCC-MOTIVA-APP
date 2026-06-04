import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seletor de ano no mesmo estilo do DateSelector:
/// - pill cinza claro
/// - borda preta
/// - setas para mudar ano
/// - chama onYearChanged
class YearSelector extends StatefulWidget {
  final int initialYear;
  final ValueChanged<int>? onYearChanged;

  const YearSelector({
    super.key,
    required this.initialYear,
    this.onYearChanged,
  });

  @override
  State<YearSelector> createState() => _YearSelectorState();
}

class _YearSelectorState extends State<YearSelector> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
  }

  void _changeYear(int offset) {
    setState(() => _year = _year + offset);
    widget.onYearChanged?.call(_year);

    // TODO(back): se precisar, buscar ciclos do ano aqui (ou no pai)
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 4 * scale,
        ),
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
              onPressed: () => _changeYear(-1),
            ),
            SizedBox(width: 12 * scale),
            Text(
              '$_year',
              style: TextStyle(
                fontSize: 14 * scale,
                color: AppColors.darkText,
                fontWeight: AppFontWeight.bold,
                fontFamily: AppFonts.roboto,
              ),
            ),
            SizedBox(width: 12 * scale),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: 24 * scale,
                height: 24 * scale,
              ),
              icon: Icon(Icons.navigate_next, size: 24 * scale),
              onPressed: () => _changeYear(1),
            ),
          ],
        ),
      ),
    );
  }
}
