import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/box.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/category_training_section.dart';
import 'package:flutter_app/shared/widgets/utils/icon_text_action_button.dart';
import 'package:flutter_app/shared/widgets/utils/primary_button.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:flutter_app/shared/widgets/utils/date_selector.dart';

/// Seção responsável por:
///  • listar/selecionar o "Box:" do aluno
///  • notificar a tela pai via onBoxChanged(Box) e onDateChanged(DateTime)
///  • exibir botão de cadastro se não houver nenhum box.
class TrainingInfoSection extends StatefulWidget {
  /// Chamado sempre que o aluno seleciona ou cadastra um box.
  final ValueChanged<Box> onBoxChanged;

  /// Chamado sempre que o aluno muda a data.
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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadBoxes();
    // notifica a data inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDateChanged(_selectedDate);
    });
  }

  Future<void> _loadBoxes() async {
    final list = await TrainingService.fetchUserBoxes();
    setState(() {
      _boxes = list;
      // se houver exatamente 1, já seleciona e notifica
      if (_boxes.isNotEmpty) {
        _selectedBox = _boxes.first;
        widget.onBoxChanged(_selectedBox!);
      }
    });
  }

  Future<void> _onRegisterBox() async {
    // TODO: exibir bottom sheet para cadastro real
    final novo = await TrainingService.registerBox('Nome do Box');
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

        // dentro do build da TrainingInfoSection, logo após o CategoryTrainingSection:
        SizedBox(height: 12 * scale),
        Align(
          alignment: Alignment.center,
          child: PrimaryButton(
            label: 'Ver turmas do dia',
            onPressed: () {},
          ), //redirecionar para pagina de turmas com info do profressores e informar qual turma deseja
        ),
        SizedBox(height: 12 * scale),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // “Não treinei hoje”
            OutlinedButton(
              onPressed: () {
                /* TODO: ação Não treinei hoje */
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
                /* TODO: ação Não treinei hoje */
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
