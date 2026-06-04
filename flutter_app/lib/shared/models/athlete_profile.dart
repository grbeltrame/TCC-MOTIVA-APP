// lib/shared/models/athlete_profile.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// 1. MODELO SIMPLES (Leitura rápida — mantido para compatibilidade)
// =============================================================================

/// Detalhes demográficos do atleta (perfil referência).
class AthleteProfileReference {
  final String gender;
  final String ageRange;
  final String weight;
  final String practiceYears;
  final String height;

  AthleteProfileReference({
    required this.gender,
    required this.ageRange,
    required this.weight,
    required this.practiceYears,
    required this.height,
  });
}

/// Perfil simples para leitura rápida (usado em cards e telas de exibição).
class AthleteProfile {
  final String name;
  final String? photoUrl;
  final String? category;
  final AthleteProfileReference? reference;
  final List<String> boxes;

  AthleteProfile({
    required this.name,
    this.photoUrl,
    this.category,
    this.reference,
    this.boxes = const [],
  });
}

// =============================================================================
// 2. MODELO EDITÁVEL (Estado da tela de edição)
// =============================================================================

class AthleteProfileEditable {
  // ── Campos compartilhados (salvos em users/{uid}) ─────────────────────────
  final String name;
  final String? photoUrl;
  final String? localPhotoPath; // somente UI, não salva no banco
  final DateTime? birthday;

  // ── Campos específicos do atleta (salvos em users/{uid}/profiles/athlete) ─
  final String? category; // Iniciante | Scaled | Intermediário | RX | Elite
  final String? gender;
  final String? weight;
  final String? practiceYears;
  final String? height;

  /// Fatores de atenção selecionados por categoria.
  /// Ex: { 'respiratorias': ['Asma'], 'cardiovasculares': [] }
  final Map<String, List<String>> healthFactors;

  AthleteProfileEditable({
    required this.name,
    this.photoUrl,
    this.localPhotoPath,
    this.birthday,
    this.category,
    this.gender,
    this.weight,
    this.practiceYears,
    this.height,
    Map<String, List<String>>? healthFactors,
  }) : healthFactors = healthFactors ?? {};

  // ── Desserialização ────────────────────────────────────────────────────────

  /// Constrói a partir de dois documentos Firestore:
  /// [sharedData]  → users/{uid}         (name, photoURL, birthDate)
  /// [athleteData] → users/{uid}/profiles/athlete (demais campos)
  factory AthleteProfileEditable.fromFirestore({
    required Map<String, dynamic> sharedData,
    required Map<String, dynamic> athleteData,
  }) {
    DateTime? birthday;
    final raw = sharedData['birthDate'];
    if (raw is Timestamp) birthday = raw.toDate();

    // healthFactors: { 'respiratorias': ['Asma', 'Bronquite'] }
    final rawFactors =
        (athleteData['healthFactors'] as Map<String, dynamic>?) ?? {};
    final factors = rawFactors.map(
      (k, v) => MapEntry(k, List<String>.from(v as List? ?? [])),
    );

    return AthleteProfileEditable(
      name: sharedData['name']?.toString().trim() ?? '',
      photoUrl: sharedData['photoURL']?.toString(),
      birthday: birthday,
      category: athleteData['category']?.toString(),
      gender: athleteData['gender']?.toString(),
      weight: athleteData['weight']?.toString(),
      practiceYears: athleteData['practiceYears']?.toString(),
      height: athleteData['height']?.toString(),
      healthFactors: factors,
    );
  }

  // ── Serialização ───────────────────────────────────────────────────────────

  /// Campos a salvar em users/{uid} (compartilhados com o perfil de coach).
  Map<String, dynamic> toSharedMap() => {
    'name': name,
    'birthDate': birthday != null ? Timestamp.fromDate(birthday!) : null,
  };

  /// Campos a salvar em users/{uid}/profiles/athlete.
  Map<String, dynamic> toAthleteMap() => {
    'category': category,
    'gender': gender,
    'weight': weight,
    'practiceYears': practiceYears,
    'height': height,
    'healthFactors': healthFactors,
  };

  // ── CopyWith ───────────────────────────────────────────────────────────────

  AthleteProfileEditable copyWith({
    String? name,
    String? photoUrl,
    String? localPhotoPath,
    DateTime? birthday,
    String? category,
    String? gender,
    String? weight,
    String? practiceYears,
    String? height,
    Map<String, List<String>>? healthFactors,
  }) {
    return AthleteProfileEditable(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      birthday: birthday ?? this.birthday,
      category: category ?? this.category,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      practiceYears: practiceYears ?? this.practiceYears,
      height: height ?? this.height,
      healthFactors: healthFactors ?? this.healthFactors,
    );
  }
}

// =============================================================================
// 3. SERVICE
// =============================================================================

class AthleteProfileService {
  AthleteProfileService._();
  static final AthleteProfileService instance = AthleteProfileService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  DocumentReference _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference _athleteDoc(String uid) =>
      _db.collection('users').doc(uid).collection('profiles').doc('athlete');

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<AthleteProfileEditable> fetchAthleteProfileEditable() async {
    final user = _auth.currentUser;
    if (user == null) return _empty();

    try {
      final results = await Future.wait([
        _userDoc(user.uid).get(),
        _athleteDoc(user.uid).get(),
      ]);

      final sharedSnap = results[0];
      final athleteSnap = results[1];

      final sharedData = sharedSnap.exists
          ? (sharedSnap.data() as Map<String, dynamic>)
          : <String, dynamic>{};
      final athleteData = athleteSnap.exists
          ? (athleteSnap.data() as Map<String, dynamic>)
          : <String, dynamic>{};

      // Se o doc compartilhado não tiver nome, usa o displayName do Auth
      if ((sharedData['name'] ?? '').toString().trim().isEmpty) {
        sharedData['name'] = user.displayName ?? '';
      }
      if ((sharedData['photoURL'] ?? '').toString().trim().isEmpty) {
        sharedData['photoURL'] = user.photoURL ?? '';
      }

      return AthleteProfileEditable.fromFirestore(
        sharedData: sharedData,
        athleteData: athleteData,
      );
    } catch (e) {
      print('ERRO fetchAthleteProfileEditable: $e');
      return _empty();
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> updateAthleteProfileEditable(
    AthleteProfileEditable updated,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Campos compartilhados → users/{uid} (merge para não apagar cref, etc.)
      await _userDoc(user.uid).set(updated.toSharedMap(), SetOptions(merge: true));

      // 2. Campos do atleta → users/{uid}/profiles/athlete
      await _athleteDoc(user.uid).set(updated.toAthleteMap(), SetOptions(merge: true));

      // 3. Atualiza displayName no Auth se mudou
      if (updated.name.isNotEmpty && updated.name != user.displayName) {
        await user.updateDisplayName(updated.name);
      }

      // 4. Upload de foto (futuro) — localPhotoPath ignorado aqui
    } catch (e) {
      print('ERRO updateAthleteProfileEditable: $e');
      rethrow;
    }
  }

  AthleteProfileEditable _empty() => AthleteProfileEditable(name: '');
}
