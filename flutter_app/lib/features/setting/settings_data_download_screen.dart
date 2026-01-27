import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/settings/settings_data_download_service.dart';
import 'package:flutter_app/features/setting/settings_scafold.dart';

class SettingsDataDownloadScreen extends StatefulWidget {
  static const routeName = '/settings/data_download';
  const SettingsDataDownloadScreen({super.key});

  @override
  State<SettingsDataDownloadScreen> createState() =>
      _SettingsDataDownloadScreenState();
}

class _SettingsDataDownloadScreenState
    extends State<SettingsDataDownloadScreen> {
  final _service = SettingsDataDownloadService();
  late Future<DataDownloadRequest> _future;
  DataDownloadRequest _status = DataDownloadRequest.defaults();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DataDownloadRequest> _load() async {
    final s = await _service.fetchStatus();
    _status = s;
    return s;
  }

  Future<void> _request() async {
    if (_loading) return;
    setState(() => _loading = true);
    await _service.requestDownload();
    final s = await _service.fetchStatus();
    setState(() {
      _status = s;
      _loading = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solicitação enviada. Você será avisado quando estiver pronto.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SettingsScaffold(
      child: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final requestedAt = _status.requestedAt;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 8 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SettingsHeader(title: 'Download de dados'),
                Text(
                  'Você pode solicitar um arquivo com seus dados do aplicativo.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
                SizedBox(height: 12 * scale),

                Container(
                  padding: EdgeInsets.all(12 * scale),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightGray),
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${_status.status}',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 13 * scale,
                          fontWeight: AppFontWeight.bold,
                          color: AppColors.darkText,
                        ),
                      ),
                      if (requestedAt != null) ...[
                        SizedBox(height: 6 * scale),
                        Text(
                          'Solicitado em: ${requestedAt.day}/${requestedAt.month}/${requestedAt.year}',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 12 * scale,
                            color: AppColors.mediumGray,
                          ),
                        ),
                      ],
                      SizedBox(height: 10 * scale),
                      Text(
                        'TODO(BACKEND): gerar arquivo, armazenar link e notificar.',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 11 * scale,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16 * scale),

                SizedBox(
                  width: double.infinity,
                  height: 44 * scale,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _request,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(MaterialState.disabled)) {
                          return AppColors.lightGray;
                        }
                        return AppColors.baseBlue;
                      }),
                      elevation: const MaterialStatePropertyAll(0),
                    ),
                    child: Text(
                      _loading ? 'Enviando...' : 'Solicitar download',
                    ),
                  ),
                ),

                SizedBox(height: 24 * scale),
              ],
            ),
          );
        },
      ),
    );
  }
}
