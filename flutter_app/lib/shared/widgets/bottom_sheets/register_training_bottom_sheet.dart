// lib/shared/widgets/bottom_sheets/register_training_bottom_sheet.dart
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/core/services/users/coach/training_upload_service.dart';

import 'package:flutter_app/shared/widgets/dialogs/pdf_upload_dialogs.dart';

class RegisterTrainingBottomSheet extends StatefulWidget {
  const RegisterTrainingBottomSheet({super.key});

  @override
  State<RegisterTrainingBottomSheet> createState() =>
      _RegisterTrainingBottomSheetState();
}

class _RegisterTrainingBottomSheetState
    extends State<RegisterTrainingBottomSheet> {
  PlatformFile? _pickedFile;
  bool _uploading = false;
  String? _uploadedUrl; // mock de retorno

  final _service = TrainingUploadService();

  Future<void> _pickPdf() async {
    setState(() {
      _uploadedUrl = null;
    });

    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: kIsWeb, // no web precisamos dos bytes aqui
    );
    if (res == null || res.files.isEmpty) return;

    setState(() => _pickedFile = res.files.single);
  }

  Future<void> _uploadPdf() async {
    if (_pickedFile == null || _uploading) return;

    try {
      setState(() => _uploading = true);

      Uint8List bytes;
      if (kIsWeb) {
        bytes = _pickedFile!.bytes!;
      } else {
        final path = _pickedFile!.path!;
        bytes = await File(path).readAsBytes();
      }

      final result = await _service.uploadTrainingPdf(
        bytes: bytes,
        filename: _pickedFile!.name,
        boxId: 'BOX_123', // TODO: substituir pelo id real
        date: DateTime.now(), // TODO: substituir pela data-alvo
      );

      if (!mounted) return;
      setState(() {
        _uploadedUrl = result.url; // mock
        _uploading = false;
      });

      // ⬇️ Sucesso: dialog fecha a si e o bottom sheet
      await showPdfUploadSuccessDialog(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);

      // ⬇️ Erro: dialog com “Tentar novamente”
      await showPdfUploadErrorDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final hasFile = _pickedFile != null && !_uploading;

    return AppBottomSheet(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20 * scale,
          vertical: 20 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1) Título
            Text(
              'É hora de cadastrar os treinos para a Olympus Crossfit',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8 * scale),

            // 2) Descrição
            Text(
              'Envie o PDF dos treinos no botão abaixo e a IA irá avaliá-los',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 16 * scale),

            // “Cartão” com estado da seleção
            Container(
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(color: AppColors.mediumGray),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    color: AppColors.baseBlue,
                    size: 22 * scale,
                  ),
                  SizedBox(width: 8 * scale),
                  Expanded(
                    child: Text(
                      _pickedFile?.name ?? 'Nenhum arquivo selecionado',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scale),
                  TextButton(
                    onPressed: _uploading ? null : _pickPdf,
                    child: const Text('Escolher PDF'),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16 * scale),

            // Botão Enviar (cinza sem arquivo; azul com arquivo)
            SizedBox(
              height: 44 * scale,
              child: ElevatedButton.icon(
                onPressed: hasFile ? _uploadPdf : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return AppColors.lightGray; // cinza sem arquivo/disable
                    }
                    return AppColors.baseBlue; // azul com arquivo selecionado
                  }),
                  foregroundColor: MaterialStateProperty.resolveWith((states) {
                    if (states.contains(MaterialState.disabled)) {
                      return AppColors.mediumGray;
                    }
                    return Colors.white; // texto/ícone brancos quando ativo
                  }),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                  ),
                  elevation: const MaterialStatePropertyAll(0),
                  padding: MaterialStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12 * scale),
                  ),
                ),
                icon:
                    _uploading
                        ? SizedBox(
                          width: 18 * scale,
                          height: 18 * scale,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : const Icon(Icons.cloud_upload),
                label: Text(
                  _uploading ? 'Enviando...' : 'Enviar PDF dos treinos',
                ),
              ),
            ),
            SizedBox(height: 40 * scale),
          ],
        ),
      ),
    );
  }
}

/// Helper para abrir o bottom sheet (continua igual).
Future<void> showRegisterTrainingBottomSheet(BuildContext context) {
  return showAppBottomSheet(context, const RegisterTrainingBottomSheet());
}
