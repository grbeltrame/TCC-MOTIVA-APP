import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seletor de data compacto (dd/MM/aaaa + ícone de calendário).
/// Cabe numa única linha junto do TextActionButton.
class CompactDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime>? onChanged;

  CompactDatePicker({super.key, DateTime? initialDate, this.onChanged})
    : initialDate = initialDate ?? DateTime.now();

  @override
  State<CompactDatePicker> createState() => _CompactDatePickerState();
}

class _CompactDatePickerState extends State<CompactDatePicker> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate;
  }

  Future<void> _openCalendar() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
      locale: const Locale('pt', 'BR'),
      helpText: 'Selecione a data',
    );
    if (picked != null) {
      setState(() => _date = picked);
      widget.onChanged?.call(_date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return InkWell(
      onTap: _openCalendar,
      borderRadius: BorderRadius.circular(8 * scale),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 10 * scale,
          vertical: 6 * scale,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.baseBlue, width: 1.2),
          borderRadius: BorderRadius.circular(8 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(_date),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                fontSize: 12 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(width: 8 * scale),
            Icon(
              Icons.calendar_today_outlined,
              size: 16 * scale,
              color: AppColors.baseBlue,
            ),
          ],
        ),
      ),
    );
  }
}
