// lib/core/services/championship_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/championship.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';

class ChampionshipService {
  // =========================================================
  // Cache local para campeonatos criados nesta sessão.
  // TODO(back): remover quando integrar POST/GET reais do backend.
  static final List<Championship> _userCreatedUpcoming = [];
  // =========================================================

  /// Retorna apenas os campeonatos cujo [startDate] está no mês corrente.
  static Future<List<Championship>> fetchUpcomingChampionships() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    // Mocks originais
    final all = <Championship>[
      Championship(
        id: 'c1',
        name: 'Sun Challenge',
        startDate: DateTime(now.year, now.month, 18),
        endDate: DateTime(now.year, now.month, 18),
      ),
      Championship(
        id: 'c2',
        name: 'Mountain Race',
        startDate: DateTime(now.year, now.month, 25),
        endDate: DateTime(now.year, now.month, 26),
      ),
    ];

    // Mescla com os criados localmente nesta sessão
    final merged = <Championship>[...all, ..._userCreatedUpcoming];

    final filtered =
        merged.where((c) {
            return c.startDate.isAfter(
                  monthStart.subtract(const Duration(days: 1)),
                ) &&
                c.startDate.isBefore(monthEnd.add(const Duration(days: 1)));
          }).toList()
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

    return filtered;
  }

  /// Retorna os últimos 5 campeonatos que já terminaram.
  static Future<List<Championship>> fetchConcludedChampionships() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    // TODO: substituir por backend e ordenar por data de término desc.
    final all = <Championship>[
      Championship(
        id: 'c3',
        name: 'TCB',
        startDate: DateTime(now.year, now.month - 1, 10),
        endDate: DateTime(now.year, now.month - 1, 10),
        userRanking: 12,
        totalParticipants: 40,
      ),
      Championship(
        id: 'c4',
        name: 'Copa Sur',
        startDate: DateTime(now.year, now.month - 2, 5),
        endDate: DateTime(now.year, now.month - 2, 5),
        userRanking: 10,
        totalParticipants: 40,
      ),
      // ... até 5
    ];
    return all.take(5).toList();
  }

  /// Cria um campeonato (mock do POST) e coloca no cache local.
  ///
  /// TODO(back):
  /// - POST /championships { name, startDate, endDate }
  /// - retornar objeto criado pelo servidor e remover o cache local
  static Future<Championship> createChampionship({
    required String name,
    required DateTime date, // data única (start == end)
    DateTime? endDate, // opcional para intervalos futuros
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final start = DateTime(date.year, date.month, date.day);
    final end =
        endDate == null
            ? start
            : DateTime(endDate.year, endDate.month, endDate.day);

    final created = Championship(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}', // id local
      name: name,
      startDate: start,
      endDate: end,
      userRanking: null,
      totalParticipants: null,
    );

    _userCreatedUpcoming.add(created);
    _userCreatedUpcoming.sort((a, b) => a.startDate.compareTo(b.startDate));

    // TODO(back): substituir por resposta do servidor
    return created;
  }

  /// Deve agendar notificações push 7 dias, 3 dias e no dia do evento.
  static Future<void> schedulePushNotifications() async {
    // TODO: usar flutter_local_notifications ou outro plugin.
  }

  /// Exibe in-app dialogs 7d, 3d e no dia do evento (chamar no build da seção).
  static void showInAppNotifications(
    BuildContext context,
    List<Championship> ups,
  ) {
    final now = DateTime.now();
    for (var c in ups) {
      final diff = c.startDate.difference(now).inDays;
      if ({7, 3, 0}.contains(diff)) {
        final title =
            diff == 0
                ? 'Hoje é o dia de "${c.name}"!'
                : 'Faltam $diff dias para "${c.name}"';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder:
                (_) => AppDialog(
                  icon: Icons.emoji_events,
                  title: title,
                  message: 'Não esqueça de se preparar.',
                  primaryAction: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ),
          );
        });
      }
    }
  }

  /// Notificar no dia seguinte ao fim para registrar resultado.
  static void showPostEventNotification(
    BuildContext context,
    List<Championship> concluded,
  ) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    for (var c in concluded) {
      if (c.endDate.year == yesterday.year &&
          c.endDate.month == yesterday.month &&
          c.endDate.day == yesterday.day) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder:
                (_) => AppDialog(
                  icon: Icons.edit,
                  title: 'Como foi "${c.name}"?',
                  message: 'Registre seu resultado.',
                  primaryAction: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Registrar'),
                  ),
                ),
          );
        });
      }
    }
  }

  /// Indica se o usuário quer ver a seção de Campeonatos.
  /// TODO: substituir o hard-code por leitura de preferência real (backend ou local storage).
  static Future<bool> fetchChampionshipSectionEnabled() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true; // ← por enquanto sempre ativo
  }
}
