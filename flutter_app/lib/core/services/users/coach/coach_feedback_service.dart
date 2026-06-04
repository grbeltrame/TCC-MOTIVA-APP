import 'package:flutter_app/shared/models/feedback.dart';

/// Service responsável por enviar e (opcionalmente) ler avaliações de coach.
///
/// TODO(back):
/// - Implementar endpoints reais:
///   POST /coaches/{coachId}/ratings
///   GET  /classes/{classId}/my-rating
/// - Garantir visibilidade "admin only" no backend.
/// - Disparar notificação para admin quando chegar uma nova avaliação.
class CoachFeedbackService {
  /// Envia avaliação do coach.
  ///
  /// [rating] pode ser 0..5. Comentário é opcional.
  static Future<void> submitCoachRating({
    required String coachId,
    required String classId,
    required DateTime date,
    required int rating,
    String? comment,
    List<String>? tags, // reservado para categorias/labels futuras
  }) async {
    // Validação local leve
    if (rating < 0 || rating > 5) {
      throw ArgumentError('rating deve estar entre 0 e 5');
    }

    // Simula latência de rede
    await Future.delayed(const Duration(milliseconds: 300));

    // ===== TODO(back): substituir mock por chamada HTTP real =====
    // Exemplo de payload sugerido:
    // final payload = {
    //   "coachId": coachId,
    //   "classId": classId,
    //   "trainingDate": date.toUtc().toIso8601String(),
    //   "rating": rating,           // 0..5
    //   "comment": comment,         // opcional
    //   "tags": tags ?? [],         // opcional (ex.: "didática", "atenção", ...)
    //   "visibility": "admin_only", // impor no backend
    // };
    //
    // final res = await http.post(
    //   Uri.parse('$baseUrl/coaches/$coachId/ratings'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $token',
    //   },
    //   body: jsonEncode(payload),
    // );
    // if (res.statusCode != 201) {
    //   throw Exception('Falha ao enviar avaliação (${res.statusCode})');
    // }
  }

  /// (Opcional) Busca a avaliação do próprio usuário para uma turma,
  /// para pré-preencher o bottom sheet se já tiver avaliado.
  static Future<CoachRating?> fetchMyCoachRatingForClass(String classId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    // ===== TODO(back): GET /classes/{classId}/my-rating =====
    // final res = await http.get(Uri.parse('$baseUrl/classes/$classId/my-rating'), headers: {...});
    // if (res.statusCode == 200) {
    //   final data = jsonDecode(res.body);
    //   return CoachRating(
    //     id: data['id'],
    //     rating: data['rating'],
    //     comment: data['comment'],
    //     createdAt: DateTime.parse(data['createdAt']).toLocal(),
    //   );
    // }
    // if (res.statusCode == 404) return null;
    // throw Exception('Erro ao buscar avaliação (${res.statusCode})');

    // Mock: sem avaliação existente
    return null;
  }
}
