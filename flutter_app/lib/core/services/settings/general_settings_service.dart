import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AthleteGeneralSettings {
  final bool weeklyInsights;
  final bool evolutionInsights;
  final bool preWorkoutInsights;
  final bool trainingReminders;

  const AthleteGeneralSettings({
    required this.weeklyInsights,
    required this.evolutionInsights,
    required this.preWorkoutInsights,
    required this.trainingReminders,
  });

  factory AthleteGeneralSettings.defaults() => const AthleteGeneralSettings(
    weeklyInsights: true,
    evolutionInsights: true,
    preWorkoutInsights: true,
    trainingReminders: true,
  );

  factory AthleteGeneralSettings.fromMap(Map<String, dynamic>? data) {
    final defaults = AthleteGeneralSettings.defaults();
    if (data == null) return defaults;
    return AthleteGeneralSettings(
      weeklyInsights:
          data['weeklyInsights'] as bool? ?? defaults.weeklyInsights,
      evolutionInsights:
          data['evolutionInsights'] as bool? ?? defaults.evolutionInsights,
      preWorkoutInsights:
          data['preWorkoutInsights'] as bool? ?? defaults.preWorkoutInsights,
      trainingReminders:
          data['trainingReminders'] as bool? ?? defaults.trainingReminders,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weeklyInsights': weeklyInsights,
      'evolutionInsights': evolutionInsights,
      'preWorkoutInsights': preWorkoutInsights,
      'trainingReminders': trainingReminders,
    };
  }

  AthleteGeneralSettings copyWith({
    bool? weeklyInsights,
    bool? evolutionInsights,
    bool? preWorkoutInsights,
    bool? trainingReminders,
  }) {
    return AthleteGeneralSettings(
      weeklyInsights: weeklyInsights ?? this.weeklyInsights,
      evolutionInsights: evolutionInsights ?? this.evolutionInsights,
      preWorkoutInsights: preWorkoutInsights ?? this.preWorkoutInsights,
      trainingReminders: trainingReminders ?? this.trainingReminders,
    );
  }
}

class CoachGeneralSettings {
  final bool dailyTrainingAnalysis;
  final bool cycleAnalysis;
  final bool missingTrainingReminder;

  const CoachGeneralSettings({
    required this.dailyTrainingAnalysis,
    required this.cycleAnalysis,
    required this.missingTrainingReminder,
  });

  factory CoachGeneralSettings.defaults() => const CoachGeneralSettings(
    dailyTrainingAnalysis: true,
    cycleAnalysis: true,
    missingTrainingReminder: true,
  );

  factory CoachGeneralSettings.fromMap(Map<String, dynamic>? data) {
    final defaults = CoachGeneralSettings.defaults();
    if (data == null) return defaults;
    return CoachGeneralSettings(
      dailyTrainingAnalysis:
          data['dailyTrainingAnalysis'] as bool? ??
          defaults.dailyTrainingAnalysis,
      cycleAnalysis: data['cycleAnalysis'] as bool? ?? defaults.cycleAnalysis,
      missingTrainingReminder:
          data['missingTrainingReminder'] as bool? ??
          defaults.missingTrainingReminder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyTrainingAnalysis': dailyTrainingAnalysis,
      'cycleAnalysis': cycleAnalysis,
      'missingTrainingReminder': missingTrainingReminder,
    };
  }

  CoachGeneralSettings copyWith({
    bool? dailyTrainingAnalysis,
    bool? cycleAnalysis,
    bool? missingTrainingReminder,
  }) {
    return CoachGeneralSettings(
      dailyTrainingAnalysis:
          dailyTrainingAnalysis ?? this.dailyTrainingAnalysis,
      cycleAnalysis: cycleAnalysis ?? this.cycleAnalysis,
      missingTrainingReminder:
          missingTrainingReminder ?? this.missingTrainingReminder,
    );
  }
}

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

  Future<AthleteGeneralSettings> fetchAthleteSettings() async {
    final uid = _requiredUid();
    final doc = await _settingsDoc(uid, 'athlete').get();
    return AthleteGeneralSettings.fromMap(doc.data());
  }

  Future<void> updateAthleteSettings(AthleteGeneralSettings settings) async {
    final uid = _requiredUid();
    await _settingsDoc(uid, 'athlete').set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<CoachGeneralSettings> fetchCoachSettings() async {
    final uid = _requiredUid();
    final doc = await _settingsDoc(uid, 'coach').get();
    return CoachGeneralSettings.fromMap(doc.data());
  }

  Future<void> updateCoachSettings(CoachGeneralSettings settings) async {
    final uid = _requiredUid();
    await _settingsDoc(uid, 'coach').set({
      ...settings.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
