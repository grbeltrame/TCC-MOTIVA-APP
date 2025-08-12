import 'dart:async';
import 'dart:math';
import 'package:flutter_app/shared/models/box.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:intl/intl.dart';

class TrainingService {
  /// Retorna a lista de boxes em que o usuário está cadastrado.
  static Future<List<Box>> fetchUserBoxes() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: substituir por chamada real ao backend
    return [
      Box(id: '1', name: 'Olympus Crossfit'),
      Box(id: '2', name: 'Spartan Gym'),
    ];
  }

  /// Retorna um mapa categoria → último bloco de treino do dia
  /// TODO: substituir por chamada real ao backend.
  static Future<Map<String, TrainingBlock?>>
  fetchTrainingBlocksByCategoryForDate({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simula latência

    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final Map<String, TrainingBlock?> result = {};

    // Mock de ultimo bloco para cada categoria:
    result['WOD'] = TrainingBlock(
      title: 'WOD “Fran”',
      subtitle: '$formattedDate – 21-15-9 Thrusters e Pull-ups',
      items: [
        '21 Thrusters 43kg',
        '21 Pull-ups',
        '15 Thrusters 43kg',
        '15 Pull-ups',
        '9 Thrusters 43kg',
        '9 Pull-ups',
      ],
    );

    result['LPO'] = TrainingBlock(
      title: 'Olympic Lifts',
      subtitle: '$formattedDate – Técnica e força',
      items: [
        '5×2 Snatch @ técnica',
        '5×3 Clean & Jerk @ 70%',
        '3×1 Snatch Balance',
      ],
    );

    result['Ginastica'] = TrainingBlock(
      title: 'Ginástica',
      subtitle: '$formattedDate – Habilidades corporais',
      items: [
        '5×5 Pull-ups estritos',
        '4×4 Handstand Push-ups',
        '3×10 Toes-to-Bar',
      ],
    );

    result['Endurance'] = TrainingBlock(
      title: 'Endurance',
      subtitle: '$formattedDate – Cardio intenso',
      items: [
        '10 min AMRAP de Double-Unders',
        '5 min Remo',
        '800m Corrida leve',
      ],
    );

    return result;
  }

  /// Registra um novo box para o usuário.
  static Future<Box> registerBox(String boxName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: chamar API de cadastro e retornar o Box criado
    return Box(id: 'novo', name: boxName);
  }

  /// Busca os treinos do dia [date] para o box [boxId].
  static Future<List<Training>> fetchTrainingsForBox({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: buscar treinos reais do backend
    return [
      // Exemplo de mock:
      Training(
        id: 't1',
        title: 'WOD “Fran”',
        description: '21-15-9 Thrusters 43kg e Pull-ups',
        date: date,
      ),
      Training(
        id: 't2',
        title: 'Strength',
        description: 'Back Squat 5x5 @ 75%',
        date: date,
      ),
    ];
  }

  /// TODO: chamar sua API para buscar treino(s) do dia [date]
  static Future<List<dynamic>> fetchWorkoutsForDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return []; // substitua por lista de treinos
  }

  /// Retorna um mapa categoria → último treino do dia (ou null se não houver).
  /// Mock: cada dia metade das categorias terá treino, as outras ficarão nulas.
  /// TODO: substituir por chamada real ao backend.
  static Future<Map<String, Training?>> fetchTrainingsByCategoryForDate({
    required String boxId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // simula latência

    final categories = ['WOD', 'LPO', 'Ginastica', 'Endurance'];
    final rnd = Random(date.day + date.month);
    final Map<String, Training?> result = {};

    for (var cat in categories) {
      if (rnd.nextBool()) {
        result[cat] = Training(
          id: '${cat.toLowerCase()}_${date.toIso8601String()}',
          title: cat,
          description:
              'Último bloco de treino de $cat em ${DateFormat('dd/MM/yyyy').format(date)}',
          date: date,
        );
      } else {
        result[cat] = null;
      }
    }

    return result;
  }
}

/// Resumo de um treino para o card “resumo do dia”.
class DailyWorkoutSummary {
  final String category; // ex.: WOD, LPO, Ginastica, Endurance
  final List<String> stimuli; // ex.: ['Força', 'Cardio']
  final String objectiveShort; // texto curtíssimo
  final String quote; // frase motivacional

  DailyWorkoutSummary({
    required this.category,
    required this.stimuli,
    required this.objectiveShort,
    required this.quote,
  });
}

extension DailySummaries on TrainingService {
  /// Retorna os resumos de treino do dia por box.
  /// Usa os dados já existentes, mas preenche "stimuli/objective/quote" com mocks.
  /// TODO (backend): substituir por payload real com fields equivalentes.
  static Future<List<DailyWorkoutSummary>> fetchDailyWorkoutSummariesForBox({
    required String boxId,
    required DateTime date,
  }) async {
    // Podemos decidir com base em quais categorias têm bloco hoje:
    final blocks = await TrainingService.fetchTrainingBlocksByCategoryForDate(
      boxId: boxId,
      date: date,
    );

    final List<DailyWorkoutSummary> list = [];

    for (final entry in blocks.entries) {
      final cat = entry.key;
      final hasBlock = entry.value != null;
      if (!hasBlock) continue;

      // MOCKS por categoria — troque por dados reais quando houver
      switch (cat) {
        case 'WOD':
          list.add(
            DailyWorkoutSummary(
              category: 'WOD',
              stimuli: ['Força', 'Cardio'],
              objectiveShort: 'Clean e resistência em rounds longos',
              quote: 'Consistência vence intensidade. Hoje é mais um passo.',
            ),
          );
          break;
        case 'LPO':
          list.add(
            DailyWorkoutSummary(
              category: 'LPO',
              stimuli: ['Técnica', 'Força'],
              objectiveShort: 'Arranco leve + base de força',
              quote: 'Qualidade > quantidade — refine cada repetição.',
            ),
          );
          break;
        case 'Ginastica':
          list.add(
            DailyWorkoutSummary(
              category: 'Ginástica',
              stimuli: ['Técnica', 'Controle'],
              objectiveShort: 'Pull-up estrito e estabilidade em HS',
              quote: 'Controle do corpo, mente tranquila.',
            ),
          );
          break;
        case 'Endurance':
          list.add(
            DailyWorkoutSummary(
              category: 'Endurance',
              stimuli: ['Cardio'],
              objectiveShort: 'Pacing constante no metcon longo',
              quote: 'Respire, mantenha o ritmo e termine forte.',
            ),
          );
          break;
        default:
          // fallback
          list.add(
            DailyWorkoutSummary(
              category: cat,
              stimuli: ['Geral'],
              objectiveShort: 'Trabalho técnico do dia',
              quote: 'Um pouco por dia leva longe.',
            ),
          );
      }
    }

    // Se nenhuma categoria tiver bloco hoje, retorna lista vazia:
    return list;
  }
}
