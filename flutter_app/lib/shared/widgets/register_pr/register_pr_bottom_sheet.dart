// lib/shared/widgets/register_pr/register_pr_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/pr_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:flutter_app/shared/widgets/register_pr/section_pr_form.dart';
import 'package:flutter_app/shared/widgets/register_result/section_effort.dart';

Future<void> showRegisterPrBottomSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _RegisterPrSheet(),
  );
}

class _RegisterPrSheet extends StatefulWidget {
  const _RegisterPrSheet({super.key});

  @override
  State<_RegisterPrSheet> createState() => _RegisterPrSheetState();
}

class _RegisterPrSheetState extends State<_RegisterPrSheet> {
  final _formKey = GlobalKey<SectionPrFormState>();
  int _effort = 5; // 1..10

  Future<void> _handleSubmit() async {
    final error = _formKey.currentState?.validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final v = _formKey.currentState!.value;

    await PRService.submitPr(
      category: v.category,
      date: v.date,
      movement: v.movement,
      weightKg: v.weightKg,
      reps: v.reps,
      benchmark: v.benchmark,
      adapted: v.adapted,
      wodType: v.wodType,
      timeSeconds: v.timeSeconds,
      amrapRounds: v.amrapRounds,
      amrapReps: v.amrapReps,
      adaptations: v.adaptations,
      effort: _effort,
    );

    if (!mounted) return;

    // Fecha o sheet
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    await Future.microtask(() {});

    if (!mounted) return;

    // Dialog de sucesso
    await showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder:
          (dCtx) => AppDialog(
            icon: Icons.check_rounded,
            title: 'Seu PR  foi registrado!',
            message:
                'Você está cada vez melhor. Continue assim que os resultados vem!',
            secondaryAction: TextButton(
              onPressed: () {
                Navigator.of(dCtx, rootNavigator: true).pop();
                Navigator.of(
                  dCtx,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.athletePrList);
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.baseBlue),
              child: const Text('Ver lista de PRs'),
            ),
            primaryAction: TextButton(
              onPressed: () => Navigator.of(dCtx, rootNavigator: true).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
              child: const Text('OK'),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return AppBottomSheet(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          10 * scale,
          16 * scale,
          16 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle
            Center(
              child: Container(
                width: 40 * scale,
                height: 4 * scale,
                decoration: BoxDecoration(
                  color: AppColors.mediumGray.withValues(alpha: .6),
                  borderRadius: BorderRadius.circular(2 * scale),
                ),
              ),
            ),
            SizedBox(height: 12 * scale),

            Text(
              'Vamos registrar um novo PR?',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 20 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 12 * scale),

            // === Formulário do PR ===
            SectionPrForm(key: _formKey),

            const Divider(height: 28),

            // === Slider de esforço (reuso) ===
            SectionEffort(
              classId: null,
              onEffortChanged: (val) => _effort = val,
            ),

            // Botões
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: AppTheme.secondaryButtonStyle(
                      AppColors.darkBlue,
                      AppColors.baseBlue,
                    ),
                    onPressed: _handleSubmit,
                    child: const Text('Registrar'),
                  ),
                  OutlinedButton(
                    style: AppTheme.tertiaryButtonStyle(AppColors.baseMagenta),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
