import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/shared/models/profile_option.dart';

class UserProvider with ChangeNotifier {
  String? _profileType; // Ex: 'athlete', 'coach', 'athleteCoach'...
  bool _isCoachView = false; // Estado atual da tela (True=Coach, False=Aluno)
  bool _isLoading = false;

  // Getters para a UI usar
  bool get isCoachView => _isCoachView;
  bool get isLoading => _isLoading;
  String? get profileType => _profileType;

  /// Retorna TRUE se o usuário tem permissão para trocar de tela.
  /// Baseado nos tipos definidos no seu SignupScreen.
  bool get canToggleView {
    return profileTypeCanToggleView(_profileType);
  }

  /// Carrega os dados do Firestore e define o estado inicial
  Future<void> loadUserData(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profileType = await AuthService.instance.fetchUserProfileType(
        user.uid,
      );
      if (profileType != null) {
        _profileType = profileType; // A string salva no cadastro
        print("🔍 [DEBUG] Perfil carregado: '$_profileType'");

        // LÓGICA DE INICIALIZAÇÃO:
        // Decide qual tela mostrar assim que o app abre.
        _isCoachView = profileTypeStartsInCoachView(_profileType);
      } else {
        _profileType = null;
        _isCoachView = false;
        print("❌ Usuário sem documento no Firestore.");
      }
    } catch (e) {
      print("❌ Erro ao carregar usuário: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Método chamado pelo botão na AppBar para trocar a visão
  void toggleViewMode() {
    if (canToggleView) {
      _isCoachView = !_isCoachView;
      print("🔄 Trocou visão para: ${_isCoachView ? 'COACH' : 'ALUNO'}");
      notifyListeners();
    } else {
      print("🚫 Tentativa de troca negada. Perfil: $_profileType");
    }
  }

  /// Limpa os dados ao fazer Logout
  void clear() {
    _profileType = null;
    _isCoachView = false;
    notifyListeners();
  }
}
