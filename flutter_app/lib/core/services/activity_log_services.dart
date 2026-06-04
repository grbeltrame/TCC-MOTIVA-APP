import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/core/services/effort_service.dart';

/// Registra no Firestore atividades do dia do atleta.
/// Schema: users/{uid}/results/{date}_{type}[_{ms}]
class ActivityLogService {
  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não logado');
    return uid;
  }

  static CollectionReference<Map<String, dynamic>> get _resultsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('results');

  static String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// Usuário informou que NÃO treinou neste dia — dia de descanso.
  /// Salva em users/{uid}/results/{date}_REST (único por dia)
  static Future<void> logDidNotTrain({required DateTime date}) async {
    try {
      final docId = '${_dateKey(date)}_REST';
      await _resultsRef.doc(docId).set({
        'date': _dateKey(date),
        'type': 'rest',
        'registeredAt': FieldValue.serverTimestamp(),
      });
      print('✅ Dia de descanso salvo: $docId');
    } catch (e) {
      print('ERRO logDidNotTrain: $e');
      rethrow;
    }
  }

  /// Usuário informou que FEZ OUTRA ATIVIDADE FÍSICA.
  /// ID único: {date}_OTHER_{milliseconds} — permite múltiplos registros no mesmo dia
  static Future<void> logOtherActivity({
    required DateTime date,
    required String activity,
    required String trainingTime,
    required int durationMinutes,
    required int effort,
  }) async {
    try {
      final ms = DateTime.now().millisecondsSinceEpoch;
      final docId = '${_dateKey(date)}_OTHER_$ms';
      await Future.wait([
        _resultsRef.doc(docId).set({
          'date': _dateKey(date),
          'type': 'other_activity',
          'activity': activity,
          'trainingTime': trainingTime,
          'durationMinutes': durationMinutes,
          'effort': effort,
          'registeredAt': FieldValue.serverTimestamp(),
        }),
        EffortService.deleteRestIfExists(date),
      ]);
      print('✅ Outra atividade salva: $docId');
    } catch (e) {
      print('ERRO logOtherActivity: $e');
      rethrow;
    }
  }

  /// Verifica se existe QUALQUER registro para a data — treino, descanso ou
  /// outra atividade. Usado para controlar a visibilidade do botão
  /// "Não treinei hoje" na tela do atleta.
  ///
  /// Faz uma query por campo `date` em vez de buscar IDs fixos, cobrindo
  /// todos os tipos: WOD, LPO, REST, OTHER, OTHER_{ms}.
  static Future<bool> hasAnyRecordForDate(DateTime date) async {
    try {
      final snap =
          await _resultsRef
              .where('date', isEqualTo: _dateKey(date))
              .limit(1)
              .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      print('ERRO hasAnyRecordForDate: $e');
      return false;
    }
  }

  /// Atualiza uma atividade "outro" já existente pelo docId.
  static Future<void> updateOtherActivity({
    required String docId,
    required String activity,
    required String trainingTime,
    required int durationMinutes,
    required int effort,
  }) async {
    try {
      await _resultsRef.doc(docId).update({
        'activity': activity,
        'trainingTime': trainingTime,
        'durationMinutes': durationMinutes,
        'effort': effort,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Outra atividade atualizada: $docId');
    } catch (e) {
      print('ERRO updateOtherActivity: $e');
      rethrow;
    }
  }

  /// Mantido para compatibilidade — retorna o primeiro registro do dia se existir.
  static Future<Map<String, dynamic>?> fetchActivityForDate(
    DateTime date,
  ) async {
    try {
      final snap =
          await _resultsRef
              .where('date', isEqualTo: _dateKey(date))
              .limit(1)
              .get();
      if (snap.docs.isEmpty) return null;
      return snap.docs.first.data();
    } catch (e) {
      print('ERRO fetchActivityForDate: $e');
      return null;
    }
  }
}
