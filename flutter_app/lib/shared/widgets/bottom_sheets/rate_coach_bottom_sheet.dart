// lib/shared/widgets/bottom_sheets/rate_coach_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/dialogs/feedback_thanks_dialog.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/core/services/users/coach/coach_feedback_service.dart';

/// Abra com:
/// await showRateCoachBottomSheet(
///   context,
///   coachId: 'c1',
///   coachName: 'Fulano',
///   classId: 'class_123',
///   date: DateTime.now(),
/// );
Future<void> showRateCoachBottomSheet(
  BuildContext context, {
  required String coachId,
  required String coachName,
  required String classId,
  required DateTime date,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => RateCoachBottomSheet(
          coachId: coachId,
          coachName: coachName,
          classId: classId,
          date: date,
        ),
  );
}

class RateCoachBottomSheet extends StatefulWidget {
  const RateCoachBottomSheet({
    Key? key,
    required this.coachId,
    required this.coachName,
    required this.classId,
    required this.date,
  }) : super(key: key);

  final String coachId;
  final String coachName;
  final String classId;
  final DateTime date;

  @override
  State<RateCoachBottomSheet> createState() => _RateCoachBottomSheetState();
}

class _RateCoachBottomSheetState extends State<RateCoachBottomSheet> {
  int _rating = 0; // 0..5
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      await CoachFeedbackService.submitCoachRating(
        coachId: widget.coachId,
        classId: widget.classId,
        date: widget.date,
        rating: _rating,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // fecha o bottom sheet

      // Mostra o diálogo de agradecimento
      await showFeedbackThanksDialog(
        context,
        coachName: widget.coachName,
        timeLabel:
            null, // se quiser mostrar o horário, passe aqui (ex.: '07:00')
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao enviar. Tente novamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AppBottomSheet(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20 * scale,
          16 * scale,
          20 * scale,
          (16 * scale) + bottomInset,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              'O que você achou da aula do Coach ${widget.coachName}?',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
                height: 1.2,
              ),
            ),
            SizedBox(height: 12 * scale),

            _StarRow(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),

            SizedBox(height: 16 * scale),

            Text(
              'Pode nos dar um feedback?',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 8 * scale),

            TextField(
              controller: _commentCtrl,
              maxLines: 5,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText:
                    'Conte como foi a aula, o que curtiu e o que podemos melhorar…',
                isDense: true,
                contentPadding: EdgeInsets.all(10 * scale),
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
                  borderSide: BorderSide(
                    color: AppColors.mediumGray.withOpacity(.9),
                    width: 1,
                  ),
                ),
              ),
            ),

            SizedBox(height: 16 * scale),

            ElevatedButton(
              style: AppTheme.secondaryButtonStyle(
                AppColors.darkBlue,
                AppColors.baseBlue,
              ),
              onPressed: () => _submit(),
              child: const Text('Enviar'),
            ),

            SizedBox(height: 16 * scale),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.value, required this.onChanged});

  final int value; // 0..5
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    Widget buildStar(int index) {
      final filled = index < value;
      return InkWell(
        onTap: () {
          if (index == 0 && value == 1) {
            onChanged(0); // toque na primeira estrela quando já era 1 → zera
          } else {
            onChanged(index + 1);
          }
        },
        borderRadius: BorderRadius.circular(20 * scale),
        child: Padding(
          padding: EdgeInsets.all(4 * scale),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 28 * scale,
            color: filled ? AppColors.baseBlue : AppColors.mediumGray,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        for (var i = 0; i < 5; i++) buildStar(i),
        TextButton(
          onPressed: () => onChanged(0),
          child: Text(
            'Limpar',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
        ),
      ],
    );
  }
}
