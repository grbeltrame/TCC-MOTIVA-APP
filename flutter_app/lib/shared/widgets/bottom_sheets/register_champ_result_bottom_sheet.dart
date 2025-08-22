// lib/shared/widgets/bottom_sheets/register_champ_result_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/championship_service.dart';
import 'package:flutter_app/shared/models/championship.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/dialogs/championship_results_feedback_dialogs.dart';

Future<bool?> showRegisterChampResultBottomSheet(
  BuildContext context, {
  required Championship championship,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _RegisterChampResultSheet(championship: championship),
  );
}

class _RegisterChampResultSheet extends StatefulWidget {
  const _RegisterChampResultSheet({super.key, required this.championship});
  final Championship championship;

  @override
  State<_RegisterChampResultSheet> createState() =>
      _RegisterChampResultSheetState();
}

class _RegisterChampResultSheetState extends State<_RegisterChampResultSheet> {
  int _participants = 20;
  int _placement = 20;

  /// Slider único 1..10 para o "como se sentiu"
  double _feeling = 7;

  bool _submitting = false;

  // Helpers de UI
  Widget _pillCounter({
    required int value,
    required VoidCallback onDec,
    required VoidCallback onInc,
    double? width,
  }) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Container(
      width: width ?? 160 * scale,
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
      decoration: BoxDecoration(
        color: AppColors.baseBlue.withAlpha(40),
        border: Border.all(color: AppColors.baseBlue),
        borderRadius: BorderRadius.circular(24 * scale),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _roundIconButton(Icons.remove, onDec),
          Text(
            '$value',
            style: TextStyle(
              fontFamily: AppFonts.montserrat,
              fontWeight: AppFontWeight.bold,
              fontSize: 18 * scale,
              color: AppColors.darkText,
            ),
          ),
          _roundIconButton(Icons.add, onInc),
        ],
      ),
    );
  }

  Widget _roundIconButton(IconData icon, VoidCallback onTap) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18 * scale),
      child: Container(
        width: 28 * scale,
        height: 28 * scale,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.baseBlue),
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18 * scale, color: AppColors.baseBlue),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      await ChampionshipService.submitChampionshipResult(
        championshipId: widget.championship.id,
        totalCompetitors: _participants,
        placement: _placement,
        feelingScore: _feeling.round(), // 1..10
      );

      if (!mounted) return;

      // Regra do diálogo: <=6 keep going ; >=7 congrats
      if (_feeling.round() <= 6) {
        await showChampKeepGoingDialog(context, widget.championship.name);
      } else {
        await showChampCongratsDialog(context, widget.championship.name);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true); // informa sucesso ao chamador
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falha ao registrar resultado. Tente novamente.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final fmt = DateFormat('dd/MM/yyyy');

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
            // handle
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

            // Título + nome
            Text(
              'Você está cadastrando seu resultado no campeonato:',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 16 * scale,
                color: AppColors.darkText,
                height: 1.2,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              widget.championship.name.toUpperCase(),
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 2 * scale),
            Text(
              fmt.format(widget.championship.startDate),
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.medium,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),

            SizedBox(height: 18 * scale),

            // Pergunta 1
            Text(
              'Quantos competidores haviam na sua categoria?',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 8 * scale),
            Center(
              child: _pillCounter(
                value: _participants,
                onDec:
                    () => setState(() {
                      if (_participants > 1) {
                        _participants--;
                        if (_placement > _participants) {
                          _placement = _participants;
                        }
                      }
                    }),
                onInc: () => setState(() => _participants++),
              ),
            ),

            SizedBox(height: 18 * scale),

            // Pergunta 2
            Text(
              'Qual foi sua colocação nesse campeonato?',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 8 * scale),
            Center(
              child: _pillCounter(
                value: _placement,
                onDec:
                    () => setState(() {
                      if (_placement > 1) _placement--;
                    }),
                onInc:
                    () => setState(() {
                      final max = _participants > 1 ? _participants : 9999;
                      if (_placement < max) _placement++;
                    }),
              ),
            ),

            SizedBox(height: 18 * scale),

            // Pergunta 3 (slider único 1..10)
            Text(
              'Como você se sentiu com esse resultado?',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 16 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 6 * scale),

            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6 * scale,
                thumbShape: RoundSliderThumbShape(
                  enabledThumbRadius: 8 * scale,
                ),
                overlayShape: RoundSliderOverlayShape(
                  overlayRadius: 12 * scale,
                ),
                activeTrackColor: AppColors.baseBlue,
                inactiveTrackColor: AppColors.lightMagenta.withAlpha(120),
              ),
              child: Slider(
                value: _feeling,
                min: 1,
                max: 10,
                divisions: 9,
                label: _feeling.round().toString(),
                onChanged: (v) => setState(() => _feeling = v),
              ),
            ),

            // labels (iguais aos do mock, embaixo)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Muito insatisfeito',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 11 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Poderia ter sido melhor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 11 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Melhor impossível',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 11 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 18 * scale),

            // Botões: Registrar (estilo do app) e Fechar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: AppTheme.secondaryButtonStyle(
                      AppColors.darkBlue,
                      AppColors.baseBlue,
                    ),
                    onPressed: () {
                      // <- precisa ser um wrapper, não passar Future diretamente
                      _handleSubmit();
                    },
                    child: Text(
                      _submitting ? 'Enviando…' : 'Registrar',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.baseMagenta),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * scale),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12 * scale),
                    ),
                    child: Text(
                      'Fechar',
                      style: TextStyle(
                        fontFamily: AppFonts.montserrat,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 16 * scale,
                        color: AppColors.baseMagenta,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelTiny(String t, double scale) => Flexible(
    child: Text(
      t,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: AppFonts.roboto,
        fontSize: 10 * scale,
        color: AppColors.mediumGray,
        height: 1.1,
      ),
    ),
  );
}
