import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TrainingUploadResult {
  final bool ok;
  final String? url;
  final String? error;

  TrainingUploadResult({required this.ok, this.url, this.error});
}

class TrainingUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Envia o PDF dos treinos para o Firebase Storage.
  Future<TrainingUploadResult> uploadTrainingPdf({
    required Uint8List bytes,
    required String filename,
    required String boxId,
    required DateTime date,
  }) async {
    try {
      // 1. Validar Usuário Logado
      final User? user = _auth.currentUser;
      if (user == null) {
        return TrainingUploadResult(ok: false, error: "Usuário não logado");
      }
      final String userId = user.uid;

      // 2. Definir o caminho do arquivo no Storage
      // Ex: uploads/uid_do_usuario/17092230000_treino.pdf
      // Usamos timestamp para evitar nomes duplicados
      final String uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$filename';
      final String filePath = 'uploads/$userId/$uniqueName';

      final Reference ref = _storage.ref().child(filePath);

      // 3. PREPARAR METADADOS (O Passo Mais Importante!)
      // Isso conecta o Flutter ao Python. O Python lê 'boxId' e 'userId' daqui.
      final metadata = SettableMetadata(
        contentType: 'application/pdf',
        customMetadata: {
          'userId': userId,
          'boxId': boxId,
          'targetDate': date.toIso8601String(), // Data alvo do treino
        },
      );

      // 4. Fazer o Upload (usando putData pois temos bytes)
      final UploadTask task = ref.putData(bytes, metadata);

      // (Opcional) Se quiser mostrar progresso na UI, você pode escutar task.snapshotEvents aqui

      // Aguarda o upload terminar
      final TaskSnapshot snapshot = await task;

      // 5. Pegar a URL pública do arquivo (caso precise salvar ou mostrar)
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print("Upload Sucesso! Cloud Function disparada.");

      return TrainingUploadResult(
        ok: true,
        url: downloadUrl,
      );

    } catch (e) {
      print("Erro no upload do PDF: $e");
      return TrainingUploadResult(
        ok: false,
        error: e.toString(),
      );
    }
  }
}