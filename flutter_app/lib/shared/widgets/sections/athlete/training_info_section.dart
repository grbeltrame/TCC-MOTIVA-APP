// lib/shared/widgets/sections/athlete/training_info_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/features/user/athlete/athlete_classes_screen.dart';
import 'package:flutter_app/shared/models/box.dart';
import 'package:flutter_app/shared/models/class.dart';
import 'package:flutter_app/shared/widgets/dialogs/activity_status_dialogs.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/category_training_section.dart';
import 'package:flutter_app/shared/widgets/utils/primary_button.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:flutter_app/shared/widgets/utils/date_selector.dart';
import 'package:flutter_app/shared/widgets/cards/interested_class_card.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/rate_coach_bottom_sheet.dart';

// 🚨 novo: vamos buscar o coach certo da turma
import 'package:flutter_app/core/services/users/coach/coach_service.dart';

class TrainingInfoSection extends StatefulWidget {
  final ValueChanged<Box> onBoxChanged;
  final ValueChanged<DateTime> onDateChanged;

  const TrainingInfoSection({
    Key? key,
    required this.onBoxChanged,
    required this.onDateChanged,
  }) : super(key: key);

  @override
  _TrainingInfoSectionState createState() => _TrainingInfoSectionState();
}

class _TrainingInfoSectionState extends State<TrainingInfoSection> {
  List<Box> _boxes = [];
  Box? _selectedBox;

  // Estado para o date selector
  late DateTime _selectedDate;

  // Interesses do dia
  List<InterestedClass> _interests = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadBoxes();
    // notifica a data inicial + carrega interesses
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateChanged(_selectedDate);
      _reloadInterests();
    });
  }

  Future<void> _reloadInterests() async {
    final list = await ClassInterestService.fetchInterestsForDate(
      _selectedDate,
    );
    if (!mounted) return;
    setState(() => _interests = list);
  }

  Future<void> _loadBoxes() async {
    final list = await TrainingService.fetchUserBoxes();
    if (!mounted) return;
    setState(() {
      _boxes = list;
      if (_boxes.isNotEmpty) {
        _selectedBox = _boxes.first;
        widget.onBoxChanged(_selectedBox!);
      }
    });
  }

  Future<void> _onRegisterBox() async {
    final novo = await TrainingService.registerBox('Nome do Box');
    if (!mounted) return;
    setState(() {
      _boxes.add(novo);
      _selectedBox = novo;
    });
    widget.onBoxChanged(novo);
  }

  void _onBoxSelected(Box? box) {
    if (box == null) return;
    setState(() => _selectedBox = box);
    widget.onBoxChanged(box);
  }

  void _onDateChanged(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
    });
    widget.onDateChanged(newDate);
    _reloadInterests(); // atualiza card(s) ao trocar a data
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Linha de Box:
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: Row(
            children: [
              Text(
                'Box:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(width: 8 * scale),
              if (_boxes.isEmpty)
                TextActionButton(
                  icon: Icons.add,
                  text: 'Cadastrar-se em um box',
                  onPressed:
                      () => showAppBottomSheet(context, const BoxSignupCoach()),
                )
              else if (_boxes.length == 1)
                Text(
                  _boxes.first.name,
                  style: TextStyle(
                    fontSize: 14 * scale,
                    fontWeight: AppFontWeight.bold,
                  ),
                )
              else
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.arrow_drop_down, color: AppColors.darkBlue),
                      SizedBox(width: 4 * scale),
                      Expanded(
                        child: DropdownButton<Box>(
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          icon: const SizedBox.shrink(),
                          hint: Text(
                            'Selecione box',
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          value: _selectedBox,
                          items:
                              _boxes
                                  .map(
                                    (b) => DropdownMenuItem<Box>(
                                      value: b,
                                      child: Text(b.name),
                                    ),
                                  )
                                  .toList(),
                          onChanged: _onBoxSelected,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        SizedBox(height: 4 * scale),

        // Linha de seleção de data:
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * scale),
          child: DateSelector(
            initialDate: _selectedDate,
            onDateChanged: _onDateChanged,
          ),
        ),

        SizedBox(height: 4 * scale),

        // Tabs com as categorias de treinos
        if (_selectedBox != null)
          CategoryTrainingSection(boxId: _selectedBox!.id, date: _selectedDate),

        SizedBox(height: 12 * scale),

        // ====== Cards de interesse (só aparecem se houver pelo menos 1) ======
        if (_interests.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * scale),
            child: Column(
              children:
                  _interests.map((it) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 10 * scale),
                      child: InterestedClassCard(
                        timeLabel: it.timeLabel,
                        category: it.category,
                        coachName: it.coachName,
                        // 1) Trocar horário: navega primeiro; quando voltar, recarrega
                        onChangeTime: () async {
                          await Navigator.of(context).pushNamed(
                            ClassesOfDayScreen.routeName,
                            arguments: {'date': _selectedDate},
                          );
                          await _reloadInterests();
                        },
                        // 2) Registrar resultado: abre o bottom sheet
                        onRegisterResult: () async {
                          await showRegisterResultBottomSheet(context);
                        },
                        // 3) Avaliar professor: busca coach correto e abre o BS
                        onRateCoach: () async {
                          try {
                            // Se seu modelo já tiver coachId, use direto:
                            // final coachId = it.coachId;
                            // Caso contrário, buscamos pelo classId:
                            final coach = await CoachService.fetchCoachForClass(
                              it.classId,
                            );

                            await showRateCoachBottomSheet(
                              context,
                              coachId: coach.id,
                              coachName: coach.name,
                              classId: it.classId,
                              date: _selectedDate,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Não foi possível abrir a avaliação.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          SizedBox(height: 4 * scale),
        ],

        // ===== Botão “Ver turmas do dia" =====
        Align(
          alignment: Alignment.center,
          child: PrimaryButton(
            label: 'Ver turmas do dia',
            onPressed: () async {
              await Navigator.of(context).pushNamed(
                ClassesOfDayScreen.routeName,
                arguments: {'date': _selectedDate},
              );
              await _reloadInterests();
            },
          ),
        ),
        SizedBox(height: 12 * scale),

        // ===== Ações de status do dia =====
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // “Não treinei hoje”
            OutlinedButton(
              onPressed: () {
                showDidNotTrainDialog(context, date: _selectedDate);
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.lightMagenta.withAlpha(50),
                side: BorderSide(color: AppColors.baseMagenta),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 8 * scale,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Não treinei hoje',
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  color: AppColors.baseMagenta,
                ),
              ),
            ),
            SizedBox(width: 16 * scale),

            // “Fiz outra atividade física”
            OutlinedButton(
              onPressed: () {
                showOtherActivityDialog(
                  context,
                  date: _selectedDate,
                  description: 'Caminhada leve',
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.baseBlue.withAlpha(50),
                side: BorderSide(color: AppColors.baseBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * scale),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scale,
                  vertical: 8 * scale,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Fiz outra atividade física',
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  color: AppColors.baseBlue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
