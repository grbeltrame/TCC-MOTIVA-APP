import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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
  bool _loading = false;

  Future<void> _download() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final data = await _service.exportUserData();
      final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = Uint8List.fromList(utf8.encode(prettyJson));
      final fileName =
          'motiva_dados_${DateTime.now().toIso8601String().split('.').first.replaceAll(':', '-')}.json';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Salvar dados do Motiva',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Download cancelado.'
                : 'Arquivo de dados salvo com sucesso.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível gerar seus dados.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SettingsScaffold(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 8 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SettingsHeader(title: 'Download de dados'),
            Text(
              'Baixe um arquivo JSON com os dados da sua conta no aplicativo.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 16 * scale),
            SizedBox(
              width: double.infinity,
              height: 44 * scale,
              child: ElevatedButton(
                onPressed: _loading ? null : _download,
                style: const ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.baseBlue),
                  elevation: WidgetStatePropertyAll(0),
                ),
                child: Text(_loading ? 'Gerando...' : 'Baixar JSON'),
              ),
            ),
            SizedBox(height: 12 * scale),
            Text(
              'O arquivo será gerado na hora e salvo no seu telefone.',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 11 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
