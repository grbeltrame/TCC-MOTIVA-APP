// lib/shared/widgets/date_selector.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/services/workout/training_service.dart'; // você cria esse service
import 'package:flutter_app/core/constants/app_colors.dart';

/// Um botão que permite navegar dia a dia.
/// Exibe dd/MM/yyyy e nome do dia da semana;
/// arrows para mudar um dia.
/// Chama onDateChanged quando a data muda.
/// Internamente faz fetch dos treinos via TrainingService (mock).
class DateSelector extends StatefulWidget {
  /// Data inicial ao criar o widget.
  final DateTime initialDate;

  /// Opcional: callback para notificar o pai de que a data mudou.
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

  void _fetchWorkouts() {
    // TODO: implementar no backend: buscar treinos do dia _selectedDate
    TrainingService.fetchWorkoutsForDate(_selectedDate).then((workouts) {
      // você pode armazenar em algum estado ou notificar via outro callback
    });
  }

  void _changeDate(int offsetDays) {
    setState(
      () => _selectedDate = _selectedDate.add(Duration(days: offsetDays)),
    );
    widget.onDateChanged?.call(_selectedDate);
    _fetchWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final dayLabel = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final rawWeekday = DateFormat.EEEE('pt_BR').format(_selectedDate);
    final weekday = toBeginningOfSentenceCase(rawWeekday) ?? rawWeekday;

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
            // seta para trás
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

            // data e dia da semana
            Column(
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

            SizedBox(width: 8 * scale),

            // seta para frente
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
