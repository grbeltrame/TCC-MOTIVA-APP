import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/primary_button.dart';

/// SECTION pública: dois botões no padrão do projeto.
/// - "Cadastrar Treino": abre bottom sheet (placeholder por enquanto)
/// - "Ver treinos cadastrados": navega para a página de listagem
class CoachTrainingsActionsSection extends StatelessWidget {
  const CoachTrainingsActionsSection({super.key});

  void _openCreateTrainingSheet(BuildContext context) {
    // Placeholder do bottom sheet – vamos substituir pelo fluxo real depois
    showAppBottomSheet(context, const _CreateTrainingSheetPlaceholder());
  }

  void _goToRegisteredTrainings(BuildContext context) {
    // TODO(nav): confirmar se esta rota está certa no seu AppRoutes
    Navigator.pushNamed(context, AppRoutes.coachRegisteredTrainings);
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Row(
      children: [
        // Botão preenchido — usa o seu PrimaryButton
        Expanded(
          child: PrimaryButton(
            label: 'Cadastrar Treino',
            onPressed: () => _openCreateTrainingSheet(context),
          ),
        ),
        SizedBox(width: 12 * scale),
        // Botão contornado — estilo alinhado ao DS do projeto
        Expanded(
          child: _OutlinedActionButton(
            label: 'Ver treinos cadastrados',
            onPressed: () => _goToRegisteredTrainings(context),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet temporário — só para manter a navegação funcionando.
/// Trocaremos pelo conteúdo real quando formos construir o fluxo.
class _CreateTrainingSheetPlaceholder extends StatelessWidget {
  const _CreateTrainingSheetPlaceholder();

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final inset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        16 * scale,
        16 * scale,
        inset + 16 * scale,
      ),
      child: SizedBox(
        height: 320 * scale,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cadastrar Treino',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
              ),
            ),
            SizedBox(height: 12 * scale),
            Text(
              'Bottom sheet placeholder.\nVamos substituir pelo fluxo real no próximo passo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão contornado no padrão visual do projeto.
/// Mantém tipografia e cores de AppColors/AppFonts.
class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlinedActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SizedBox(
      width: double.infinity,
      height: 48 * scale,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.darkBlue, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          foregroundColor: AppColors.darkBlue,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
            fontSize: 16 * scale,
            color: AppColors.darkBlue,
          ),
        ),
      ),
    );
  }
}
