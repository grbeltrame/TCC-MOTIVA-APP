// lib/core/services/workout/muscles_service.dart
import 'dart:async';
import 'package:flutter_app/shared/models/worked_muscle.dart';
import 'package:flutter_app/shared/models/training_block.dart';

/// Service responsável por retornar os músculos trabalhados
/// nos movimentos do último bloco do treino.
/// TODO(back): substituir mapeamentos estáticos por payload real da API.
class MusclesService {
  /// Mapeia nome de movimento → { músculo → [assets] }.
  /// Obs.: os assets listados abaixo devem existir em /assets/muscles/...
  /// Você pode começar com poucos movimentos e ir expandindo.
  static const Map<String, Map<String, List<String>>> _movementToMuscles = {
    'Snatch': {
      'Dorsal': [
        'assets/muscles/snatch/dorsal_1.png',
        'assets/muscles/snatch/dorsal_2.png',
      ],
      'Deltoides': [
        'assets/muscles/snatch/deltoides_1.png',
        'assets/muscles/snatch/deltoides_2.png',
      ],
      'Quadríceps': [
        'assets/muscles/snatch/quadriceps_1.png',
        'assets/muscles/snatch/quadriceps_2.png',
      ],
      'Glúteos': [
        'assets/muscles/snatch/gluteos_1.png',
        'assets/muscles/snatch/gluteos_2.png',
      ],
      'Core': [
        'assets/muscles/snatch/core_1.png',
        'assets/muscles/snatch/core_2.png',
      ],
    },
    'Pull-up': {
      'Dorsal': [
        'assets/muscles/pullup/dorsal_1.png',
        'assets/muscles/pullup/dorsal_2.png',
      ],
      'Bíceps': [
        'assets/muscles/pullup/biceps_1.png',
        'assets/muscles/pullup/biceps_2.png',
      ],
      'Deltoides': [
        'assets/muscles/pullup/deltoides_1.png',
        'assets/muscles/pullup/deltoides_2.png',
      ],
      'Core': [
        'assets/muscles/pullup/core_1.png',
        'assets/muscles/pullup/core_2.png',
      ],
    },
    'Burpee': {
      'Peitoral': [
        'assets/muscles/burpee/peitoral_1.png',
        'assets/muscles/burpee/peitoral_2.png',
      ],
      'Deltoides': [
        'assets/muscles/burpee/deltoides_1.png',
        'assets/muscles/burpee/deltoides_2.png',
      ],
      'Quadríceps': [
        'assets/muscles/burpee/quadriceps_1.png',
        'assets/muscles/burpee/quadriceps_2.png',
      ],
      'Core': [
        'assets/muscles/burpee/core_1.png',
        'assets/muscles/burpee/core_2.png',
      ],
      'Glúteos': [
        'assets/muscles/burpee/gluteos_1.png',
        'assets/muscles/burpee/gluteos_2.png',
      ],
    },
  };

  /// Extrai possíveis nomes de movimentos a partir das linhas de um bloco.
  /// Bem tolerante: ignora quantidades, cargas e sinalizadores como “@”.
  static List<String> _guessMovements(List<String> lines) {
    final results = <String>[];
    for (final raw in lines) {
      var s = raw;
      final at = s.indexOf('@');
      if (at != -1) s = s.substring(0, at);
      // remove contagens iniciais (ex.: "21", "5x3", "3×10", "40s")
      s = s.replaceAll(
        RegExp(r'(^|\s)(\d+[x×]?\d*|[0-9]+s)\s*', caseSensitive: false),
        ' ',
      );
      s = s.trim();

      // tenta casar com alguma key do nosso dicionário
      for (final mv in _movementToMuscles.keys) {
        final re = RegExp('\\b${RegExp.escape(mv)}\\b', caseSensitive: false);
        if (re.hasMatch(s)) {
          results.add(mv);
          break;
        }
      }
    }
    return results.toSet().toList(); // únicos
  }

  /// Retorna uma lista de WorkedMuscle (músculo → imagens) consolidando
  /// os movimentos detectados no último bloco do treino informado.
  static Future<List<WorkedMuscle>> fetchWorkedMusclesForLastBlock(
    TrainingBlock lastBlock,
  ) async {
    await Future.delayed(const Duration(milliseconds: 120)); // mock de latência
    final movements = _guessMovements(lastBlock.items);
    final out = <WorkedMuscle>[];

    for (final mv in movements) {
      final map = _movementToMuscles[mv];
      if (map == null) continue;
      map.forEach((muscle, imgs) {
        out.add(
          WorkedMuscle(muscle: muscle, movement: mv, imageAssetPaths: imgs),
        );
      });
    }

    return out;
  }
}
