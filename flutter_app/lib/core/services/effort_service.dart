// lib/core/services/effort_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/core/services/weekly_summary_service.dart';

/// Um ponto por dia, com valor de esforço (1–10)
class DailyEffort {
  final DateTime date;
  final double percent;
  DailyEffort(this.date, this.percent);
}

// =============================================================================
// Model do resultado registrado pelo atleta
// =============================================================================

class AthleteResultRecord {
  // Referência ao treino
  final String date; // "2026-03-16"
  final String wodType; // "WOD" | "LPO" | "Ginástica" | "Endurance"
  final String? wodName; // "HEAVEN IN HELL"
  final String? modalidade; // "FOR TIME" | "AMRAP" | "EMOM"
  final List<String> keyMetrics; // ["Força", "Potência"]
  final String? trainingDocId; // ID do doc em exercises/

  // Registro do atleta
  final String trainingTime; // "06:30"
  final String category; // "Iniciante" | "Scale" | "Intermediário" | "RX"
  final bool adapted;
  final bool completed;

  // Resultado condicional por modalidade
  final int? forTimeSec;
  final int? amrapRounds;
  final int? amrapReps;
  final int? emomCompletedRounds;

  // Esforço
  final int effort; // 1-10

  // Adaptações
  final List<Map<String, dynamic>> adaptations;

  // Metadados
  final String? dayOfWeek; // "QUARTA FEIRA"

  const AthleteResultRecord({
    required this.date,
    required this.wodType,
    this.wodName,
    this.modalidade,
    this.keyMetrics = const [],
    this.trainingDocId,
    required this.trainingTime,
    required this.category,
    required this.adapted,
    required this.completed,
    this.forTimeSec,
    this.amrapRounds,
    this.amrapReps,
    this.emomCompletedRounds,
    required this.effort,
    this.adaptations = const [],
    this.dayOfWeek,
  });

  Map<String, dynamic> toFirestore() => {
    // Referência ao treino
    'date': date,
    'wodType': wodType,
    'wodName': wodName,
    'modalidade': modalidade,
    'keyMetrics': keyMetrics,
    'trainingDocId': trainingDocId,

    // Registro do atleta
    'trainingTime': trainingTime,
    'category': category,
    'adapted': adapted,
    'completed': completed,

    // Resultado condicional
    'forTimeSec': forTimeSec,
    'amrapRounds': amrapRounds,
    'amrapReps': amrapReps,
    'emomCompletedRounds': emomCompletedRounds,

    // Esforço
    'effort': effort,

    // Adaptações
    'adaptations': adaptations,

    // Metadados para IA
    'dayOfWeek': dayOfWeek,
    'registeredAt': FieldValue.serverTimestamp(),
  };

  /// Reconstrói o model a partir de um documento do Firestore.
  factory AthleteResultRecord.fromFirestore(Map<String, dynamic> data) {
    return AthleteResultRecord(
      date: data['date'] ?? '',
      wodType: data['wodType'] ?? '',
      wodName: data['wodName'],
      modalidade: data['modalidade'],
      keyMetrics: List<String>.from(data['keyMetrics'] ?? []),
      trainingDocId: data['trainingDocId'],
      trainingTime: data['trainingTime'] ?? '',
      category: data['category'] ?? '',
      adapted: data['adapted'] ?? false,
      completed: data['completed'] ?? false,
      forTimeSec: data['forTimeSec'],
      amrapRounds: data['amrapRounds'],
      amrapReps: data['amrapReps'],
      emomCompletedRounds: data['emomCompletedRounds'],
      effort: data['effort'] ?? 5,
      adaptations:
          (data['adaptations'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .toList(),
      dayOfWeek: data['dayOfWeek'],
    );
  }
}

// =============================================================================
// EffortService
// =============================================================================

class EffortService {
  // ── Helpers internos ────────────────────────────────────────────────────────

  /// UID do usuário logado. Lança se não estiver logado.
  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não logado');
    return uid;
  }

  /// Referência à subcoleção results do atleta logado.
  static CollectionReference<Map<String, dynamic>> get _resultsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('results');

  /// Formata a data como "yyyy-MM-dd" para uso como chave.
  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// ID do documento: "{date}_{wodType}" — ex: "2026-03-16_WOD"
  static String _docId(DateTime date, String wodType) =>
      '${_dateKey(date)}_$wodType';

  // ── Métodos de leitura ──────────────────────────────────────────────────────

  /// Verifica se o atleta já registrou o resultado do WOD de hoje.
  /// Retorna o registro se existir, null se não existir.
  /// Usado pelo PendingActionsService para decidir o estado do card.
  static Future<AthleteResultRecord?> fetchTodayResult({
    DateTime? date,
    String wodType = 'WOD',
  }) async {
    try {
      final day = date ?? DateTime.now();
      final doc = await _resultsRef.doc(_docId(day, wodType)).get();
      if (!doc.exists || doc.data() == null) return null;
      return AthleteResultRecord.fromFirestore(doc.data()!);
    } catch (e) {
      print('ERRO fetchTodayResult: $e');
      return null;
    }
  }

  // ── Métodos de escrita ──────────────────────────────────────────────────────

  /// Salva o resultado completo do atleta em users/{uid}/results/{date}_{wodType}.
  /// Sobrescreve se já existir (atleta pode editar o registro do dia).
  static Future<void> submitResult(AthleteResultRecord record) async {
    try {
      final date = DateTime.parse(record.date);
      final docId = _docId(date, record.wodType);
      await _resultsRef.doc(docId).set(record.toFirestore());
      print('✅ Resultado salvo: $docId');
    } catch (e) {
      print('ERRO submitResult: $e');
      rethrow; // propaga para o UI tratar
    }
  }

  // ── Métodos existentes mantidos ─────────────────────────────────────────────

  /// Retorna 7 pontos (domingo→sábado) com valores hard‑coded por enquanto.
  /// TODO: trocar por leitura real de users/{uid}/results/ quando fase 2 chegar.
  Future<List<DailyEffort>> fetchWeeklyEffortSeries(WeekRange week) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final start = week.start;
    return List.generate(7, (i) {
      final dia = start.add(Duration(days: i));
      final raw = 50 + i * 5;
      final scaled = raw / 10;
      return DailyEffort(dia, scaled.clamp(1.0, 10.0));
    });
  }

  /// Valor padrão do esforço (1..10).
  /// TODO: buscar último registro do atleta quando fase 2 chegar.
  Future<int> fetchDefaultEffort() async {
    await Future.delayed(const Duration(milliseconds: 120));
    return 5;
  }

  /// Mantido por compatibilidade — redireciona para submitResult.
  /// @deprecated Use submitResult() diretamente.
  Future<void> submitEffort({
    required int effort,
    String? classId,
    required DateTime date,
  }) async {
    // Mantido para não quebrar referências existentes enquanto
    // o register_result_bottom_sheet não for refatorado (passo 3).
    await Future.delayed(const Duration(milliseconds: 240));
  }
}
