// lib/core/services/weekly_load_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// Model
// =============================================================================

class WeeklyLoadEntry {
  final String weekLabel;
  final String weekStart;
  final String weekEnd;

  // Cargas brutas (AU)
  final double totalLoadCrossfit;
  final double totalLoadOther;
  final double totalLoadAll;

  // ICN (0–150, meta = 50)
  final double icnAll;
  final double icnCrossfit;
  final String icnBaselineUsed;

  // RPE médio
  final double avgRpeCrossfit;
  final double avgRpeAll;

  // Frequência
  final int wodDays;
  final int otherDays;
  final int restDays;

  // Saúde do treino
  final double monotony;
  final double strain;
  final double restRatio;

  // PRs
  final int prsCount;

  // Cargas diárias { "YYYY-MM-DD": AU }
  final Map<String, double> dailyLoadsCrossfit;
  final Map<String, double> dailyLoadsOther;

  const WeeklyLoadEntry({
    required this.weekLabel,
    required this.weekStart,
    required this.weekEnd,
    required this.totalLoadCrossfit,
    required this.totalLoadOther,
    required this.totalLoadAll,
    required this.icnAll,
    required this.icnCrossfit,
    required this.icnBaselineUsed,
    required this.avgRpeCrossfit,
    required this.avgRpeAll,
    required this.wodDays,
    required this.otherDays,
    required this.restDays,
    required this.monotony,
    required this.strain,
    required this.restRatio,
    required this.prsCount,
    required this.dailyLoadsCrossfit,
    required this.dailyLoadsOther,
  });

  factory WeeklyLoadEntry.fromFirestore(Map<String, dynamic> d) {
    Map<String, double> _toDoubleMap(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    }

    return WeeklyLoadEntry(
      weekLabel: d['weekLabel'] as String? ?? '',
      weekStart: d['weekStart'] as String? ?? '',
      weekEnd: d['weekEnd'] as String? ?? '',
      totalLoadCrossfit: (d['totalLoadCrossfit'] as num? ?? 0).toDouble(),
      totalLoadOther: (d['totalLoadOther'] as num? ?? 0).toDouble(),
      totalLoadAll: (d['totalLoadAll'] as num? ?? 0).toDouble(),
      icnAll: (d['icnAll'] as num? ?? 50).toDouble(),
      icnCrossfit: (d['icnCrossfit'] as num? ?? 50).toDouble(),
      icnBaselineUsed: d['icnBaselineUsed'] as String? ?? '',
      avgRpeCrossfit: (d['avgRpeCrossfit'] as num? ?? 0).toDouble(),
      avgRpeAll: (d['avgRpeAll'] as num? ?? 0).toDouble(),
      wodDays: (d['wodDays'] as num? ?? 0).toInt(),
      otherDays: (d['otherDays'] as num? ?? 0).toInt(),
      restDays: (d['restDays'] as num? ?? 0).toInt(),
      monotony: (d['monotony'] as num? ?? 0).toDouble(),
      strain: (d['strain'] as num? ?? 0).toDouble(),
      restRatio: (d['restRatio'] as num? ?? 0).toDouble(),
      prsCount: (d['prsCount'] as num? ?? 0).toInt(),
      dailyLoadsCrossfit: _toDoubleMap(d['dailyLoadsCrossfit']),
      dailyLoadsOther: _toDoubleMap(d['dailyLoadsOther']),
    );
  }

  /// Interpreta o ICN: zona de treino.
  String get icnZoneLabel {
    if (icnAll < 25) return 'Muito Baixa';
    if (icnAll < 40) return 'Baixa';
    if (icnAll < 60) return 'Ideal';
    if (icnAll < 80) return 'Elevada';
    return 'Muito Elevada';
  }
}

// =============================================================================
// Service
// =============================================================================

class WeeklyLoadService {
  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não logado');
    return uid;
  }

  static CollectionReference<Map<String, dynamic>> get _loadRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('weekly_load');

  /// Retorna as últimas [limit] semanas, da mais recente à mais antiga.
  static Future<List<WeeklyLoadEntry>> fetchHistory({int limit = 8}) async {
    try {
      final snap = await _loadRef
          .orderBy('weekLabel', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((d) => WeeklyLoadEntry.fromFirestore(d.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream do documento da semana atual.
  static Stream<WeeklyLoadEntry?> watchCurrentWeek(String weekLabel) {
    return _loadRef.doc(weekLabel).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return WeeklyLoadEntry.fromFirestore(snap.data()!);
    });
  }
}
