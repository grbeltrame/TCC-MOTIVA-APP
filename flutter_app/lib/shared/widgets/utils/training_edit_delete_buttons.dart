import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/widgets/dialogs/confirm_delete_training.dart';

class TrainingEditDeleteButtons extends StatelessWidget {
  final String boxId;
  final DateTime date;
  final String category;
  final TrainingBlock? currentBlock;

  /// Chamado após deletar + você querer esconder o card localmente.
  final VoidCallback? onDeleted;

  /// Chamado quando voltar da edição com sucesso (pra você recarregar).
  final VoidCallback? onEdited;

  const TrainingEditDeleteButtons({
    super.key,
    required this.boxId,
    required this.date,
    required this.category,
    required this.currentBlock,
    this.onDeleted,
    this.onEdited,
  });

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yy';
  }

  Future<void> _handleDelete(BuildContext context) async {
    final block = currentBlock;
    if (block == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há treino para apagar.')),
      );
      return;
    }

    final confirmed = await showConfirmDeleteTrainingDialog(
      context,
      trainingTitle: block.title,
      dateLabel: _fmtDate(date),
      categoryLabel: category.toUpperCase(),
    );

    if (confirmed != true) return;

    await TrainingService.deleteTraining(
      boxId: boxId,
      date: date,
      category: category,
      blockId: block.id,
    );

    if (!context.mounted) return;

    await showTrainingDeletedDialog(
      context,
      trainingTitle: block.title,
      dateLabel: _fmtDate(date),
      categoryLabel: category.toUpperCase(),
    );

    onDeleted?.call();
  }

  void _handleEdit(BuildContext context) {
    final block = currentBlock;
    if (block == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não há treino para editar.')),
      );
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.coachTrainingEdit,
      arguments: {
        'boxId': boxId,
        'date': date,
        'category': category,
        'blockId': block.id,
      },
    ).then((saved) {
      if (saved == true) {
        onEdited?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Treino atualizado com sucesso.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleDelete(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.red.shade700, width: 1.2),
              backgroundColor: Colors.red.withOpacity(0.1),
              minimumSize: Size(0, 36 * scale),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scale),
              ),
            ),
            child: Text(
              'Apagar Treino',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleEdit(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.baseBlue, width: 1.2),
              backgroundColor: AppColors.baseBlue.withAlpha(32),
              minimumSize: Size(0, 36 * scale),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scale),
              ),
            ),
            child: const Text(
              'Editar Treino',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.bold,
                color: AppColors.baseBlue,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
