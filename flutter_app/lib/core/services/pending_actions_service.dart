import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
// TODO backend: traga o papel do usuário de um ProfileService real
// import 'package:flutter_app/core/services/profile_service.dart';

enum UserRole { athlete, coach }

enum PendingActionType {
  athleteLogResult,
  athleteLogEffort,
  athletePickTime,
  coachPlanNextDay,
}

class PendingAction {
  final PendingActionType type;
  final String message;
  final String ctaLabel;
  final IconData ctaIcon;
  final String route; // rota genérica para navegação

  const PendingAction({
    required this.type,
    required this.message,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.route,
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
    return (needResult: true, needEffort: false, needTime: false);
  }

  /// Mock da pendência do COACH (treinos de amanhã).
  static Future<bool> fetchCoachNeedPlanNextDay(DateTime day) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // TODO backend: checar se não existem treinos cadastrados para (day + 1)
    return false;
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
        return const PendingAction(
          type: PendingActionType.athleteLogResult,
          message: 'Você ainda não registrou o resultado do treino de hoje!',
          ctaLabel: 'Registrar agora',
          ctaIcon: Icons.edit,
          route: '/athlete/trainings/result', // TODO ajustar rota real
        );
      }
      if (flags.needEffort) {
        return const PendingAction(
          type: PendingActionType.athleteLogEffort,
          message: 'Você ainda não registrou seu esforço no treino de hoje!',
          ctaLabel: 'Registrar agora',
          ctaIcon: Icons.edit,
          route: '/athlete/trainings/effort', // TODO ajustar rota real
        );
      }
      if (flags.needTime) {
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
