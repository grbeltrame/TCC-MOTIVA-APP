// lib/core/services/effort_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/core/services/athlete_stats_service.dart';
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
  final String date;
  final String wodType;
  final String? wodName;
  final String? modalidade;
  final List<String> keyMetrics;
  final String? trainingDocId;

  final String trainingTime;
  final String category;
  final bool adapted;
  final bool completed;

  final int? forTimeSec;
  final int? amrapRounds;
  final int? amrapReps;
  final int? emomCompletedRounds;

  final int effort;

  final List<Map<String, dynamic>> adaptations;

  final String? dayOfWeek;

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
    'date': date,
    'wodType': wodType,
    'wodName': wodName,
    'modalidade': modalidade,
    'keyMetrics': keyMetrics,
    'trainingDocId': trainingDocId,
    'trainingTime': trainingTime,
    'category': category,
    'adapted': adapted,
    'completed': completed,
    'forTimeSec': forTimeSec,
    'amrapRounds': amrapRounds,
    'amrapReps': amrapReps,
    'emomCompletedRounds': emomCompletedRounds,
    'effort': effort,
    'adaptations': adaptations,
    'dayOfWeek': dayOfWeek,
    'registeredAt': FieldValue.serverTimestamp(),
  };

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
  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não logado');
    return uid;
  }

  static CollectionReference<Map<String, dynamic>> get _resultsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('results');

  static String _dateKey(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-"
      "${date.day.toString().padLeft(2, '0')}";

  static String _docId(DateTime date, String wodType) =>
      "${_dateKey(date)}_$wodType";

  // ── Leitura ─────────────────────────────────────────────────────────────────

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
      print('ERRO fetchTodayResult: \$e');
      return null;
    }
  }

  // ── Escrita ──────────────────────────────────────────────────────────────────

  static Future<void> submitResult(AthleteResultRecord record) async {
    try {
      final date = DateTime.parse(record.date);
      final docId = _docId(date, record.wodType);
      await _resultsRef.doc(docId).set(record.toFirestore());
      print('✅ Resultado salvo: \$docId');
    } catch (e) {
      print('ERRO submitResult: \$e');
      rethrow;
    }
  }

  // ── Série semanal de esforço — agora usa dados reais ────────────────────────

  /// Retorna os pontos de esforço da semana informada.
  /// Substitui o mock hard-coded anterior.
  Future<List<DailyEffort>> fetchWeeklyEffortSeries(WeekRange week) async {
    return AthleteStatsService.fetchEffortSeries(
      from: week.start,
      to: week.end,
    );
  }

  // ── Esforço padrão para o slider ────────────────────────────────────────────

  /// Retorna o esforço do último treino registrado como valor inicial do slider.
  Future<int> fetchDefaultEffort() async {
    try {
      final snap =
          await _resultsRef
              .orderBy('registeredAt', descending: true)
              .limit(1)
              .get();
      if (snap.docs.isEmpty) return 5;
      final effort = snap.docs.first.data()['effort'];
      if (effort == null) return 5;
      return (effort as num).toInt().clamp(1, 10);
    } catch (e) {
      print('ERRO fetchDefaultEffort: \$e');
      return 5;
    }
  }

  // ── Mantido por compatibilidade ──────────────────────────────────────────────

  /// @deprecated Use submitResult() diretamente.
  Future<void> submitEffort({
    required int effort,
    String? classId,
    required DateTime date,
  }) async {
    await Future.delayed(const Duration(milliseconds: 240));
  }
}
