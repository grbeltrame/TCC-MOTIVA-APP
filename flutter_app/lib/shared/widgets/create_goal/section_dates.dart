import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/create_goal/section_card.dart';

class SectionGoalDates extends StatelessWidget {
  const SectionGoalDates({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.noDeadline,
    required this.errorText,
    required this.onTapStartDate,
    required this.onTapEndDate,
    required this.onToggleNoDeadline,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final bool noDeadline;
  final String? errorText;
  final VoidCallback onTapStartDate;
  final VoidCallback onTapEndDate;
  final ValueChanged<bool> onToggleNoDeadline;

  String _fmt(DateTime? d) {
    if (d == null) return 'dd/mm/yyyy';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    return '$dd/$mm/$yy';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: "Informe as datas" + ícone calendário (decorativo)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Informe as datas',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 14 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 20 * scale,
                    color: AppColors.baseBlue,
                  ),
                ],
              ),
              SizedBox(height: 10 * scale),

              // Linha: Início e Fim
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Início',
                      valueText: _fmt(startDate),
                      onTap: onTapStartDate,
                      enabled: true,
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: _DateField(
                      label: 'Fim',
                      valueText: _fmt(endDate),
                      onTap: onTapEndDate,
                      enabled: !noDeadline,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10 * scale),

              Align(
                alignment: Alignment.centerLeft,
                child: ChoiceChip(
                  label: Text(
                    'Sem prazo',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 12 * scale,
                      color:
                          noDeadline ? AppColors.baseBlue : AppColors.darkBlue,
                    ),
                  ),
                  selected: noDeadline,
                  selectedColor: AppColors.baseBlue.withOpacity(0.12),
                  shape: const StadiumBorder(
                    side: BorderSide(color: Colors.transparent, width: 0),
                  ),
                  side: BorderSide(color: AppColors.baseBlue),
                  onSelected: onToggleNoDeadline,
                ),
              ),

              if (errorText != null) ...[
                SizedBox(height: 8 * scale),
                Text(
                  errorText!,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.lightMagenta,
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: 4 * scale),
        Text(
          'Ao optar por sem prazo, a meta irá se repetir sempre que for concluída, até que seja excluída.',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 12 * scale,
            color: AppColors.darkText,
            fontWeight: AppFontWeight.medium,
          ),
        ),
      ],
    );
  }
}

/// Campo de data com label azul e borda arredondada.
/// ReadOnly; abre o seletor ao tocar (via onTap).
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.valueText,
    required this.onTap,
    required this.enabled,
  });

  final String label;
  final String valueText;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final activeColor = AppColors.baseBlue;
    final disabledColor = AppColors.mediumGray;

    final baseBorderEnabled = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12 * scale),
      borderSide: BorderSide(color: activeColor),
    );
    final baseBorderDisabled = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12 * scale),
      borderSide: BorderSide(color: disabledColor),
    );

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AbsorbPointer(
        absorbing: true, // evita teclado
        child: TextField(
          readOnly: true,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * scale,
              color: enabled ? activeColor : disabledColor,
            ),
            hintText: 'dd/mm/yyyy',
            hintStyle: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 14 * scale,
              color: AppColors.mediumGray,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10 * scale,
              vertical: 10 * scale,
            ),
            border: enabled ? baseBorderEnabled : baseBorderDisabled,
            enabledBorder: baseBorderEnabled,
            disabledBorder: baseBorderDisabled,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12 * scale),
              borderSide: BorderSide(
                color: enabled ? activeColor : disabledColor,
                width: 1.4,
              ),
            ),
            suffixIcon: const SizedBox.shrink(),
          ),
          controller: TextEditingController(text: valueText),
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 14 * scale,
            color: enabled ? AppColors.darkText : disabledColor,
          ),
        ),
      ),
    );
  }
}
