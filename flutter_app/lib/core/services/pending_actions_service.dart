import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/effort_only_bottom_sheet.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';

// TODO backend: traga o papel do usuário de um ProfileService real
// import 'package:flutter_app/core/services/profile_service.dart';

// IMPORT do bottom sheet (ajuste o caminho se necessário)
import 'package:flutter_app/shared/widgets/bottom_sheets/register_result_bottom_sheet.dart';

enum UserRole { athlete, coach }

enum PendingActionType {
  athleteLogResult,
  athleteLogEffort,
  athletePickTime,
  coachPlanNextDay,
}

// Handler opcional para executar ação de UI (ex.: abrir bottom sheet)
typedef PendingActionHandler = Future<void> Function(BuildContext context);

class PendingAction {
  final PendingActionType type;
  final String message;
  final String ctaLabel;
  final IconData ctaIcon;
  final String route; // rota genérica para navegação
  final PendingActionHandler? onTap; // se definido, usar isto no CTA

  const PendingAction({
    required this.type,
    required this.message,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.route,
    this.onTap,
  });
}

class PendingActionsService {
  /// Retorna o papel do usuário logado.
  static Future<UserRole> fetchUserRole() async {
    await Future.delayed(const Duration(milliseconds: 120));
    // TODO backend: obter do ProfileService/Auth
    return UserRole.athlete; // mock: altere pra testar
  }

  /// Retorna se o usuário deseja ver pendências (se algum dia virar preferência).
  static Future<bool> fetchShowPendingBanner() async {
    await Future.delayed(const Duration(milliseconds: 80));
    // TODO backend: preferência do usuário
    return true;
  }

  /// Mock das flags de pendência do ALUNO para o dia.
  static Future<({bool needResult, bool needEffort, bool needTime})>
  fetchAthletePendenciesForToday(DateTime day) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO backend: checar no servidor (hoje) se faltam registros
    return (needResult: false, needEffort: true, needTime: false);
  }

  /// Mock da pendência do COACH (treinos de amanhã).
  static Future<bool> fetchCoachNeedPlanNextDay(DateTime day) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO backend: checar se não existem treinos cadastrados para (day + 1)
    return false;
  }

  /// Escolhe a turma do dia para abrir o sheet de esforço.
  /// Prioriza WOD; se não houver, usa a primeira.
  static Future<String?> _pickTodayClassId() async {
    final today = DateTime.now();
    final classes = await WorkoutResultService.fetchClassesForDate(today);
    if (classes.isEmpty) return null;

    // Prioriza WOD
    final wod = classes.where((c) => c.type.toUpperCase() == 'WOD');
    return wod.isNotEmpty ? wod.first.id : classes.first.id;
  }

  /// Abre o bottom sheet de esforço+adaptações+results (results já preenchidos pelo coach).
  static Future<void> _openEffortOnlyBottomSheet(BuildContext context) async {
    final classId = await _pickTodayClassId();

    // Se não achou turma, como fallback abrimos o sheet padrão (você pode ajustar)
    if (classId == null) {
      await showRegisterResultBottomSheet(context);
      return;
    }

    final today = DateTime.now();
    final trainingDate = DateTime(today.year, today.month, today.day);

    await showEffortOnlyBottomSheet(
      context,
      classId: classId,
      trainingDate: trainingDate,
    );
  }

  /// Retorna **apenas uma** pendência priorizada para hoje.
  static Future<PendingAction?> fetchTopPendingForToday() async {
    final show = await fetchShowPendingBanner();
    if (!show) return null;

    final role = await fetchUserRole();
    final today = DateTime.now();

    if (role == UserRole.athlete) {
      final flags = await fetchAthletePendenciesForToday(today);

      // Prioridade: Resultado > Esforço > Horário
      if (flags.needResult) {
        return PendingAction(
          type: PendingActionType.athleteLogResult,
          message: 'Você ainda não registrou o resultado do treino de hoje!',
          ctaLabel: 'Registrar agora',
          ctaIcon: Icons.edit,
          route: '/athlete/trainings/result', // fallback se não houver onTap
          onTap: (context) => showRegisterResultBottomSheet(context),
        );
      }

      if (flags.needEffort) {
        return PendingAction(
          type: PendingActionType.athleteLogEffort,
          message: 'Você ainda não registrou seu esforço no treino de hoje!',
          ctaLabel: 'Registrar agora',
          ctaIcon: Icons.edit,
          route: '/athlete/trainings/effort', // fallback se não houver onTap
          onTap: (context) => _openEffortOnlyBottomSheet(context),
        );
      }

      if (flags.needTime) {
        // "Registrar interesse em aula" => navegar de página
        return const PendingAction(
          type: PendingActionType.athletePickTime,
          message: 'Você ainda não indicou seu horário de treino de hoje.',
          ctaLabel: 'Escolher horário',
          ctaIcon: Icons.edit,
          route: '/athlete/trainings/schedule', // TODO ajustar rota real
        );
      }

      return null;
    } else {
      final needPlan = await fetchCoachNeedPlanNextDay(today);
      if (needPlan) {
        // "Registrar treino para o professor" => navegar de página
        return const PendingAction(
          type: PendingActionType.coachPlanNextDay,
          message: 'Você ainda não cadastrou os treinos de amanhã.',
          ctaLabel: 'Planejar treinos',
          ctaIcon: Icons.edit,
          route: '/coach/trainings/plan-next-day', // TODO ajustar rota real
        );
      }
      return null;
    }
  }
}
