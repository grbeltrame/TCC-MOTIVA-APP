// lib/shared/models/daily_workout_model.dart

class DailyWorkoutModel {
  final String boxId;
  final String dateText; // "01 DEZEMBRO"
  final String weekDay; // "SEGUNDA FEIRA"
  final Map<String, WorkoutPart> parts; // Onde ficam WOD, SKILL, etc.

  DailyWorkoutModel({
    required this.boxId,
    required this.dateText,
    required this.weekDay,
    required this.parts,
  });

  factory DailyWorkoutModel.fromJson(Map<String, dynamic> json) {
    final partsMap = <String, WorkoutPart>{};

    if (json['partes'] != null) {
      (json['partes'] as Map<String, dynamic>).forEach((key, value) {
        partsMap[key] = WorkoutPart.fromJson(value);
      });
    }

    return DailyWorkoutModel(
      boxId: json['boxId'] ?? '',
      dateText: json['dataDoTreinoTexto'] ?? '',
      weekDay: json['diaDaSemana'] ?? '',
      parts: partsMap,
    );
  }
}

class ExerciseItem {
  /// String de exibição original — usada por toda a UI existente.
  /// Ex: "15 KTB swing (24Kg|18Kg)"
  final String raw;

  /// Tipo do item no parser novo: exercise, note, segment, penalty.
  final String kind;

  // --- Campos estruturados (disponíveis apenas no schema novo) ---

  /// Nome do exercício sem quantidade/carga. Ex: "KTB swing"
  final String? nome;

  /// Quantidade numérica. Ex: 15, 500
  final int? quantidade;

  /// String de ratio. Ex: "10:10"
  final String? quantidadeRatio;

  /// "reps" ou "metros"
  final String unidade;

  /// Carga RX. Ex: "24Kg"
  final String? cargaRx;

  /// Carga Scaled. Ex: "18Kg"
  final String? cargaScaled;

  const ExerciseItem({
    required this.raw,
    this.kind = 'exercise',
    this.nome,
    this.quantidade,
    this.quantidadeRatio,
    this.unidade = 'reps',
    this.cargaRx,
    this.cargaScaled,
  });

  /// Compatibilidade: retorna a string de exibição diretamente.
  @override
  String toString() => raw;

  factory ExerciseItem.fromJson(dynamic json) {
    // Schema ANTIGO: o exercício já é uma String
    if (json is String) {
      return ExerciseItem(raw: json, nome: json);
    }

    // Schema NOVO: o exercício é um Map com campos estruturados
    if (json is Map<String, dynamic>) {
      final raw = json['raw']?.toString() ?? json['nome']?.toString() ?? '';

      // Quantidade pode ser int ou string (ratio "10:10")
      int? quantidade;
      String? quantidadeRatio;
      final qtdRaw = json['quantidade'];
      if (qtdRaw is int) {
        quantidade = qtdRaw;
      } else if (qtdRaw is String && qtdRaw.contains(':')) {
        quantidadeRatio = qtdRaw;
      }

      return ExerciseItem(
        raw: raw,
        kind: json['kind']?.toString() ?? 'exercise',
        nome: json['nome']?.toString(),
        quantidade: quantidade,
        quantidadeRatio: quantidadeRatio,
        unidade: json['unidade']?.toString() ?? 'reps',
        cargaRx: json['cargaRx']?.toString(),
        cargaScaled: json['cargaScaled']?.toString(),
      );
    }

    // Fallback inesperado
    return ExerciseItem(raw: json.toString(), nome: json.toString());
  }
}

class WorkoutPart {
  /// Para schema antigo: valor de 'tipo' (ex: "AMRAP", "WOD").
  /// Para schema novo: valor de 'modalidade' com fallback para 'secao'.
  /// Usado para manter compatibilidade com código existente.
  final String type;

  /// Seção do treino. Ex: "WARM UP", "WOD". (schema novo)
  final String? secao;

  /// Modalidade real do treino. Ex: "AMRAP", "3 ROUNDS FOR TIME". (schema novo)
  final String? modalidade;

  /// Número de rounds quando especificado. Ex: 3. (schema novo)
  final int? rounds;

  /// Nome do WOD. Ex: "SKY IS THE LIMIT"
  final String? wodName;

  final int? durationMinutes;

  /// Lista de strings para exibição na UI — compatível com todo o código existente.
  /// Cada item é o campo 'raw' do ExerciseItem.
  final List<String> exercises;

  /// Lista estruturada com todos os campos (carga, unidade, etc.).
  /// Use para funcionalidades novas que precisem de dados ricos.
  final List<ExerciseItem> exercisesStructured;

  final String? observations;

  WorkoutPart({
    required this.type,
    this.secao,
    this.modalidade,
    this.rounds,
    this.wodName,
    this.durationMinutes,
    required this.exercises,
    required this.exercisesStructured,
    this.observations,
  });

  factory WorkoutPart.fromJson(Map<String, dynamic> json) {
    // --- Detecta schema pelo campo 'secao' (exclusivo do schema novo) ---
    final bool isNewSchema = json.containsKey('secao');

    // --- type: usado por todo o código legado ---
    // No schema novo, prioriza 'modalidade'. Fallback para 'secao'.
    // No schema antigo, usa 'tipo' diretamente.
    final String type =
        isNewSchema
            ? (json['modalidade']?.toString() ??
                json['secao']?.toString() ??
                '')
            : (json['tipo']?.toString() ?? '');

    // --- Converte exercícios suportando ambos os formatos ---
    final rawList = (json['exercicios'] as List?) ?? [];
    final List<ExerciseItem> structured =
        rawList.map((e) => ExerciseItem.fromJson(e)).toList();

    // Lista de strings para a UI existente (TrainingBlock.items)
    final List<String> displayList = structured.map((e) => e.raw).toList();

    return WorkoutPart(
      type: type,
      secao: isNewSchema ? json['secao']?.toString() : null,
      modalidade: isNewSchema ? json['modalidade']?.toString() : null,
      rounds: isNewSchema ? json['rounds'] as int? : null,
      wodName: json['nomeWod']?.toString(),
      durationMinutes: json['duracaoMinutos'] as int?,
      exercises: displayList,
      exercisesStructured: structured,
      observations: json['observacoes']?.toString(),
    );
  }
}
