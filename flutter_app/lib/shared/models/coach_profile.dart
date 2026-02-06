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
  final String name;
  final String? photoUrl;
  final String? localPhotoPath; // Apenas UI (não salva no banco)
  final String? cref;
  final DateTime? birthday;

  /// ✅ APENAS selecionadas (Salvas no Banco)
  final List<String> certifications;
  final List<String> specialties;

  /// ✅ Catálogo (Opções disponíveis para marcar)
  final List<String> availableCertifications;
  final Map<String, List<String>> specialtiesByCategory;

  CoachProfileEditable({
    required this.name,
    this.photoUrl,
    this.localPhotoPath,
    this.cref,
    this.birthday,
    required this.certifications,
    required this.specialties,
    required this.availableCertifications,
    required this.specialtiesByCategory,
  });

  // --- MÉTODOS DE CONVERSÃO FIREBASE ---

  /// Converte o documento do Firestore para o Objeto
  factory CoachProfileEditable.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CoachProfileEditable(
      name: data['name'] ?? '',
      photoUrl: data['photoURL'], // Padrão Firebase Auth
      cref: data['cref'],
      birthday: data['birthDate'] != null 
          ? (data['birthDate'] as Timestamp).toDate() 
          : null,
      
      // Listas salvas no banco
      certifications: List<String>.from(data['certifications'] ?? []),
      specialties: List<String>.from(data['specialties'] ?? []),

      // 👇 INJETAMOS AS OPÇÕES PADRÃO AQUI
      // (Mantive suas listas originais hardcoded para alimentar a UI)
      availableCertifications: _defaultAvailableCertifications,
      specialtiesByCategory: _defaultSpecialtiesByCategory,
    );
  }

  /// Converte o Objeto para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cref': cref,
      'birthDate': birthday != null ? Timestamp.fromDate(birthday!) : null,
      'certifications': certifications,
      'specialties': specialties,
      // Nota: photoURL e localPhotoPath são tratados separadamente 
      // ou via Auth update, não necessariamente aqui.
    };
  }

  // --- COPY WITH ---
  CoachProfileEditable copyWith({
    String? name,
    String? photoUrl,
    String? localPhotoPath,
    String? cref,
    DateTime? birthday,
    List<String>? certifications,
    List<String>? specialties,
    List<String>? availableCertifications,
    Map<String, List<String>>? specialtiesByCategory,
  }) {
    return CoachProfileEditable(
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      cref: cref ?? this.cref,
      birthday: birthday ?? this.birthday,
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
// 3. CONSTANTES DE CATÁLOGO (Mantidas do seu código original)
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
  'Saude e Bem estar': [
    'Treinamento para terceira idade',
    'Reabilitação',
  ],
};

// =============================================================================
// 4. SERVICE (CONECTADO AO FIREBASE)
// =============================================================================
class CoachProfileService {
  CoachProfileService._();
  static final CoachProfileService instance = CoachProfileService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca o perfil do usuário logado no Firestore
  Future<CoachProfileEditable> fetchCoachProfileEditable() async {
    final user = _auth.currentUser;
    
    if (user == null) {
      // Retorna um perfil vazio/padrão se não estiver logado (modo fallback)
      return _createEmptyProfile();
    }

    try {
      final docSnapshot = await _firestore.collection('users').doc(user.uid).get();

      if (!docSnapshot.exists) {
        // Se o usuário existe no Auth mas não tem doc no banco, cria um básico visual
        return CoachProfileEditable(
          name: user.displayName ?? '',
          photoUrl: user.photoURL,
          certifications: [],
          specialties: [],
          availableCertifications: _defaultAvailableCertifications,
          specialtiesByCategory: _defaultSpecialtiesByCategory,
        );
      }

      return CoachProfileEditable.fromFirestore(docSnapshot);
    } catch (e) {
      print('Erro ao buscar perfil: $e');
      return _createEmptyProfile();
    }
  }

  /// Salva as alterações no Firestore
  Future<void> updateCoachProfileEditable(CoachProfileEditable updated) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 1. Converte para Map
      final dataToSave = updated.toMap();

      // 2. Atualiza no Firestore (merge true para não apagar outros campos como email)
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(dataToSave, SetOptions(merge: true));

      // 3. Atualiza DisplayName no Auth (opcional, mas recomendado)
      if (updated.name.isNotEmpty && updated.name != user.displayName) {
        await user.updateDisplayName(updated.name);
      }
      
      // 4. Se tiver Upload de foto (lógica futura), seria aqui.
      // O campo localPhotoPath é ignorado no save do banco.
      
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  CoachProfileEditable _createEmptyProfile() {
    return CoachProfileEditable(
      name: '',
      certifications: [],
      specialties: [],
      availableCertifications: _defaultAvailableCertifications,
      specialtiesByCategory: _defaultSpecialtiesByCategory,
    );
  }
}