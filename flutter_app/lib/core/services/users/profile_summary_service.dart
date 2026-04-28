import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileSummaryCounts {
  final int totalPrs;
  final int totalWorkouts;

  ProfileSummaryCounts({required this.totalPrs, required this.totalWorkouts});
}

class ProfileSummaryService {
  static String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Usuário não logado');
    return uid;
  }

  /// Retorna a contagem total de PRs e de treinos registrados pelo atleta.
  /// - PRs: `users/{uid}/prs`
  /// - Treinos: `users/{uid}/results` excluindo dias de descanso (`*_REST`).
  ///   Inclui WODs, OTHER e qualquer outra atividade — só REST é descontado.
  static Future<ProfileSummaryCounts> fetchCounts() async {
    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(_uid);
      final prsFut = userDoc.collection('prs').count().get();
      // Lê os IDs dos results para conseguir filtrar *_REST (Firestore não
      // suporta NOT-LIKE no servidor).
      final resultsFut = userDoc.collection('results').get();
      final prs = await prsFut;
      final results = await resultsFut;
      final trainingCount = results.docs
          .where((d) => !d.id.toUpperCase().endsWith('_REST'))
          .length;
      return ProfileSummaryCounts(
        totalPrs: prs.count ?? 0,
        totalWorkouts: trainingCount,
      );
    } catch (_) {
      return ProfileSummaryCounts(totalPrs: 0, totalWorkouts: 0);
    }
  }
}
