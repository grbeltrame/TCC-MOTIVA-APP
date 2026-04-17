// lib/core/services/athlete_stats_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/core/services/effort_service.dart';

// =============================================================================
// Models
// =============================================================================

/// Calendário da semana — tipo de atividade por dia.
enum DayActivityType { wod, rest, other, none }

/// Resumo completo pré-calculado pela Cloud Function.
class AthleteStatsSummary {
  // All-time
  final int totalTrainingDays;
  final double averageEffortAllTime;

  // Mês atual
  final int currentMonthTrainingDays;
  final double averageEffortCurrentMonth;

  // Semana atual
  final int currentWeekTrainingDays;
  final double averageEffortCurrentWeek;
  final Map<String, int> currentWeekStimuli; // { "Força": 3, ... }
  final Map<String, DayActivityType>
  currentWeekCalendar; // { "2026-04-08": wod, ... }

  // Metadados
  final String weekStart;
  final String weekEnd;
  final String monthStart;
  final DateTime? updatedAt;

  const AthleteStatsSummary({
    required this.totalTrainingDays,
    required this.averageEffortAllTime,
    required this.currentMonthTrainingDays,
    required this.averageEffortCurrentMonth,
    required this.currentWeekTrainingDays,
    required this.averageEffortCurrentWeek,
    required this.currentWeekStimuli,
    required this.currentWeekCalendar,
    required this.weekStart,
    required this.weekEnd,
    required this.monthStart,
    this.updatedAt,
  });

  /// Retorna uma cópia com todos os dados da semana atual zerados.
  /// Usado quando o summary armazenado pertence a uma semana anterior.
  AthleteStatsSummary withCurrentWeekZeroed({
    required String currentWeekStart,
    required String currentWeekEnd,
  }) {
    return AthleteStatsSummary(
      totalTrainingDays: totalTrainingDays,
      averageEffortAllTime: averageEffortAllTime,
      currentMonthTrainingDays: currentMonthTrainingDays,
      averageEffortCurrentMonth: averageEffortCurrentMonth,
      currentWeekTrainingDays: 0,
      averageEffortCurrentWeek: 0,
      currentWeekStimuli: const {},
      currentWeekCalendar: const {},
      weekStart: currentWeekStart,
      weekEnd: currentWeekEnd,
      monthStart: monthStart,
      updatedAt: updatedAt,
    );
  }

  factory AthleteStatsSummary.fromFirestore(Map<String, dynamic> data) {
    // Converte o calendário raw { "2026-04-08": "wod" } para enum
    final rawCalendar =
        (data['currentWeekCalendar'] as Map<String, dynamic>?) ?? {};
    final calendar = rawCalendar.map((date, type) {
      final activity = switch (type as String? ?? '') {
        'wod' => DayActivityType.wod,
        'rest' => DayActivityType.rest,
        'other' => DayActivityType.other,
        _ => DayActivityType.none,
      };
      return MapEntry(date, activity);
    });

    // Estímulos
    final rawStimuli =
        (data['currentWeekStimuli'] as Map<String, dynamic>?) ?? {};
    final stimuli = rawStimuli.map((k, v) => MapEntry(k, (v as num).toInt()));

    // updatedAt pode vir como Timestamp do Firestore
    DateTime? updatedAt;
    final raw = data['updatedAt'];
    if (raw is Timestamp) {
      updatedAt = raw.toDate();
    }

    return AthleteStatsSummary(
      totalTrainingDays: (data['totalTrainingDays'] as num? ?? 0).toInt(),
      averageEffortAllTime:
          (data['averageEffortAllTime'] as num? ?? 0).toDouble(),
      currentMonthTrainingDays:
          (data['currentMonthTrainingDays'] as num? ?? 0).toInt(),
      averageEffortCurrentMonth:
          (data['averageEffortCurrentMonth'] as num? ?? 0).toDouble(),
      currentWeekTrainingDays:
          (data['currentWeekTrainingDays'] as num? ?? 0).toInt(),
      averageEffortCurrentWeek:
          (data['averageEffortCurrentWeek'] as num? ?? 0).toDouble(),
      currentWeekStimuli: stimuli,
      currentWeekCalendar: calendar,
      weekStart: data['weekStart'] as String? ?? '',
      weekEnd: data['weekEnd'] as String? ?? '',
      monthStart: data['monthStart'] as String? ?? '',
      updatedAt: updatedAt,
    );
  }

  /// Retorna os estímulos ordenados do mais ao menos frequente.
  List<MapEntry<String, int>> get stimuliSorted {
    final entries =
        currentWeekStimuli.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  /// Tipo de atividade de um dia específico (usa 'YYYY-MM-DD').
  DayActivityType activityTypeFor(String dateKey) {
    return currentWeekCalendar[dateKey] ?? DayActivityType.none;
  }
}

// =============================================================================
// AthleteStatsService
// =============================================================================

class AthleteStatsService {
  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não logado');
    return uid;
  }

  static DocumentReference<Map<String, dynamic>> get _summaryRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('stats')
          .doc('summary');

  static CollectionReference<Map<String, dynamic>> get _resultsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('results');

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Domingo da semana que contém [ref] (semana dom→sáb).
  /// Dart weekday: seg=1..sáb=6, dom=7 → `weekday % 7` dá dias desde domingo.
  static DateTime _weekStartOf(DateTime ref) {
    final daysSinceSunday = ref.weekday % 7; // seg=1..sáb=6, dom=0
    return DateTime(ref.year, ref.month, ref.day - daysSinceSunday);
  }

  // ── Leitura do summary pré-calculado (1 doc read) ────────────────────────────

  /// Retorna o resumo pré-calculado pela Cloud Function.
  /// Se o summary armazenado for de uma semana anterior, devolve os dados
  /// all-time/mensal intactos mas zera todos os campos da semana atual.
  /// Null se ainda não existir (atleta nunca registrou nada).
  static Future<AthleteStatsSummary?> fetchSummary() async {
    try {
      final doc = await _summaryRef.get();
      if (!doc.exists || doc.data() == null) return null;
      final summary = AthleteStatsSummary.fromFirestore(doc.data()!);

      // Verifica se a semana armazenada corresponde à semana atual.
      final now = DateTime.now();
      final currentWeekStart = _weekStartOf(now);
      final currentWeekEnd = currentWeekStart.add(const Duration(days: 6));
      final expectedWeekStart = _dateKey(currentWeekStart);

      if (summary.weekStart != expectedWeekStart) {
        // Summary é de outra semana — zera dados da semana para não mostrar
        // treinos/estímulos/calendário antigos como se fossem desta semana.
        return summary.withCurrentWeekZeroed(
          currentWeekStart: expectedWeekStart,
          currentWeekEnd: _dateKey(currentWeekEnd),
        );
      }

      return summary;
    } catch (e) {
      print('ERRO fetchSummary: $e');
      return null;
    }
  }

  /// Stream do summary — atualiza automaticamente quando a Cloud Function salva.
  static Stream<AthleteStatsSummary?> watchSummary() {
    return _summaryRef.snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return AthleteStatsSummary.fromFirestore(snap.data()!);
    });
  }

  // ── Série temporal de esforço (para gráfico) ─────────────────────────────────

  /// Retorna um ponto de esforço por atividade no período [from, to].
  /// Exclui REST. [wodType] filtra por tipo específico (null = todos).
  static Future<List<DailyEffort>> fetchEffortSeries({
    required DateTime from,
    required DateTime to,
    String? wodType,
  }) async {
    try {
      final fromKey = _dateKey(from);
      final toKey = _dateKey(to);

      var query =
          _resultsRef
              .where('date', isGreaterThanOrEqualTo: fromKey)
              .where('date', isLessThanOrEqualTo: toKey)
              .orderBy('date');

      final snap = await query.get();

      final points = <DailyEffort>[];
      for (final doc in snap.docs) {
        final docId = doc.id.toUpperCase();
        if (docId.endsWith('_REST')) continue;

        // Filtro por tipo: OTHER usa campo 'activity', treinos usam 'wodType'
        if (wodType != null) {
          final isOther = docId.contains('_OTHER');
          final docTypeRaw = isOther
              ? (doc.data()['activity'] as String? ?? '')
              : (doc.data()['wodType'] as String? ?? '');
          if (docTypeRaw.toLowerCase() != wodType.toLowerCase()) continue;
        }

        final data = doc.data();
        final effort = data['effort'];
        final date = data['date'] as String?;

        if (effort == null || date == null) continue;

        try {
          final dt = DateTime.parse(date);
          points.add(DailyEffort(dt, (effort as num).toDouble()));
        } catch (_) {}
      }

      return points;
    } catch (e) {
      print('ERRO fetchEffortSeries: $e');
      return [];
    }
  }

  // ── Frequência por período ────────────────────────────────────────────────────

  /// Retorna contagem de treinos agrupada por semana ('YYYY-Www') no período.
  /// Ex: { '2026-W14': 4, '2026-W15': 3 }
  static Future<Map<String, int>> fetchFrequencyByWeek({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final snap =
          await _resultsRef
              .where('date', isGreaterThanOrEqualTo: _dateKey(from))
              .where('date', isLessThanOrEqualTo: _dateKey(to))
              .get();

      final freq = <String, int>{};
      for (final doc in snap.docs) {
        final docId = doc.id.toUpperCase();
        if (docId.contains('_REST') || docId.contains('_OTHER')) continue;

        final date = (doc.data()['date'] as String?) ?? '';
        if (date.isEmpty) continue;

        try {
          final dt = DateTime.parse(date);
          final weekNum = _isoWeekNumber(dt);
          final key = '${dt.year}-W${weekNum.toString().padLeft(2, '0')}';
          freq[key] = (freq[key] ?? 0) + 1;
        } catch (_) {}
      }

      return freq;
    } catch (e) {
      print('ERRO fetchFrequencyByWeek: $e');
      return {};
    }
  }

  // ── Histórico de WOD específico ───────────────────────────────────────────────

  /// Retorna registros de um WOD pelo nome, ordenados do mais recente.
  /// Útil para gráfico de progressão (FOR TIME / AMRAP ao longo do tempo).
  static Future<List<AthleteResultRecord>> fetchResultsByWodName({
    required String wodName,
    int limit = 20,
  }) async {
    try {
      final snap =
          await _resultsRef
              .where('wodName', isEqualTo: wodName)
              .orderBy('date', descending: true)
              .limit(limit)
              .get();

      return snap.docs
          .map((d) => AthleteResultRecord.fromFirestore(d.data()))
          .toList();
    } catch (e) {
      print('ERRO fetchResultsByWodName: $e');
      return [];
    }
  }

  /// Lista os nomes únicos de WODs que o atleta já registrou.
  /// Usado para popular o dropdown de seleção na tela de evolução.
  static Future<List<String>> fetchRegisteredWodNames() async {
    try {
      final snap = await _resultsRef.where('wodName', isNull: false).get();

      final names = <String>{};
      for (final doc in snap.docs) {
        final name = doc.data()['wodName'] as String?;
        if (name != null && name.isNotEmpty) names.add(name);
      }

      final sorted = names.toList()..sort();
      return sorted;
    } catch (e) {
      print('ERRO fetchRegisteredWodNames: $e');
      return [];
    }
  }

  // ── Dias de descanso no período ──────────────────────────────────────────────

  /// Conta quantos dias de descanso (_REST) foram registrados em [from, to].
  static Future<int> fetchRestCount({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final snap =
          await _resultsRef
              .where('date', isGreaterThanOrEqualTo: _dateKey(from))
              .where('date', isLessThanOrEqualTo: _dateKey(to))
              .get();

      return snap.docs
          .where((d) => d.id.toUpperCase().endsWith('_REST'))
          .length;
    } catch (e) {
      print('ERRO fetchRestCount: $e');
      return 0;
    }
  }

  // ── Tipos de treino no período ────────────────────────────────────────────────

  /// Retorna lista de tipos únicos de treino registrados em [from, to].
  /// Ex: ['LPO', 'WOD']
  static Future<List<String>> fetchTrainingTypes({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final snap =
          await _resultsRef
              .where('date', isGreaterThanOrEqualTo: _dateKey(from))
              .where('date', isLessThanOrEqualTo: _dateKey(to))
              .get();

      final types = <String>{};
      for (final doc in snap.docs) {
        final id = doc.id.toUpperCase();
        if (id.endsWith('_REST')) continue;

        if (id.contains('_OTHER')) {
          // Outra atividade: usa o campo 'activity' (ex: "Corrida")
          final activity = doc.data()['activity'] as String?;
          if (activity != null && activity.isNotEmpty) {
            types.add(activity);
          }
        } else {
          // Treino normal: usa wodType (ex: "WOD", "LPO")
          final wodType = doc.data()['wodType'] as String?;
          if (wodType != null && wodType.isNotEmpty) {
            types.add(wodType.toUpperCase());
          }
        }
      }
      return types.toList()..sort();
    } catch (e) {
      print('ERRO fetchTrainingTypes: $e');
      return [];
    }
  }

  // ── Estímulos agregados por período ──────────────────────────────────────────

  /// Agrega keyMetrics de todos os treinos em [from, to].
  /// Retorna Map { "Força": 3, "Resistência": 2, ... } ordenado por contagem.
  static Future<Map<String, int>> fetchStimuliCountsForPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final snap =
          await _resultsRef
              .where('date', isGreaterThanOrEqualTo: _dateKey(from))
              .where('date', isLessThanOrEqualTo: _dateKey(to))
              .get();

      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final id = doc.id.toUpperCase();
        if (id.endsWith('_REST') || id.contains('_OTHER')) continue;
        final keyMetrics = doc.data()['keyMetrics'];
        if (keyMetrics is List) {
          for (final m in keyMetrics) {
            if (m is String && m.isNotEmpty) {
              counts[m] = (counts[m] ?? 0) + 1;
            }
          }
        }
      }

      final sorted = Map.fromEntries(
        counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
      );
      return sorted;
    } catch (e) {
      print('ERRO fetchStimuliCountsForPeriod: $e');
      return {};
    }
  }

  // ── Helper: número da semana ISO ─────────────────────────────────────────────

  static int _isoWeekNumber(DateTime date) {
    // Algoritmo ISO 8601: semana começa na segunda-feira
    final thursday = date.add(Duration(days: 4 - (date.weekday)));
    final firstThursday = DateTime(thursday.year, 1, 1);
    final diff = thursday.difference(firstThursday);
    return 1 + (diff.inDays ~/ 7);
  }
}
