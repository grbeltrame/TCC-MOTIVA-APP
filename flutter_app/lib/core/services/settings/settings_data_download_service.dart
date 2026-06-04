import 'package:cloud_functions/cloud_functions.dart';

class SettingsDataDownloadService {
  SettingsDataDownloadService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  Future<Map<String, dynamic>> exportUserData() async {
    final response = await _functions.httpsCallable('export_user_data').call();
    final data = response.data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    throw StateError('Exportacao retornou um formato inesperado.');
  }
}
