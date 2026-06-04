// lib/shared/widgets/date_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

/// Um botão que permite navegar dia a dia.
/// Exibe dd/MM/yyyy e nome do dia da semana;
/// arrows para mudar um dia.
/// Clicar no centro abre um calendário (DatePicker).
class DateSelector extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime>? onDateChanged;

  DateSelector({Key? key, DateTime? initialDate, this.onDateChanged})
    : initialDate = initialDate ?? DateTime.now(),
      super(key: key);

  @override
  State<DateSelector> createState() => _DateSelectorState();
}

class _DateSelectorState extends State<DateSelector> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _fetchWorkouts();
  }

  // Se a data mudar externamente (pelo pai), atualizamos o estado interno
  @override
  void didUpdateWidget(covariant DateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      setState(() {
        _selectedDate = widget.initialDate;
      });
    }
  }

  void _fetchWorkouts() {
    // TODO: implementar no backend: buscar treinos do dia _selectedDate
    TrainingService.fetchWorkoutsForDate(_selectedDate).then((workouts) {
      // logica de bolinhas (se houver)
    });
  }

  void _changeDate(int offsetDays) {
    setState(
      () => _selectedDate = _selectedDate.add(Duration(days: offsetDays)),
    );
    _notifyChange();
  }

  // NOVO: Abre o calendário para seleção rápida
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // Limite inferior (ajuste se quiser)
      lastDate: DateTime(now.year + 2), // Limite superior
      builder: (context, child) {
        // Personaliza a cor do calendário para azul (se quiser)
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1), // Azul escuro do app
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _notifyChange();
    }
  }

  void _notifyChange() {
    widget.onDateChanged?.call(_selectedDate);
    _fetchWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final dayLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final rawWeekday = DateFormat.EEEE('pt_BR').format(_selectedDate);
    final weekday = toBeginningOfSentenceCase(rawWeekday);

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
              onPressed: () => _changeDate(-1),
            ),

            SizedBox(width: 8 * scale),

            // CENTRO CLICÁVEL (Abre Calendário)
            GestureDetector(
              onTap: _pickDate, // <--- AQUI ESTÁ A MÁGICA
              behavior: HitTestBehavior.opaque, // Melhora a área de toque
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mediumGray,
                    ),
                  ),
                  Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: AppColors.darkText,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ],
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
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// VARIAÇÃO A — CycleAwareDateSelector
/// (Também atualizado com calendário)
/// ===============================================================
class CycleAwareDateSelector extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime>? onDateChanged;
  final void Function(int year, int month)? onMonthChanged;

  const CycleAwareDateSelector({
    Key? key,
    required this.initialDate,
    this.onDateChanged,
    this.onMonthChanged,
  }) : super(key: key);

  @override
  State<CycleAwareDateSelector> createState() => _CycleAwareDateSelectorState();
}

class _CycleAwareDateSelectorState extends State<CycleAwareDateSelector> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  // Garante sincronia se o pai mudar a data
  @override
  void didUpdateWidget(covariant CycleAwareDateSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate) {
      setState(() {
        _selectedDate = widget.initialDate;
      });
    }
  }

  void _changeDate(int offsetDays) {
    final next = _selectedDate.add(Duration(days: offsetDays));
    _updateDate(next);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
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

    if (picked != null && picked != _selectedDate) {
      _updateDate(picked);
    }
  }

  void _updateDate(DateTime next) {
    final prevMonth = _selectedDate.month;
    final prevYear = _selectedDate.year;

    setState(() => _selectedDate = next);
    widget.onDateChanged?.call(_selectedDate);

    if (next.month != prevMonth || next.year != prevYear) {
      widget.onMonthChanged?.call(next.year, next.month);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final dayLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final rawWeekday = DateFormat.EEEE('pt_BR').format(_selectedDate);
    final weekday = toBeginningOfSentenceCase(rawWeekday);

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
              onPressed: () => _changeDate(-1),
            ),
            SizedBox(width: 8 * scale),

            // CENTRO CLICÁVEL
            GestureDetector(
              onTap: _pickDate,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 10 * scale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.mediumGray,
                    ),
                  ),
                  Text(
                    weekday,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: AppColors.darkText,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ],
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
              onPressed: () => _changeDate(1),
            ),
          ],
        ),
      ),
    );
  }
}
