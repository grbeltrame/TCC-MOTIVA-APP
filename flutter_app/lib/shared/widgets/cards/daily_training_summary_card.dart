// lib/shared/widgets/daily_training_summary_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/box.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';

class DailyTrainingSummaryCard extends StatefulWidget {
  const DailyTrainingSummaryCard({Key? key}) : super(key: key);

  @override
  State<DailyTrainingSummaryCard> createState() =>
      _DailyTrainingSummaryCardState();
}

class _DailyTrainingSummaryCardState extends State<DailyTrainingSummaryCard> {
  String? _selectedBoxId;
  int _currentIdx = 0;
  Timer? _rotTimer;

  @override
  void dispose() {
    _rotTimer?.cancel();
    super.dispose();
  }

  void _startRotationIfNeeded(List<DailyWorkoutSummary> items) {
    _rotTimer?.cancel();
    if (items.length <= 1) return;
    // menos rápido: 12s
    _rotTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      setState(() {
        _currentIdx = (_currentIdx + 1) % items.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<List<Box>>(
      future: TrainingService.fetchUserBoxes(),
      builder: (ctx, snapBoxes) {
        if (snapBoxes.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final boxes = snapBoxes.data ?? const <Box>[];

        // 0 boxes → CTA para cadastrar
        if (boxes.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.baseBlue),
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            padding: EdgeInsets.all(12 * scale),
            child: OutlinedButton.icon(
              onPressed:
                  () => showAppBottomSheet(context, const BoxSignupCoach()),
              icon: Icon(
                Icons.add,
                color: AppColors.baseBlue,
                size: 16 * scale,
              ),
              label: Text(
                'Cadastrar box',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.medium,
                  fontSize: 14 * scale,
                  color: AppColors.baseBlue,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.baseBlue),
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          );
        }

        _selectedBoxId ??= boxes.first.id;

        return FutureBuilder<List<DailyWorkoutSummary>>(
          future: DailySummaries.fetchDailyWorkoutSummariesForBox(
            boxId: _selectedBoxId!,
            date: DateTime.now(),
          ),
          builder: (ctx2, snapW) {
            if (snapW.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }
            final workouts = snapW.data ?? const <DailyWorkoutSummary>[];
            if (_currentIdx >= workouts.length) _currentIdx = 0;
            _startRotationIfNeeded(workouts);

            // conteúdo variável (categoria/linhas) vai dentro do AnimatedSwitcher
            Widget variableContent;
            if (workouts.isEmpty) {
              variableContent = Padding(
                key: const ValueKey('empty'),
                padding: EdgeInsets.only(top: 8 * scale),
                child: Text(
                  'Nenhum treino publicado para hoje',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.regular,
                    fontSize: 14 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              );
            } else {
              final w = workouts[_currentIdx];
              variableContent = Column(
                key: ValueKey('idx$_currentIdx-${w.category}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (workouts.length > 1) ...[
                    SizedBox(height: 6 * scale),
                    _CategoryTag(text: w.category),
                  ],
                  SizedBox(height: 8 * scale),
                  _StimulusLine(stimuli: w.stimuli),
                  SizedBox(height: 6 * scale),
                  _ObjectiveLine(text: w.objectiveShort),
                  SizedBox(height: 8 * scale),
                  _QuoteLine(text: w.quote),
                ],
              );
            }

            return Container(
              margin: EdgeInsets.only(bottom: 6 * scale), // respiro
              decoration: BoxDecoration(
                color: Colors.transparent, // fundo transparente
                border: Border.all(color: AppColors.baseBlue),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              padding: EdgeInsets.all(12 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Título (dropdown ou texto) =====
                  _BoxTitle(
                    boxes: boxes,
                    selectedId: _selectedBoxId!,
                    onChanged: (id) {
                      if (id == _selectedBoxId) return;
                      setState(() {
                        _selectedBoxId = id;
                        _currentIdx = 0;
                      });
                    },
                  ),

                  // ===== Conteúdo variável com transição suave =====
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, anim) {
                      // fade + leve slide para baixo -> cima
                      final slide = Tween<Offset>(
                        begin: const Offset(0, .06),
                        end: Offset.zero,
                      ).animate(anim);
                      return FadeTransition(
                        opacity: anim,
                        child: SlideTransition(position: slide, child: child),
                      );
                    },
                    child: variableContent,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BoxTitle extends StatelessWidget {
  final List<Box> boxes;
  final String selectedId;
  final ValueChanged<String> onChanged;
  const _BoxTitle({
    Key? key,
    required this.boxes,
    required this.selectedId,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // 1 box → só texto
    if (boxes.length == 1) {
      return Text(
        boxes.first.name,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.medium,
          fontSize: 18 * scale,
          color: AppColors.baseBlue,
        ),
      );
    }

    // 2+ boxes → dropdown estilizado
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: selectedId,
        isDense: true,
        icon: Icon(
          Icons.arrow_drop_down,
          color: AppColors.baseBlue,
          size: 18 * scale,
        ),
        items:
            boxes
                .map(
                  (b) => DropdownMenuItem(
                    value: b.id,
                    child: Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.medium,
                        fontSize: 18 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: (v) => v != null ? onChanged(v) : null,
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  final String text;
  const _CategoryTag({Key? key, required this.text}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withAlpha(50),
        border: Border.all(color: AppColors.baseBlue),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontWeight: AppFontWeight.medium,
          fontSize: 12 * scale,
          color: AppColors.darkBlue,
        ),
      ),
    );
  }
}

class _StimulusLine extends StatelessWidget {
  final List<String> stimuli;
  const _StimulusLine({Key? key, required this.stimuli}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Estímulo do dia: ',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.w600, // semibold
              fontSize: 16 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          TextSpan(
            text: stimuli.join(' + '),
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.regular,
              fontSize: 16 * scale,
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectiveLine extends StatelessWidget {
  final String text;
  const _ObjectiveLine({Key? key, required this.text}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Objetivo: ',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.medium, // medium 12dp
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.regular,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteLine extends StatelessWidget {
  final String text;
  const _QuoteLine({Key? key, required this.text}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Text(
      '“$text”',
      style: TextStyle(
        fontFamily: AppFonts.roboto,
        fontStyle: FontStyle.italic,
        fontWeight: AppFontWeight.regular,
        fontSize: 14 * scale,
        color: AppColors.mediumGray,
      ),
    );
  }
}
