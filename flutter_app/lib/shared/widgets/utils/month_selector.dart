import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seletor de MÊS (MMM/yyyy) no estilo do DateSelector.
/// Usa setas para ir e voltar um mês.
/// Clicar no texto central abre um calendário focado em ano/mês.
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
  static const int _firstAllowedYear = 2020;

  DateTime get _defaultMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  DateTime get _firstAllowedMonth => DateTime(_firstAllowedYear);

  DateTime get _lastAllowedMonth {
    final now = DateTime.now();
    return DateTime(now.year + 2, 12);
  }

  @override
  void initState() {
    super.initState();
    _month = _safeMonth(widget.initialMonth);
  }

  // Garante que se a data mudar externamente, o widget atualiza
  @override
  void didUpdateWidget(covariant MonthSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMonth != oldWidget.initialMonth) {
      _normalizeDate(widget.initialMonth);
    }
  }

  void _normalizeDate(DateTime date) {
    final normalized = _safeMonth(date);
    setState(() {
      _month = normalized;
    });
  }

  void _changeMonth(int delta) {
    final newDate = DateTime(_month.year, _month.month + delta);
    if (!_isAllowedMonth(newDate)) return;
    _updateDate(newDate);
  }

  // Abre o calendário nativo já no modo de Ano para facilitar
  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final firstDate = _firstAllowedMonth;
    final lastDate = DateTime(now.year + 2, 12, 31);
    final initialDate = _isAllowedMonth(_month) ? _month : _defaultMonth;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode:
          DatePickerMode.year, // Abre mostrando os Anos primeiro
      builder: (context, child) {
        // Mantém o tema azul consistente com o app
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateDate(picked);
    }
  }

  void _updateDate(DateTime date) {
    final normalized = _safeMonth(date);
    setState(() {
      _month = normalized;
    });
    widget.onMonthChanged?.call(normalized);
  }

  DateTime _safeMonth(DateTime date) {
    final normalized = DateTime(date.year, date.month);
    if (_isAllowedMonth(normalized)) return normalized;
    return _defaultMonth;
  }

  bool _isAllowedMonth(DateTime date) {
    final normalized = DateTime(date.year, date.month);
    return !normalized.isBefore(_firstAllowedMonth) &&
        !normalized.isAfter(_lastAllowedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final formatter = DateFormat('MMMM yyyy', 'pt_BR');
    var label = formatter.format(_month);
    // Primeira letra maiúscula (ex: fevereiro -> Fevereiro)
    label = toBeginningOfSentenceCase(label) ?? label;
    final canGoPrevious = _isAllowedMonth(
      DateTime(_month.year, _month.month - 1),
    );
    final canGoNext = _isAllowedMonth(DateTime(_month.year, _month.month + 1));

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
            // Seta Esquerda
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: 24 * scale,
                height: 24 * scale,
              ),
              icon: Icon(Icons.navigate_before, size: 24 * scale),
              onPressed: canGoPrevious ? () => _changeMonth(-1) : null,
            ),

            SizedBox(width: 8 * scale),

            // Texto Central Clicável
            GestureDetector(
              onTap: _pickMonth, // Abre o calendário
              behavior: HitTestBehavior.opaque,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: AppColors.darkText,
                  fontWeight: AppFontWeight.bold,
                  fontFamily: AppFonts.roboto, // Garantindo a fonte correta
                ),
              ),
            ),

            SizedBox(width: 8 * scale),

            // Seta Direita
            IconButton(
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tightFor(
                width: 24 * scale,
                height: 24 * scale,
              ),
              icon: Icon(Icons.navigate_next, size: 24 * scale),
              onPressed: canGoNext ? () => _changeMonth(1) : null,
            ),
          ],
        ),
      ),
    );
  }
}
