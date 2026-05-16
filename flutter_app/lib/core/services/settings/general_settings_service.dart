import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrivacySettingsState {
  final bool aiPersonalizationEnabled;
  final bool diagnosticsEnabled;

  const PrivacySettingsState({
    required this.aiPersonalizationEnabled,
    required this.diagnosticsEnabled,
  });

  factory PrivacySettingsState.defaults() => const PrivacySettingsState(
    aiPersonalizationEnabled: true,
    diagnosticsEnabled: true,
  );

  factory PrivacySettingsState.fromMap(Map<String, dynamic>? data) {
    final defaults = PrivacySettingsState.defaults();
    if (data == null) return defaults;
    return PrivacySettingsState(
      aiPersonalizationEnabled:
          data['aiPersonalizationEnabled'] as bool? ??
          defaults.aiPersonalizationEnabled,
      diagnosticsEnabled:
          data['diagnosticsEnabled'] as bool? ?? defaults.diagnosticsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'aiPersonalizationEnabled': aiPersonalizationEnabled,
      'diagnosticsEnabled': diagnosticsEnabled,
    };
  }

  PrivacySettingsState copyWith({
    bool? aiPersonalizationEnabled,
    bool? diagnosticsEnabled,
  }) {
    return PrivacySettingsState(
      aiPersonalizationEnabled:
          aiPersonalizationEnabled ?? this.aiPersonalizationEnabled,
      diagnosticsEnabled: diagnosticsEnabled ?? this.diagnosticsEnabled,
    );
  }
}

class UserSettingsService {
  UserSettingsService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  static final UserSettingsService instance = UserSettingsService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _settingsDoc(String uid, String id) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc(id);
  }

  String _requiredUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Usuario nao autenticado.');
    }
    return uid;
  }

  Future<PrivacySettingsState> fetchPrivacySettings() async {
    final uid = _requiredUid();
    final doc = await _settingsDoc(uid, 'privacy').get();
    return PrivacySettingsState.fromMap(doc.data());
  }

  Future<void> updatePrivacySettings(PrivacySettingsState settings) async {
    final uid = _requiredUid();
    await _settingsDoc(uid, 'privacy').set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
