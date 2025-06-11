// lib/shared/widgets/primary_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Botão primário azul grande usado em várias telas.
/// Recebe texto, estado de carregamento e callback.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const PrimaryButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return SizedBox(
      width: double.infinity,
      height: 48 * scale,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8 * scale),
          ),
        ),
        onPressed: isLoading ? null : onPressed,
        child:
            isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: AppFontWeight.bold,
                    fontSize: 16 * scale,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }
}
