// lib/core/services/athlete_prs_service.dart
//
// Serviço para cadastro e leitura de PRs (Personal Records) do atleta.
//
// Lê a coleção `movimentos` (cada doc tem `displayName`, `categories`,
// `prType`, `supportedPrTypes`, `prUnit` — populados pelo script
// `scripts_gerais/analise_movimentos_pr.py`) e salva os registros
// do usuário em `users/{uid}/prs/{prId}`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// Tipos de PR
// =============================================================================

enum PrType { weight, reps, time, distance }

extension PrTypeX on PrType {
  String get key => switch (this) {
    PrType.weight => 'weight',
    PrType.reps => 'reps',
    PrType.time => 'time',
    PrType.distance => 'distance',
  };

  String get label => switch (this) {
    PrType.weight => 'Carga máxima',
    PrType.reps => 'Repetições máximas',
    PrType.time => 'Tempo na posição',
    PrType.distance => 'Distância percorrida',
  };

  String get defaultUnit => switch (this) {
    PrType.weight => 'kg',
    PrType.reps => 'reps',
    PrType.time => 's',
    PrType.distance => 'm',
  };

  static PrType fromString(String? raw) {
    switch (raw) {
      case 'weight':
        return PrType.weight;
      case 'reps':
        return PrType.reps;
      case 'time':
        return PrType.time;
      case 'distance':
        return PrType.distance;
      default:
        return PrType.reps;
    }
  }
}

// =============================================================================
// Models
// =============================================================================

class Movement {
  final String id;
  final String displayName;
  final List<String> categories;
  final PrType prType;
  final List<PrType> supportedPrTypes;
  final String unit;

  const Movement({
    required this.id,
    required this.displayName,
    required this.categories,
    required this.prType,
    required this.supportedPrTypes,
    required this.unit,
  });

  factory Movement.fromFirestore(String id, Map<String, dynamic> data) {
    final categories =
        (data['categories'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();

    final prTypeRaw = data['prType'] as String?;
    final prType = PrTypeX.fromString(prTypeRaw);

    final supportedRaw =
        (data['supportedPrTypes'] as List<dynamic>? ?? const [])
            .map((e) => PrTypeX.fromString(e.toString()))
            .toList();
    final supported = supportedRaw.isEmpty ? [prType] : supportedRaw;

    return Movement(
      id: id,
      displayName: (data['displayName'] as String?) ??
          (data['name'] as String?) ??
          id,
      categories: categories,
      prType: prType,
      supportedPrTypes: supported,
      unit: (data['prUnit'] as String?) ?? prType.defaultUnit,
    );
  }
}

/// Registro de PR do atleta em `users/{uid}/prs/{prId}`.
class AthletePr {
  final String id;
  final String movementId;
  final String movementName;
  final PrType prType;
  final double value; // valor numérico (kg, reps, s ou m)
  final String unit;
  final DateTime date;

  const AthletePr({
    required this.id,
    required this.movementId,
    required this.movementName,
    required this.prType,
    required this.value,
    required this.unit,
    required this.date,
  });

  factory AthletePr.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime date;
    final raw = data['date'];
    if (raw is Timestamp) {
      date = raw.toDate();
    } else if (raw is String) {
      date = DateTime.tryParse(raw) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return AthletePr(
      id: id,
      movementId: (data['movementId'] as String?) ?? '',
      movementName: (data['movementName'] as String?) ?? '',
      prType: PrTypeX.fromString(data['prType'] as String?),
      value: (data['value'] as num? ?? 0).toDouble(),
      unit: (data['unit'] as String?) ?? '',
      date: date,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'movementId': movementId,
    'movementName': movementName,
    'prType': prType.key,
    'value': value,
    'unit': unit,
    'date': Timestamp.fromDate(date),
    'registeredAt': FieldValue.serverTimestamp(),
  };
}

// =============================================================================
// Service
// =============================================================================

class AthletePrsService {
  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não logado');
    return uid;
  }

  static CollectionReference<Map<String, dynamic>> get _prsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('prs');

  static CollectionReference<Map<String, dynamic>> get _movementsRef =>
      FirebaseFirestore.instance.collection('movimentos');

  // ── Movimentos ────────────────────────────────────────────────────────────

  /// Lê todos os movimentos e agrupa por categoria (primeira categoria do doc).
  /// Retorna um mapa { "levantamento de peso": [...], "ginástica": [...] } já
  /// ordenado alfabeticamente por categoria e, dentro dela, por nome.
  static Future<Map<String, List<Movement>>> fetchMovementsGroupedByCategory() async {
    final snap = await _movementsRef.get();
    final movements = snap.docs
        .map((d) => Movement.fromFirestore(d.id, d.data()))
        .toList();

    final Map<String, List<Movement>> grouped = {};
    for (final m in movements) {
      final cat = m.categories.isNotEmpty ? m.categories.first : 'Outros';
      grouped.putIfAbsent(cat, () => []).add(m);
    }

    // Ordena categorias e movimentos dentro de cada uma
    final sorted = <String, List<Movement>>{};
    final catKeys = grouped.keys.toList()..sort();
    for (final k in catKeys) {
      final list = grouped[k]!
        ..sort((a, b) => a.displayName.toLowerCase().compareTo(
              b.displayName.toLowerCase(),
            ));
      sorted[k] = list;
    }
    return sorted;
  }

  // ── PRs do atleta ─────────────────────────────────────────────────────────

  /// Cria um novo PR (um doc por registro — permite múltiplos PRs
  /// ao longo do tempo para o mesmo movimento).
  static Future<String> submitPr({
    required Movement movement,
    required PrType prType,
    required double value,
    required DateTime date,
    String? unit,
  }) async {
    final doc = _prsRef.doc();
    final record = AthletePr(
      id: doc.id,
      movementId: movement.id,
      movementName: movement.displayName,
      prType: prType,
      value: value,
      unit: unit ?? prType.defaultUnit,
      date: date,
    );
    await doc.set(record.toFirestore());
    return doc.id;
  }

  /// Lê todos os PRs do usuário ordenados por data (mais recentes primeiro).
  static Future<List<AthletePr>> fetchUserPrs() async {
    try {
      final snap =
          await _prsRef.orderBy('date', descending: true).get();
      return snap.docs
          .map((d) => AthletePr.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      print('ERRO fetchUserPrs: $e');
      return [];
    }
  }

  /// PRs registrados na semana corrente (dom → sáb).
  static Future<List<AthletePr>> fetchWeekPrs({
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    try {
      final snap = await _prsRef
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(weekEnd))
          .orderBy('date', descending: true)
          .get();
      return snap.docs
          .map((d) => AthletePr.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e) {
      print('ERRO fetchWeekPrs: $e');
      return [];
    }
  }

  /// Atualiza um PR existente.
  static Future<void> updatePr({
    required String prId,
    required Movement movement,
    required PrType prType,
    required double value,
    required DateTime date,
    String? unit,
  }) async {
    await _prsRef.doc(prId).update({
      'movementId': movement.id,
      'movementName': movement.displayName,
      'prType': prType.key,
      'value': value,
      'unit': unit ?? prType.defaultUnit,
      'date': Timestamp.fromDate(date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deletePr(String prId) async {
    await _prsRef.doc(prId).delete();
  }
}
