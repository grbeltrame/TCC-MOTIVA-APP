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

  // Cargas brutas (AU) — Session-RPE (esforço × duração)
  final double totalLoadCrossfit;
  final double totalLoadOther;
  final double totalLoadAll;

  // ICN via ACWR (Gabbett, 2016) — nullable pois pode não ter base crônica
  final double? icnAll;
  final double? icnCrossfit;
  final double? cargaCronica; // média das últimas 4 semanas
  final double? acwrRaw;      // razão antes do × 50
  final String baselineType;  // cold_start | partial_N_weeks | historical_4_weeks

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
    required this.cargaCronica,
    required this.acwrRaw,
    required this.baselineType,
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

    double? _nullableDouble(dynamic raw) =>
        raw is num ? raw.toDouble() : null;

    return WeeklyLoadEntry(
      weekLabel: d['weekLabel'] as String? ?? '',
      weekStart: d['weekStart'] as String? ?? '',
      weekEnd: d['weekEnd'] as String? ?? '',
      totalLoadCrossfit: (d['totalLoadCrossfit'] as num? ?? 0).toDouble(),
      totalLoadOther: (d['totalLoadOther'] as num? ?? 0).toDouble(),
      totalLoadAll: (d['totalLoadAll'] as num? ?? 0).toDouble(),
      icnAll: _nullableDouble(d['icnAll']),
      icnCrossfit: _nullableDouble(d['icnCrossfit']),
      cargaCronica: _nullableDouble(d['cargaCronica']),
      acwrRaw: _nullableDouble(d['acwrRaw']),
      baselineType: d['baselineType'] as String? ?? 'cold_start',
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

  /// Interpreta o ICN alinhado com as zonas oficiais do ACWR (Gabbett, 2016).
  /// 50 é o ponto neutro (carga = média crônica); >75 é zona de alerta.
  String get icnZoneLabel {
    final icn = icnAll;
    if (icn == null) return 'Sem histórico';
    if (icn < 50)   return 'Abaixo da média';
    if (icn < 75)   return 'Zona ideal';
    if (icn < 100)  return 'Alerta';
    return 'Risco de lesão';
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
