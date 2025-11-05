import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seletor de MÊS (MMM/yyyy) no estilo do DateSelector.
/// Usa setas para ir e voltar um mês.
/// - [initialMonth]: qualquer DateTime, usamos apenas year/month.
/// - [onMonthChanged]: notificado com DateTime(normalizado para dia 1).
class MonthSelector extends StatefulWidget {
  final DateTime initialMonth;
  final ValueChanged<DateTime>? onMonthChanged;

  MonthSelector({super.key, DateTime? initialMonth, this.onMonthChanged})
    : initialMonth = initialMonth ?? DateTime.now();

  @override
  State<MonthSelector> createState() => _MonthSelectorState();
}

class _MonthSelectorState extends State<MonthSelector> {
  late DateTime _month; // sempre normalizado para dia 1

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialMonth.year, widget.initialMonth.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
    widget.onMonthChanged?.call(_month);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final formatter = DateFormat('MMMM yyyy', 'pt_BR');
    var label = formatter.format(_month);
    // Primeira letra maiúscula
    label = label[0].toUpperCase() + label.substring(1);

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
              onPressed: () => _changeMonth(-1),
            ),
            SizedBox(width: 8 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 14 * scale,
                color: AppColors.darkText,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            SizedBox(width: 8 * scale),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: 24 * scale,
                height: 24 * scale,
              ),
              icon: Icon(Icons.navigate_next, size: 24 * scale),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),
      ),
    );
  }
}
