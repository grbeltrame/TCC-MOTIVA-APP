// lib/features/user/coach/edit_profile/widgets/profile_photo_picker.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';

import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

class ProfilePhotoPicker extends StatelessWidget {
  const ProfilePhotoPicker({
    super.key,
    required this.scale,
    required this.photoUrl,
    required this.localPhotoPath,
    required this.onPhotoChanged,
  });

  final double scale;
  final String? photoUrl;
  final String? localPhotoPath;
  final ValueChanged<String> onPhotoChanged;

  Future<void> _pickAndCrop(BuildContext context) async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cortar foto',
          toolbarColor: AppColors.baseBlue,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'Cortar foto', aspectRatioLockEnabled: true),
      ],
    );

    if (cropped == null) return;

    onPhotoChanged(cropped.path);
  }

  @override
  Widget build(BuildContext context) {
    final size = 92.0 * scale;

    ImageProvider? provider;

    if (localPhotoPath != null && localPhotoPath!.trim().isNotEmpty) {
      provider = FileImage(File(localPhotoPath!));
    } else if (photoUrl != null && photoUrl!.trim().isNotEmpty) {
      provider = NetworkImage(photoUrl!);
    }

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.lightGray,
            image:
                provider != null
                    ? DecorationImage(image: provider, fit: BoxFit.cover)
                    : null,
          ),
          child:
              provider == null
                  ? Icon(
                    Icons.person,
                    size: 42 * scale,
                    color: AppColors.mediumGray,
                  )
                  : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: () => _pickAndCrop(context),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 32 * scale,
              height: 32 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Icon(
                Icons.edit,
                size: 18 * scale,
                color: AppColors.darkText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
