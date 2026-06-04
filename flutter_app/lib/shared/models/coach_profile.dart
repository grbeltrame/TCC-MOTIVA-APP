import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =============================================================================
// 1. MODELO SIMPLES (Leitura rápida)
// =============================================================================
class CoachProfile {
  final String name;
  final String? photoUrl;
  final String? cref;
  final List<String> specialties;
  final List<String> certifications;

  CoachProfile({
    required this.name,
    this.photoUrl,
    this.cref,
    required this.specialties,
    required this.certifications,
  });
}

// =============================================================================
// 2. MODELO EDITÁVEL (Gerencia Estado da Tela de Edição)
// =============================================================================
class CoachProfileEditable {
  // ── Campos compartilhados (salvos em users/{uid}) ─────────────────────────
  final String name;
  final String? photoUrl;
  final String? localPhotoPath; // somente UI, não salva no banco
  final DateTime? birthday;

  // ── Campos específicos do coach (salvos em users/{uid}/profiles/coach) ────
  final String? cref;
  final List<String> certifications;
  final List<String> specialties;

  /// Catálogo de opções disponíveis (somente UI)
  final List<String> availableCertifications;
  final Map<String, List<String>> specialtiesByCategory;

  CoachProfileEditable({
    required this.name,
    this.photoUrl,
    this.localPhotoPath,
    this.birthday,
    this.cref,
    required this.certifications,
    required this.specialties,
    required this.availableCertifications,
    required this.specialtiesByCategory,
  });

  // ── Desserialização ────────────────────────────────────────────────────────

  /// Constrói a partir de dois documentos Firestore:
  /// [sharedData] → users/{uid}           (name, photoURL, birthDate)
  /// [coachData]  → users/{uid}/profiles/coach  (cref, certifications, specialties)
  factory CoachProfileEditable.fromFirestore({
    required Map<String, dynamic> sharedData,
    required Map<String, dynamic> coachData,
  }) {
    DateTime? birthday;
    final raw = sharedData['birthDate'];
    if (raw is Timestamp) birthday = raw.toDate();

    final name = sharedData['name']?.toString().trim() ?? '';
    final certifications = _cleanProfileList(
      coachData['certifications'],
      excludedValue: name,
    );
    final specialties = _cleanProfileList(
      coachData['specialties'],
      excludedValue: name,
    );

    return CoachProfileEditable(
      name: name,
      photoUrl: sharedData['photoURL']?.toString(),
      birthday: birthday,
      cref: coachData['cref']?.toString(),
      certifications: certifications,
      specialties: specialties,
      availableCertifications: _mergeUnique(
        _defaultAvailableCertifications,
        certifications,
      ),
      specialtiesByCategory: _withCustomSpecialties(specialties),
    );
  }

  // ── Serialização ───────────────────────────────────────────────────────────

  /// Campos a salvar em users/{uid} (compartilhados com atleta).
  Map<String, dynamic> toSharedMap() => {
    'name': name,
    'birthDate': birthday != null ? Timestamp.fromDate(birthday!) : null,
  };

  /// Campos a salvar em users/{uid}/profiles/coach.
  Map<String, dynamic> toCoachMap() => {
    'cref': cref,
    'certifications': _cleanProfileList(certifications, excludedValue: name),
    'specialties': _cleanProfileList(specialties, excludedValue: name),
  };

  // ── CopyWith ───────────────────────────────────────────────────────────────

  CoachProfileEditable copyWith({
    String? name,
    String? photoUrl,
    String? localPhotoPath,
    DateTime? birthday,
    String? cref,
    List<String>? certifications,
    List<String>? specialties,
    List<String>? availableCertifications,
    Map<String, List<String>>? specialtiesByCategory,
  }) {
    return CoachProfileEditable(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      birthday: birthday ?? this.birthday,
      cref: cref ?? this.cref,
      certifications: certifications ?? this.certifications,
      specialties: specialties ?? this.specialties,
      availableCertifications:
          availableCertifications ?? this.availableCertifications,
      specialtiesByCategory:
          specialtiesByCategory ?? this.specialtiesByCategory,
    );
  }
}

// =============================================================================
// 3. CONSTANTES DE CATÁLOGO
// =============================================================================
const List<String> _defaultAvailableCertifications = [
  'Bacharel em Educação Física',
  'CrossFit L1',
  'CrossFit L2',
  'Weightlifting Level 1',
];

const Map<String, List<String>> _defaultSpecialtiesByCategory = {
  'Estratégia e Planejamento': [
    'Planejamento Estratégico',
    'Periodização de Ciclos',
    'Analise de Dados para Performance',
    'Adaptação para diferentes níveis',
    'Gestão de Planilhas e Metas',
  ],
  'Técnica e Execução': [
    'Levantamento de Peso Olimpico',
    'Ginasticos',
    'Corrida e Pacing',
    'Respiração',
  ],
  'Mobilidade e Prevenção': [
    'Mobilidade articular',
    'Alongamento e Aquecimento',
    'Cuidados pós lesão',
    'Fortalecimento',
  ],
  'Motivação e Psicologia': [
    'Psicologia do esporte',
    'Gestão de Grupo',
    'Motivação de alunos',
    'Feedback individual',
  ],
  'Saude e Bem estar': ['Treinamento para terceira idade', 'Reabilitação'],
};

List<String> _cleanProfileList(dynamic raw, {String? excludedValue}) {
  final excluded = excludedValue?.trim().toLowerCase();
  final values = raw is Iterable ? raw : const [];
  final seen = <String>{};
  final result = <String>[];

  for (final item in values) {
    final value = item.toString().trim();
    if (value.isEmpty) continue;
    if (excluded != null && excluded.isNotEmpty) {
      if (value.toLowerCase() == excluded) continue;
    }
    if (seen.add(value.toLowerCase())) result.add(value);
  }

  return result;
}

List<String> _mergeUnique(List<String> defaults, List<String> custom) {
  return _cleanProfileList([...defaults, ...custom]);
}

Map<String, List<String>> _withCustomSpecialties(List<String> specialties) {
  final categories = <String, List<String>>{
    for (final entry in _defaultSpecialtiesByCategory.entries)
      entry.key: [...entry.value],
  };

  final defaultItems =
      categories.values
          .expand((items) => items)
          .map((e) => e.toLowerCase())
          .toSet();
  final custom =
      specialties
          .where((item) => !defaultItems.contains(item.toLowerCase()))
          .toList();

  if (custom.isNotEmpty) {
    categories['Outras Especialidades'] = custom;
  }

  return categories;
}

// =============================================================================
// 4. SERVICE
// =============================================================================
class CoachProfileService {
  CoachProfileService._();
  static final CoachProfileService instance = CoachProfileService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  DocumentReference _userDoc(String uid) => _db.collection('users').doc(uid);

  DocumentReference _coachDoc(String uid) =>
      _db.collection('users').doc(uid).collection('profiles').doc('coach');

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<CoachProfileEditable> fetchCoachProfileEditable() async {
    final user = _auth.currentUser;
    if (user == null) return _empty();

    try {
      final results = await Future.wait([
        _userDoc(user.uid).get(),
        _coachDoc(user.uid).get(),
      ]);

      final sharedSnap = results[0];
      final coachSnap = results[1];

      final sharedData =
          sharedSnap.exists
              ? (sharedSnap.data() as Map<String, dynamic>)
              : <String, dynamic>{};
      final coachData =
          coachSnap.exists
              ? (coachSnap.data() as Map<String, dynamic>)
              : <String, dynamic>{};

      // Fallback para displayName do Auth se o doc não tiver nome
      if ((sharedData['name'] ?? '').toString().trim().isEmpty) {
        sharedData['name'] = user.displayName ?? '';
      }
      if ((sharedData['photoURL'] ?? '').toString().trim().isEmpty) {
        sharedData['photoURL'] = user.photoURL ?? '';
      }

      return CoachProfileEditable.fromFirestore(
        sharedData: sharedData,
        coachData: coachData,
      );
    } catch (e) {
      print('ERRO fetchCoachProfileEditable: $e');
      return _empty();
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> updateCoachProfileEditable(CoachProfileEditable updated) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Campos compartilhados → users/{uid} (merge para não apagar email, profile, etc.)
      await _userDoc(
        user.uid,
      ).set(updated.toSharedMap(), SetOptions(merge: true));

      // 2. Campos do coach → users/{uid}/profiles/coach
      await _coachDoc(
        user.uid,
      ).set(updated.toCoachMap(), SetOptions(merge: true));

      // 3. Atualiza displayName no Auth se mudou
      if (updated.name.isNotEmpty && updated.name != user.displayName) {
        await user.updateDisplayName(updated.name);
      }

      // 4. Upload de foto (futuro) — localPhotoPath ignorado aqui
    } catch (e) {
      print('ERRO updateCoachProfileEditable: $e');
      rethrow;
    }
  }

  CoachProfileEditable _empty() => CoachProfileEditable(
    name: '',
    certifications: [],
    specialties: [],
    availableCertifications: _defaultAvailableCertifications,
    specialtiesByCategory: _defaultSpecialtiesByCategory,
  );
}
