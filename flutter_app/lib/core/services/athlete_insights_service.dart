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
  final Map<String, String> alertas;       // key -> message
  final Map<String, String> informacoes;   // key -> detail
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
    alertas.forEach((k, v) => out.add(InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.alert,
          source: InsightSource.weekly,
        )));
    informacoes.forEach((k, v) => out.add(InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.info,
          source: InsightSource.weekly,
        )));
    return out;
  }

  static AthleteWeeklyInsights fromMap(Map<String, dynamic> data) {
    final alertas = <String, String>{};
    final infos = <String, String>{};

    final rawAlertas = data['alertas'];
    if (rawAlertas is Map) {
      rawAlertas.forEach((k, v) {
        if (v is Map && v['message'] is String) {
          alertas[k.toString()] = v['message'] as String;
        }
      });
    }
    final rawInfos = data['informacoes'];
    if (rawInfos is Map) {
      rawInfos.forEach((k, v) {
        if (v is Map && v['detail'] is String) {
          infos[k.toString()] = v['detail'] as String;
        }
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
    alertas.forEach((k, v) => out.add(InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.alert,
          source: InsightSource.evolution,
        )));
    informacoes.forEach((k, v) => out.add(InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.info,
          source: InsightSource.evolution,
        )));
    return out;
  }

  static AthleteEvolutionInsights fromMap(Map<String, dynamic> data) {
    final alertas = <String, String>{};
    final infos = <String, String>{};

    final rawAlertas = data['alertas'];
    if (rawAlertas is Map) {
      rawAlertas.forEach((k, v) {
        if (v is Map && v['message'] is String) {
          alertas[k.toString()] = v['message'] as String;
        }
      });
    }
    final rawInfos = data['informacoes'];
    if (rawInfos is Map) {
      rawInfos.forEach((k, v) {
        if (v is Map && v['detail'] is String) {
          infos[k.toString()] = v['detail'] as String;
        }
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
      weeksAnalyzed: data['weeksAnalyzed'] is int
          ? data['weeksAnalyzed'] as int
          : null,
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
    alertas.forEach((k, v) => out.add(InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.alert,
          source: InsightSource.preWorkout,
        )));
    informacoes.forEach((k, v) => out.add(InsightCardItem(
          key: k,
          message: v,
          kind: InsightKind.info,
          source: InsightSource.preWorkout,
        )));
    return out;
  }

  static AthletePreWorkoutInsights fromMap(Map<String, dynamic> data) {
    final alertas = <String, String>{};
    final infos = <String, String>{};

    final rawAlertas = data['alertas'];
    if (rawAlertas is Map) {
      rawAlertas.forEach((k, v) {
        if (v is Map && v['message'] is String) {
          alertas[k.toString()] = v['message'] as String;
        }
      });
    }
    final rawInfos = data['informacoes'];
    if (rawInfos is Map) {
      rawInfos.forEach((k, v) {
        if (v is Map && v['detail'] is String) {
          infos[k.toString()] = v['detail'] as String;
        }
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

class AthleteInsightsService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _fn =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // Cache em memória para evolução: evita chamar o onCall toda vez que
  // o usuário sai e volta para a tela de evolução na mesma sessão.
  // TTL de 1h — suficiente pois o backend tem cache de 4 dias.
  static AthleteEvolutionInsights? _evolutionMemCache;
  static DateTime? _evolutionMemCachedAt;
  static const _evolutionMemTtl = Duration(hours: 1);

  /// Lê os insights semanais já gerados (doc `users/{uid}/insights/semanal`).
  static Future<AthleteWeeklyInsights?> fetchWeekly() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('insights')
        .doc('semanal')
        .get();
    if (!snap.exists) return null;
    return AthleteWeeklyInsights.fromMap(snap.data() ?? {});
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

    final snap = await _db
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

    final snap = await _db
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
  /// Cache em memória (1h): se o usuário sair e voltar para a tela de evolução
  /// na mesma sessão, retorna os dados já carregados sem fazer novo onCall.
  static Future<AthleteEvolutionInsights> fetchEvolution({
    bool force = false,
  }) async {
    if (!force) {
      final cached = _evolutionMemCache;
      final cachedAt = _evolutionMemCachedAt;
      if (cached != null &&
          cachedAt != null &&
          DateTime.now().difference(cachedAt) < _evolutionMemTtl) {
        return cached;
      }
    }

    final callable = _fn.httpsCallable('get_athlete_evolution_insights');
    final res = await callable.call<Map<Object?, Object?>>({'force': force});
    final data = Map<String, dynamic>.from(res.data);
    final result = AthleteEvolutionInsights.fromMap(data);

    _evolutionMemCache = result;
    _evolutionMemCachedAt = DateTime.now();

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

    final weeklyCards = (weekly?.toCards() ?? <InsightCardItem>[])..shuffle(rng);
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
