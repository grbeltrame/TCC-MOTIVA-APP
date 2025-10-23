import 'dart:typed_data';

class TrainingUploadResult {
  final bool ok;
  final String? url; // URL/ID do arquivo salvo (mock)

  TrainingUploadResult({required this.ok, this.url});
}

class TrainingUploadService {
  /// Envia o PDF dos treinos para o backend.
  /// TODO: Implementar chamada real da API (multipart ou upload para storage).
  Future<TrainingUploadResult> uploadTrainingPdf({
    required Uint8List bytes,
    required String filename,
    required String boxId,
    required DateTime date,
  }) async {
    // TODO: chamar sua API:
    // - POST /coach/trainings/upload
    // - headers: auth
    // - body: multipart { file: pdf, filename, boxId, date }
    await Future.delayed(const Duration(seconds: 1)); // mock de latência

    // Retorno mockado
    return TrainingUploadResult(
      ok: true,
      url:
          'https://mock.storage/treinos/$boxId/${date.toIso8601String()}/$filename',
    );
  }
}
