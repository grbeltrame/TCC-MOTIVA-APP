// lib/core/services/athlete_service.dart

import 'dart:async';

import 'package:flutter_app/shared/models/athlete_profile.dart';
import 'package:flutter_app/core/services/training_service.dart';

/// Serviço para trazer (_mock_) perfil do usuário.
class AthleteService {
  static Future<AthleteProfileReference> fetchAthleteProfileReference() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: substituir este mock por chamada real ao backend
    return AthleteProfileReference(
      gender: 'Mulheres',
      ageRange: 'Entre 20 e 30 anos',
      weightRange: 'Entre 50 e 60 kg',
      practiceYears: 'Entre 3 e 5 anos de prática',
      heightRange: 'Mais de 170 cm',
    );
  }

  /// Busca o perfil completo do atleta.
  static Future<AthleteProfile> fetchAthleteProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: substituir este mock por chamada real ao backend
    return AthleteProfile(
      name: 'Camila Souza',
      photoUrl: null, // ou URL real
      category: 'Intermediario', // simula perfil ainda incompleto
      reference: await AthleteService.fetchAthleteProfileReference(),
      boxes: await TrainingService.fetchUserBoxes().then(
        (list) => list.map((b) => b.name).toList(),
      ),
    );
  }
}
