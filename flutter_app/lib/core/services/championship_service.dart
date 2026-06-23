// lib/core/services/championship_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/championship.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';

class ChampionshipService {
  // ====== Caches locais (mock) =================================================
  static final List<Championship> _userCreatedUpcoming = [];
  static final List<Championship> _userConcluded = [];
  static final Set<String> _movedFromUpcomingIds = {};
  static final Set<String> _deletedUpcomingIds = {};
  static final Set<String> _firedInAppKeys = <String>{};

  /// Notificador global de mudanças (criar, deletar, concluir)
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static void _bump() => changes.value = changes.value + 1;
  // ============================================================================

  // ---- Mocks base -------------------------------------------------------------
  static List<Championship> _builtInUpcomingForCurrentMonth() {
    final now = DateTime.now();
    return <Championship>[
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
  }

  static List<Championship> _builtInConcluded() {
    final now = DateTime.now();
    return <Championship>[
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
    ];
  }
  // -----------------------------------------------------------------------------

  /// Próximos **do mês corrente**
  static Future<List<Championship>> fetchUpcomingChampionships() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final merged = <Championship>[
      ..._builtInUpcomingForCurrentMonth(),
      ..._userCreatedUpcoming,
    ];

    return merged
        .where((c) => !_movedFromUpcomingIds.contains(c.id))
        .where((c) => !_deletedUpcomingIds.contains(c.id))
        .where(
          (c) =>
              c.startDate.isAfter(
                monthStart.subtract(const Duration(days: 1)),
              ) &&
              c.startDate.isBefore(monthEnd.add(const Duration(days: 1))),
        )
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Concluídos (limitado a 5, mais recentes primeiro)
  static Future<List<Championship>> fetchConcludedChampionships() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final merged = <Championship>[..._userConcluded, ..._builtInConcluded()];
    merged.sort((a, b) => b.endDate.compareTo(a.endDate));
    return merged.take(5).toList();
  }

  // ===== NOVOS para “Ver todos” ===============================================

  /// TODOS os próximos (sem filtro de mês), ordenados do mais próximo p/ o mais distante.
  static Future<List<Championship>> fetchAllUpcoming() async {
    await Future.delayed(const Duration(milliseconds: 250)); // TODO(back)
    final merged = <Championship>[
      ..._builtInUpcomingForCurrentMonth(),
      ..._userCreatedUpcoming,
    ];

    return merged
        .where((c) => !_movedFromUpcomingIds.contains(c.id))
        .where((c) => !_deletedUpcomingIds.contains(c.id))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// TODOS os concluídos (sem limite), ordenados do mais recente p/ o mais antigo.
  static Future<List<Championship>> fetchAllConcluded() async {
    await Future.delayed(const Duration(milliseconds: 250)); // TODO(back)
    final merged = <Championship>[..._userConcluded, ..._builtInConcluded()];
    merged.sort((a, b) => b.endDate.compareTo(a.endDate));
    return merged;
  }
  // ============================================================================

  /// Cria um campeonato (mock do POST) e coloca no cache local.
  static Future<Championship> createChampionship({
    required String name,
    required DateTime date,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final start = DateTime(date.year, date.month, date.day);
    final end =
        endDate == null
            ? start
            : DateTime(endDate.year, endDate.month, endDate.day);

    final created = Championship(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      startDate: start,
      endDate: end,
      userRanking: null,
      totalParticipants: null,
    );

    _userCreatedUpcoming.add(created);
    _userCreatedUpcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
    _bump(); // >>> avisa UI que houve mudança
    return created;
  }

  /// Exclui um campeonato de "Próximos" (mock).
  static Future<void> deleteUpcomingChampionship(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final before = _userCreatedUpcoming.length;
    _userCreatedUpcoming.removeWhere((c) => c.id == id);
    final removed = _userCreatedUpcoming.length < before;
    if (!removed) {
      // Não estava no cache do usuário → marcar como deletado dos mocks base
      _deletedUpcomingIds.add(id);
    }
    _bump(); // >>> avisa UI que houve mudança
  }

  /// Envia o resultado e move de "Próximos" para "Concluídos" (mock).
  static Future<void> submitChampionshipResult({
    required String championshipId,
    required int totalCompetitors,
    required int placement,
    required int feelingScore,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    Championship? found;
    bool foundInUserCreated = false;

    // 1) Procurar no cache do usuário
    try {
      found = _userCreatedUpcoming.firstWhere((c) => c.id == championshipId);
      foundInUserCreated = true;
    } catch (_) {
      // ignore
    }

    // 2) Se não achou, procurar nos mocks base (filtrando os deletados)
    if (found == null) {
      final base =
          _builtInUpcomingForCurrentMonth()
              .where((c) => !_deletedUpcomingIds.contains(c.id))
              .toList();
      try {
        found = base.firstWhere((c) => c.id == championshipId);
      } catch (_) {
        found = null;
      }
    }

    // 3) Se ainda não achou, nada a mover
    if (found == null) return;

    // 4) Remover do cache do usuário (se veio de lá)
    if (foundInUserCreated) {
      _userCreatedUpcoming.removeWhere((c) => c.id == championshipId);
    }

    // 5) Marcar como movido para não aparecer mais em "Próximos"
    _movedFromUpcomingIds.add(championshipId);

    // 6) Adicionar versão concluída no topo
    _userConcluded.insert(
      0,
      Championship(
        id: found.id,
        name: found.name,
        startDate: found.startDate,
        endDate: found.endDate,
        userRanking: placement,
        totalParticipants: totalCompetitors,
      ),
    );

    _bump(); // >>> avisa UI que houve mudança
  }

  static Future<void> schedulePushNotifications() async {
    // TODO: usar flutter_local_notifications ou outro plugin.
  }

  /// Exibe in-app dialogs 7d, 3d e no dia do evento (uma vez por dia por campeonato).
  static void showInAppNotifications(
    BuildContext context,
    List<Championship> ups,
  ) {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';

    for (var c in ups) {
      final diff =
          c.startDate.difference(DateTime(now.year, now.month, now.day)).inDays;

      if ({7, 3, 0}.contains(diff)) {
        final key = '${c.id}|$todayKey|$diff';
        if (_firedInAppKeys.contains(key)) continue; // já mostramos hoje
        _firedInAppKeys.add(key);

        final title =
            diff == 0
                ? 'Hoje é o dia de "${c.name}"!'
                : 'Faltam $diff dias para "${c.name}"';

        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            useRootNavigator: true,
            builder:
                (dialogCtx) => AppDialog(
                  icon: Icons.emoji_events,
                  title: title,
                  message: 'Não esqueça de se preparar.',
                  primaryAction: TextButton(
                    onPressed:
                        () =>
                            Navigator.of(dialogCtx, rootNavigator: true).pop(),
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
  static Future<bool> fetchChampionshipSectionEnabled() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return true; // por enquanto sempre ativo
  }
}
