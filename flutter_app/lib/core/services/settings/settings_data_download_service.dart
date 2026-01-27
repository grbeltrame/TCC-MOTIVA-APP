class DataDownloadRequest {
  final String status; // 'idle' | 'requested' | 'processing' | 'ready'
  final DateTime? requestedAt;

  DataDownloadRequest({required this.status, this.requestedAt});

  factory DataDownloadRequest.defaults() =>
      DataDownloadRequest(status: 'idle', requestedAt: null);
}

/// ✅ MOCK
/// TODO(BACKEND): criar job, armazenar status, gerar link
class SettingsDataDownloadService {
  static DataDownloadRequest _cache = DataDownloadRequest.defaults();

  Future<DataDownloadRequest> fetchStatus() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _cache;
  }

  Future<void> requestDownload() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _cache = DataDownloadRequest(
      status: 'requested',
      requestedAt: DateTime.now(),
    );
  }
}
