import 'package:flutter/material.dart';
import 'package:flutter_app/routes/app_routes.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/models/training.dart';

class CoachDailyTrainingsSection extends StatefulWidget {
  final String boxId;
  final DateTime date;

  const CoachDailyTrainingsSection({
    super.key,
    required this.boxId,
    required this.date,
  });

  @override
  State<CoachDailyTrainingsSection> createState() =>
      _CoachDailyTrainingsSectionState();
}

class _CoachDailyTrainingsSectionState
    extends State<CoachDailyTrainingsSection> {
  late Stream<List<Training>> _trainingsStream;

  @override
  void initState() {
    super.initState();
    _trainingsStream = _watchTrainings(widget.date);
  }

  @override
  void didUpdateWidget(covariant CoachDailyTrainingsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      setState(() {
        _trainingsStream = _watchTrainings(widget.date);
      });
    }
  }

  Stream<List<Training>> _watchTrainings(DateTime date) {
    return TrainingService.watchTrainingsListForDate(
      boxId: widget.boxId,
      date: date,
      includeDrafts: true,
    );
  }

  void _openDetail(Training training) {
    // Passamos o objeto inteiro ou o ID.
    // Aqui mantive a lógica de passar argumentos, mas agora focada no treino específico.
    Navigator.of(context).pushNamed(
      AppRoutes.coachTrainingDetail,
      arguments: {
        'training': training, // Passa o objeto completo se sua rota suportar
        'date': widget.date,
        'boxId': widget.boxId,
        // Se precisar manter a compatibilidade com 'category',
        // enviamos a categoria principal desse treino
        'category': _determineMainCategory(training),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return StreamBuilder<List<Training>>(
      stream: _trainingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 20 * scale),
            child: Center(
              child: Text(
                'Não foi possível carregar os treinos agora.',
                style: TextStyle(
                  color: AppColors.mediumGray,
                  fontSize: 14 * scale,
                  fontFamily: AppFonts.roboto,
                ),
              ),
            ),
          );
        }

        final dailyTrainings = snapshot.data ?? const <Training>[];

        if (dailyTrainings.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 20 * scale),
            child: Center(
              child: Text(
                'Nenhum treino programado para este dia.',
                style: TextStyle(
                  color: AppColors.mediumGray,
                  fontSize: 14 * scale,
                  fontFamily: AppFonts.roboto,
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Treinos do Dia',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 4 * scale),
            Text(
              'Toque para ver detalhes e registrar resultados.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 12 * scale),

            Column(
              children:
                  dailyTrainings.map((training) {
                    return _TrainingTypeButton(
                      label: _generateButtonTitle(training),
                      status: training.status,
                      onPressed: () => _openDetail(training),
                    );
                  }).toList(),
            ),
          ],
        );
      },
    );
  }

  /// Define qual nome vai aparecer no botão baseado no conteúdo do JSON
  String _generateButtonTitle(Training training) {
    // Acessa o mapa de partes (WOD, SKILL, EXTRA)
    // Supondo que no seu model 'partes' seja um Map<String, dynamic> ou similar
    final partes = training.partes;

    // REGRA 1: Se tem WOD, ele é o principal.
    if (partes.containsKey('WOD')) {
      final wodPart = partes['WOD'];
      // Tenta pegar o nome do WOD (ex: "THE NEW GOD")
      String? nomeWod;
      if (wodPart is Map) {
        nomeWod = wodPart['nomeWod'];
      } else {
        // Ajuste conforme seu model real se 'wodPart' for um objeto
        nomeWod = wodPart.nomeWod;
      }

      if (nomeWod != null && nomeWod.isNotEmpty) {
        return "WOD - ${nomeWod.toUpperCase()}";
      }
      return "WOD DO DIA";
    }

    // REGRA 2: Se não tem WOD, mas tem LPO (documento separado de LPO)
    // Supondo que a chave no JSON venha como "LPO" ou "LPO_CLASS"
    if (partes.containsKey('LPO')) {
      return "LPO CLASS";
    }

    // REGRA 3: Se não tem WOD, mas tem Ginástica
    if (partes.containsKey('GINASTICA') || partes.containsKey('SKILL')) {
      return "GINÁSTICA / SKILL";
    }

    // REGRA 4: Caso genérico (Endurance, etc)
    if (partes.containsKey('ENDURANCE')) {
      return "ENDURANCE";
    }

    return "TREINO DO DIA";
  }

  /// Função auxiliar para determinar categoria para navegação
  String _determineMainCategory(Training training) {
    if (training.partes.containsKey('WOD')) return 'WOD';
    if (training.partes.containsKey('LPO')) return 'LPO';
    if (training.partes.containsKey('GINASTICA')) return 'Ginastica';
    return 'WOD';
  }
}

// O BOTÃO AZUL (MANTIDO INTACTO)
class _TrainingTypeButton extends StatelessWidget {
  final String label;
  final String status;
  final VoidCallback onPressed;

  const _TrainingTypeButton({
    required this.label,
    required this.status,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: SizedBox(
        height: 50 * scale,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1), // Azul Escuro
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label, // Ex: "WOD - THE NEW GOD"
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 15 * scale,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16 * scale,
              ),
              if (status != 'publicado') ...[
                SizedBox(width: 8 * scale),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8 * scale,
                    vertical: 3 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8 * scale),
                  ),
                  child: Text(
                    'Rascunho',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.w700,
                      fontSize: 10 * scale,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
