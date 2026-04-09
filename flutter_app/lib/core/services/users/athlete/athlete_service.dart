// lib/core/services/athlete_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/shared/models/athlete_profile.dart';

class AthleteService {
  /// Busca o perfil do atleta logado diretamente do Firestore.
  /// Lê users/{uid} — o documento criado no signup/select_profile.
  static Future<AthleteProfile> fetchAthleteProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Fallback: usuário não logado
    if (uid == null) {
      return AthleteProfile(name: 'Atleta');
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!doc.exists) return AthleteProfile(name: 'Atleta');

      final data = doc.data()!;
      final name = data['name']?.toString().trim() ?? '';

      return AthleteProfile(
        name: name.isNotEmpty ? name : 'Atleta',
        photoUrl:
            data['photoURL']?.toString().isNotEmpty == true
                ? data['photoURL'].toString()
                : null,
        // category e reference serão preenchidos quando a edição
        // de perfil do atleta for implementada (fase futura)
        category: null,
        reference: null,
        boxes: const [],
      );
    } catch (e) {
      print('ERRO fetchAthleteProfile: $e');
      return AthleteProfile(name: 'Atleta');
    }
  }

  /// Mantido para compatibilidade — retorna referência vazia.
  /// Será implementado junto com a edição de perfil do atleta.
  static Future<AthleteProfileReference> fetchAthleteProfileReference() async {
    return AthleteProfileReference(
      gender: '',
      ageRange: '',
      weight: '',
      practiceYears: '',
      height: '',
    );
  }
}
