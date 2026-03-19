// lib/shared/widgets/bottom_sheets/other_activity_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/activity_log_services.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/shared/widgets/register_result/section_effort.dart';

// =============================================================================
// Lista de atividades disponíveis
// =============================================================================

const _kActivities = [
  'Cross',
  'Corrida',
  'Funcional',
  'Caminhada',
  'Bicicleta',
  'Musculação',
  'Natação',
  'Outro',
];

// =============================================================================
// Função pública de abertura
// =============================================================================

Future<void> showOtherActivityBottomSheet(
  BuildContext context, {
  required DateTime date,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _OtherActivityContent(date: date),
  );
}

// =============================================================================
// Widget principal
// =============================================================================

class _OtherActivityContent extends StatefulWidget {
  const _OtherActivityContent({required this.date});
  final DateTime date;

  @override
  State<_OtherActivityContent> createState() => _OtherActivityContentState();
}

class _OtherActivityContentState extends State<_OtherActivityContent> {
  String? _selectedActivity;
  TimeOfDay? _trainingTime;
  final _durationController = TextEditingController();
  final _otherActivityController = TextEditingController();
  int _effortValue = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _durationController.dispose();
    _otherActivityController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _trainingTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      builder:
          (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
    );
    if (picked != null) setState(() => _trainingTime = picked);
  }

  Future<void> _handleRegister(BuildContext sheetContext) async {
    if (_selectedActivity == null) {
      ScaffoldMessenger.of(
        sheetContext,
      ).showSnackBar(const SnackBar(content: Text('Selecione uma atividade')));
      return;
    }

    // Se "Outro", usa o texto livre
    final activityName =
        _selectedActivity == 'Outro'
            ? _otherActivityController.text.trim()
            : _selectedActivity!;

    if (_selectedActivity == 'Outro' && activityName.isEmpty) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Descreva a atividade que você fez')),
      );
      return;
    }
    if (_trainingTime == null) {
      ScaffoldMessenger.of(sheetContext).showSnackBar(
        const SnackBar(content: Text('Informe o horário que treinou')),
      );
      return;
    }

    final durationText = _durationController.text.trim();
    final duration = int.tryParse(durationText) ?? 0;

    setState(() => _submitting = true);
    try {
      await ActivityLogService.logOtherActivity(
        date: widget.date,
        activity: activityName,
        trainingTime: _formatTime(_trainingTime!),
        durationMinutes: duration,
        effort: _effortValue,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          sheetContext,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
      setState(() => _submitting = false);
      return;
    }

    if (Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
    }

    await Future.microtask(() {});
    await showDialog(
      context: sheetContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AppDialog(
            icon: Icons.auto_awesome,
            iconColor: AppColors.darkBlue,
            title: 'Parabéns por se manter em movimento!',
            message:
                'Seu momento esportivo diário é importante para manter sua saúde mental e física.\n\n'
                'Que bom que manteve o foco, esse é o caminho!',
            primaryAction: TextButton(
              onPressed:
                  () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
              child: const Text('OK'),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final pad = EdgeInsets.fromLTRB(
      16 * scale,
      10 * scale,
      16 * scale,
      16 * scale,
    );

    return AppBottomSheet(
      child: Padding(
        padding: pad,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40 * scale,
                height: 4 * scale,
                decoration: BoxDecoration(
                  color: AppColors.mediumGray.withOpacity(.6),
                  borderRadius: BorderRadius.circular(2 * scale),
                ),
              ),
            ),
            SizedBox(height: 12 * scale),

            Text(
              'Que atividade você fez?',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 16 * scale),

            // ── Grid de atividades ────────────────────────────────────────
            Wrap(
              spacing: 8 * scale,
              runSpacing: 8 * scale,
              children:
                  _kActivities.map((activity) {
                    final selected = _selectedActivity == activity;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedActivity = activity),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12 * scale,
                          vertical: 8 * scale,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? AppColors.baseBlue.withOpacity(0.1)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8 * scale),
                          border: Border.all(
                            color:
                                selected
                                    ? AppColors.baseBlue
                                    : AppColors.mediumGray.withOpacity(0.5),
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          activity,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 13 * scale,
                            fontWeight:
                                selected
                                    ? AppFontWeight.bold
                                    : AppFontWeight.regular,
                            color:
                                selected
                                    ? AppColors.baseBlue
                                    : AppColors.darkText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            SizedBox(height: 20 * scale),

            // Campo de texto livre quando "Outro" selecionado
            if (_selectedActivity == 'Outro') ...[
              TextField(
                controller: _otherActivityController,
                decoration: InputDecoration(
                  hintText: 'Descreva a atividade...',
                  hintStyle: TextStyle(
                    color: AppColors.mediumGray,
                    fontSize: 13 * scale,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                    borderSide: BorderSide(
                      color: AppColors.baseBlue.withOpacity(0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8 * scale),
                    borderSide: BorderSide(color: AppColors.baseBlue),
                  ),
                  filled: true,
                  fillColor: AppColors.baseBlue.withOpacity(0.04),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 10 * scale,
                  ),
                ),
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 13 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 8 * scale),
            ],

            Divider(color: AppColors.mediumGray.withOpacity(0.2), height: 1),
            SizedBox(height: 16 * scale),

            // ── Horário + Duração lado a lado ─────────────────────────────
            Wrap(
              spacing: 16 * scale,
              runSpacing: 8 * scale,
              children: [
                // Horário
                _buildInlineField(
                  label: 'Que horas treinou?:',
                  scale: scale,
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: _fieldBox(
                      scale: scale,
                      child: Text(
                        _trainingTime != null
                            ? _formatTime(_trainingTime!)
                            : '--:--',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 13 * scale,
                          fontWeight: AppFontWeight.medium,
                          color:
                              _trainingTime != null
                                  ? AppColors.darkText
                                  : AppColors.mediumGray,
                        ),
                      ),
                    ),
                  ),
                ),

                // Duração
                _buildInlineField(
                  label: 'Duração (min):',
                  scale: scale,
                  child: _fieldBox(
                    scale: scale,
                    width: 64 * scale,
                    child: TextField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 13 * scale,
                        fontWeight: AppFontWeight.medium,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16 * scale),
            Divider(color: AppColors.mediumGray.withOpacity(0.2), height: 1),
            SizedBox(height: 8 * scale),

            // ── Esforço ───────────────────────────────────────────────────
            SectionEffort(
              classId: null,
              onEffortChanged: (val) => setState(() => _effortValue = val),
            ),

            SizedBox(height: 16 * scale),

            // ── Botão registrar ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: AppTheme.secondaryButtonStyle(
                  AppColors.darkBlue,
                  AppColors.baseBlue,
                ),
                onPressed: _submitting ? null : () => _handleRegister(context),
                child:
                    _submitting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: const Text('Registrar atividade'),
                        ),
              ),
            ),

            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 13 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              ),
            ),

            SizedBox(height: 8 * scale),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineField({
    required String label,
    required double scale,
    required Widget child,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.bold,
            fontSize: 12 * scale,
            color: AppColors.mediumGray,
          ),
        ),
        SizedBox(width: 8 * scale),
        child,
      ],
    );
  }

  Widget _fieldBox({
    required double scale,
    required Widget child,
    double? width,
  }) {
    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      padding: EdgeInsets.symmetric(
        horizontal: 8 * scale,
        vertical: width != null ? 0 : 6 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.baseBlue.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(
          color: AppColors.baseBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
