// lib/shared/widgets/box_signup_coach.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Bottom sheet específico para cadastro de Box pelo Coach.
class BoxSignupCoach extends StatelessWidget {
  const BoxSignupCoach({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // O AppBottomSheet cuida do background e do keyboard padding
    return AppBottomSheet(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cadastrar novo Box',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 16),

            // TODO: trocar por um verdadeiro Form
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nome do Box'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Endereço'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Contato'),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: enviar os dados ao backend
                  Navigator.of(context).pop();
                },
                child: const Text('Cadastrar'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
