// lib/core/services/pending_actions_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/effort_service.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';

// =============================================================================
// Enums
// =============================================================================

enum UserRole { athlete, coach }

enum PendingActionType { athleteLogResult, coachPlanNextDay }

// =============================================================================
// Model
// =============================================================================

typedef PendingActionHandler = Future<void> Function(BuildContext context);

class PendingAction {
  final PendingActionType type;
  final String message;
  final String ctaLabel;
  final IconData ctaIcon;
  final String route;
  final PendingActionHandler? onTap;

  const PendingAction({
    required this.type,
    required this.message,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.route,
    this.onTap,
  });
}

// =============================================================================
// Service
// =============================================================================

class PendingActionsService {
  /// Verifica no Firestore se o atleta já registrou o WOD de hoje.
  /// Retorna PendingAction se não registrou, null se já registrou.
  static Future<PendingAction?> fetchTopPendingForToday() async {
    try {
      final result = await EffortService.fetchTodayResult(wodType: 'WOD');

      // Já registrou → sem pendência
      if (result != null) return null;

      // Não registrou → retorna a ação pendente
      return PendingAction(
        type: PendingActionType.athleteLogResult,
        message: 'Você ainda não registrou seu resultado do treino de hoje!',
        ctaLabel: 'Registrar agora',
        ctaIcon: Icons.edit_outlined,
        route: '',
        onTap: (context) => showRegisterResultBottomSheet(context),
      );
    } catch (e) {
      print('ERRO fetchTopPendingForToday: $e');
      // Em caso de erro não exibe o banner — evita falso positivo
      return null;
    }
  }
}
