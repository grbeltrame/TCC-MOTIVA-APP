// lib/core/services/athlete_insights_service.dart

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// Models
// =============================================================================

enum InsightKind { alert, info }

enum InsightSource { weekly, evolution, preWorkout }

/// Card unificado que alimenta o carrossel.
class InsightCardItem {
  final String key;
  final String message;
  final InsightKind kind;
  final InsightSource source;

  const InsightCardItem({
    required this.key,
    required this.message,
    required this.kind,
    required this.source,
  });
}

class AthleteWeeklyInsights {
  final Map<String, String> alertas; // key -> message
  final Map<String, String> informacoes; // key -> detail
  final String? weekLabel;
  final DateTime? lastGeneratedAt;

  const AthleteWeeklyInsights({
    required this.alertas,
    required this.informacoes,
    this.weekLabel,
    this.lastGeneratedAt,
  });

  bool get isEmpty => alertas.isEmpty && informacoes.isEmpty;

  List<InsightCardItem> toCards() {
    final out = <InsightCardItem>[];
    alertas.forEach(
      (k, v) => out.add(
        InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.alert,
          source: InsightSource.weekly,
        ),
      ),
    );
    informacoes.forEach(
      (k, v) => out.add(
        InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.info,
          source: InsightSource.weekly,
        ),
      ),
    );
    return out;
  }

  static AthleteWeeklyInsights fromMap(Map<String, dynamic> data) {
    final alertas = <String, String>{};
    final infos = <String, String>{};

    final rawAlertas = data['alertas'];
    if (rawAlertas is Map) {
      rawAlertas.forEach((k, v) {
        final text = _stringFromInsightValue(v, primaryKey: 'message');
        if (text != null) alertas[k.toString()] = text;
      });
    }
    final rawInfos = data['informacoes'];
    if (rawInfos is Map) {
      rawInfos.forEach((k, v) {
        final text = _stringFromInsightValue(v, primaryKey: 'detail');
        if (text != null) infos[k.toString()] = text;
      });
    }

    DateTime? generatedAt;
    final ts = data['lastGeneratedAt'];
    if (ts is Timestamp) generatedAt = ts.toDate();

    return AthleteWeeklyInsights(
      alertas: alertas,
      informacoes: infos,
      weekLabel: data['weekLabel']?.toString(),
      lastGeneratedAt: generatedAt,
    );
  }
}

class AthleteEvolutionInsights {
  final Map<String, String> alertas;
  final Map<String, String> informacoes;
  final int? weeksAnalyzed;
  final DateTime? lastGeneratedAt;

  const AthleteEvolutionInsights({
    required this.alertas,
    required this.informacoes,
    this.weeksAnalyzed,
    this.lastGeneratedAt,
  });

  bool get isEmpty => alertas.isEmpty && informacoes.isEmpty;

  List<InsightCardItem> toCards() {
    final out = <InsightCardItem>[];
    alertas.forEach(
      (k, v) => out.add(
        InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.alert,
          source: InsightSource.evolution,
        ),
      ),
    );
    informacoes.forEach(
      (k, v) => out.add(
        InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.info,
          source: InsightSource.evolution,
        ),
      ),
    );
    return out;
  }

  static AthleteEvolutionInsights fromMap(Map<String, dynamic> data) {
    final alertas = <String, String>{};
    final infos = <String, String>{};

    final rawAlertas = data['alertas'];
    if (rawAlertas is Map) {
      rawAlertas.forEach((k, v) {
        final text = _stringFromInsightValue(v, primaryKey: 'message');
        if (text != null) alertas[k.toString()] = text;
      });
    }
    final rawInfos = data['informacoes'];
    if (rawInfos is Map) {
      rawInfos.forEach((k, v) {
        final text = _stringFromInsightValue(v, primaryKey: 'detail');
        if (text != null) infos[k.toString()] = text;
      });
    }

    DateTime? generatedAt;
    final ts = data['lastGeneratedAt'];
    if (ts is Timestamp) {
      generatedAt = ts.toDate();
    } else if (ts is String) {
      generatedAt = DateTime.tryParse(ts);
    } else if (ts is int) {
      // Caso venha de onCall: millis
      generatedAt = DateTime.fromMillisecondsSinceEpoch(ts);
    }

    return AthleteEvolutionInsights(
      alertas: alertas,
      informacoes: infos,
      weeksAnalyzed:
          data['weeksAnalyzed'] is int ? data['weeksAnalyzed'] as int : null,
      lastGeneratedAt: generatedAt,
    );
  }
}

/// Insights pré-treino — gerados quando o coach publica/atualiza um treino
/// em `exercises/{workoutId}`. Persistidos por atleta em
/// `users/{uid}/insights/pre_workout/items/{workoutId}`.
class AthletePreWorkoutInsights {
  final Map<String, String> alertas;
  final Map<String, String> informacoes;
  final String? workoutId;
  final int historySize;
  final bool hasPattern;
  final DateTime? generatedAt;

  const AthletePreWorkoutInsights({
    required this.alertas,
    required this.informacoes,
    required this.historySize,
    required this.hasPattern,
    this.workoutId,
    this.generatedAt,
  });

  bool get isEmpty => alertas.isEmpty && informacoes.isEmpty;

  List<InsightCardItem> toCards() {
    final out = <InsightCardItem>[];
    alertas.forEach(
      (k, v) => out.add(
        InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.alert,
          source: InsightSource.preWorkout,
        ),
      ),
    );
    informacoes.forEach(
      (k, v) => out.add(
        InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.info,
          source: InsightSource.preWorkout,
        ),
      ),
    );
    return out;
  }

  static AthletePreWorkoutInsights fromMap(Map<String, dynamic> data) {
    final alertas = <String, String>{};
    final infos = <String, String>{};

    final rawAlertas = data['alertas'];
    if (rawAlertas is Map) {
      rawAlertas.forEach((k, v) {
        final text = _stringFromInsightValue(v, primaryKey: 'message');
        if (text != null) alertas[k.toString()] = text;
      });
    }
    final rawInfos = data['informacoes'];
    if (rawInfos is Map) {
      rawInfos.forEach((k, v) {
        final text = _stringFromInsightValue(v, primaryKey: 'detail');
        if (text != null) infos[k.toString()] = text;
      });
    }

    DateTime? generatedAt;
    final ts = data['generatedAt'];
    if (ts is Timestamp) generatedAt = ts.toDate();

    return AthletePreWorkoutInsights(
      alertas: alertas,
      informacoes: infos,
      workoutId: data['workoutId']?.toString(),
      historySize: (data['historySize'] as num?)?.toInt() ?? 0,
      hasPattern: data['hasPattern'] == true,
      generatedAt: generatedAt,
    );
  }
}

// =============================================================================
// Service
// =============================================================================

String? _stringFromInsightValue(Object? value, {required String primaryKey}) {
  if (value is String) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  if (value is Map) {
    for (final key in <String>[primaryKey, 'message', 'detail', 'text']) {
      final candidate = value[key];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
  }

  return null;
}

class AthleteInsightsService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _fn = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Lê os insights semanais já gerados (doc `users/{uid}/insights/semanal`).
  /// Retorna `null` se o documento for de uma semana anterior — evita exibir
  /// insights antigos como se fossem da semana corrente quando o atleta
  /// ainda não treinou nesta semana.
  static Future<AthleteWeeklyInsights?> fetchWeekly() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final snap =
        await _db
            .collection('users')
            .doc(uid)
            .collection('insights')
            .doc('semanal')
            .get();
    if (!snap.exists) return null;

    final insights = AthleteWeeklyInsights.fromMap(snap.data() ?? {});
    if (insights.weekLabel != null &&
        insights.weekLabel != _currentWeekLabel()) {
      return null;
    }
    return insights;
  }

  /// Domingo da semana que contém [ref] (semana dom→sáb).
  static DateTime _weekStartOf(DateTime ref) {
    final daysSinceSunday = ref.weekday % 7; // seg=1..sáb=6, dom=0
    return DateTime(ref.year, ref.month, ref.day - daysSinceSunday);
  }

  /// Label `YYYY-Www` da semana atual, replicando a convenção do backend
  /// (`functions/athlete_stats_module/logic.py:_week_label_sunday`).
  /// Semana 01 = semana que contém o primeiro domingo do ano. Domingos
  /// anteriores pertencem à última semana do ano anterior.
  static String _currentWeekLabel() {
    final weekStart = _weekStartOf(DateTime.now());
    return _weekLabelSunday(weekStart);
  }

  static String _weekLabelSunday(DateTime weekStart) {
    final year = weekStart.year;
    final jan1 = DateTime(year, 1, 1);
    // Dart weekday: seg=1..dom=7. Domingo → 0 dias até o próximo domingo.
    final daysToFirstSunday = (7 - jan1.weekday) % 7;
    final firstSunday = jan1.add(Duration(days: daysToFirstSunday));

    if (weekStart.isBefore(firstSunday)) {
      // Pertence à última semana do ano anterior.
      final prevYearLastDay = DateTime(year - 1, 12, 31);
      return _weekLabelSunday(_weekStartOf(prevYearLastDay));
    }

    final weekNum = weekStart.difference(firstSunday).inDays ~/ 7 + 1;
    return '$year-W${weekNum.toString().padLeft(2, '0')}';
  }

  /// Lê os insights pré-treino de um treino específico.
  /// Path: `users/{uid}/insights/pre_workout/items/{workoutId}`.
  /// Retorna null se ainda não foram gerados (atleta não elegível ou
  /// trigger ainda não rodou).
  static Future<AthletePreWorkoutInsights?> fetchPreWorkout(
    String workoutId,
  ) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final snap =
        await _db
            .collection('users')
            .doc(uid)
            .collection('insights')
            .doc('pre_workout')
            .collection('items')
            .doc(workoutId)
            .get();
    if (!snap.exists) return null;
    return AthletePreWorkoutInsights.fromMap(snap.data() ?? {});
  }

  /// Lê o cache local de evolução, se houver.
  /// Útil para decidir se mostra algo enquanto o onCall roda.
  static Future<AthleteEvolutionInsights?> fetchEvolutionCached() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final snap =
        await _db
            .collection('users')
            .doc(uid)
            .collection('insights')
            .doc('evolucao')
            .get();
    if (!snap.exists) return null;
    return AthleteEvolutionInsights.fromMap(snap.data() ?? {});
  }

  /// Dispara o onCall `get_athlete_evolution_insights`.
  /// O backend cuida do cache de 4 dias. Passe [force] = true para forçar
  /// regeneração.
  ///
  /// A chamada sempre chega ao backend. A Function decide se reutiliza o cache
  /// de 4 dias ou se gera uma análise nova.
  static Future<AthleteEvolutionInsights> fetchEvolution({
    bool force = false,
  }) async {
    final callable = _fn.httpsCallable('get_athlete_evolution_insights');
    final res = await callable.call<Map<Object?, Object?>>({'force': force});
    final data = Map<String, dynamic>.from(res.data);
    final result = AthleteEvolutionInsights.fromMap(data);

    return result;
  }

  /// Sorteia cards para o carrossel da home.
  ///
  /// Regra (alinhada ao pedido do produto):
  ///   - Tenta entregar 2 da semana + 2 de evolução (4 no total).
  ///   - Se faltar alertas, completa com informações (não deixa de entregar
  ///     a quantidade alvo enquanto houver cards disponíveis).
  ///   - Se uma das fontes for nula/vazia, preenche com a outra.
  ///   - Nunca devolve repetidos na mesma rodada.
  static List<InsightCardItem> buildHomeMix({
    required AthleteWeeklyInsights? weekly,
    required AthleteEvolutionInsights? evolution,
    int targetPerSource = 2,
    int? seed,
  }) {
    final rng = Random(seed);

    final weeklyCards =
        (weekly?.toCards() ?? <InsightCardItem>[])..shuffle(rng);
    final evoCards =
        (evolution?.toCards() ?? <InsightCardItem>[])..shuffle(rng);

    final pickedWeekly = weeklyCards.take(targetPerSource).toList();
    final pickedEvo = evoCards.take(targetPerSource).toList();

    // Se uma das fontes faltou cards, completa com a outra.
    final total = targetPerSource * 2;
    final all = [...pickedWeekly, ...pickedEvo];

    if (all.length < total) {
      final extras = <InsightCardItem>[
        ...weeklyCards.skip(pickedWeekly.length),
        ...evoCards.skip(pickedEvo.length),
      ]..shuffle(rng);
      final need = total - all.length;
      all.addAll(extras.take(need));
    }

    all.shuffle(rng);
    return all;
  }
}
