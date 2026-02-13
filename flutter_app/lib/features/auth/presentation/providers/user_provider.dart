import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _uid;
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
    return _profileType == 'athleteCoach' ||
        _profileType == 'athleteIntern' ||
        _profileType == 'admin';
  }

  /// Carrega os dados do Firestore e define o estado inicial
  Future<void> loadUserData(User user) async {
    _uid = user.uid;
    _isLoading = true;
    notifyListeners();

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(_uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _profileType = data['profile']; // A string salva no cadastro

        print("🔍 [DEBUG] Perfil carregado: '$_profileType'");

        // LÓGICA DE INICIALIZAÇÃO:
        // Decide qual tela mostrar assim que o app abre.

        switch (_profileType) {
          case 'coach':
          case 'intern':
            // Se for só Coach ou Estagiário, FORÇA a visão de Coach
            _isCoachView = true;
            break;

          case 'athlete':
            // Se for só Atleta, FORÇA a visão de Aluno
            _isCoachView = false;
            break;

          case 'athleteCoach':
          case 'athleteIntern':
          case 'admin':
            // Se for Híbrido, começamos como Coach (padrão),
            // mas o getter 'canToggleView' vai liberar o botão de troca.
            _isCoachView = true;
            break;

          default:
            // Segurança: Se der erro ou for string desconhecida, joga pro Aluno
            print("⚠️ Perfil desconhecido. Tratando como atleta.");
            _isCoachView = false;
        }
      } else {
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
    _uid = null;
    _profileType = null;
    _isCoachView = false;
    notifyListeners();
  }
}
