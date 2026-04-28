// lib/shared/widgets/highlights_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/alerts_service.dart';
import 'package:flutter_app/shared/widgets/carousels/alerts_carousel.dart';

/// Seção completa de Destaques Inteligentes:
/// – inclui título, carousel e espaçamento final
/// – só aparece se houver highlights habilitados
class AlertsSection extends StatelessWidget {
  const AlertsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // 1) Busca todos os highlights
    return FutureBuilder<List<AlertModel>>(
      future: AlertsService().fetchAlerts(),
      builder: (ctx, snapAlerts) {
        // enquanto carrega, mostra o loader existente
        if (snapAlerts.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapAlerts.data!;

        // 2) Busca o conjunto de tipos habilitados
        return FutureBuilder<Set<String>>(
          future: AlertsService().fetchEnabledTypes(),
          builder: (ctx2, snapEnabled) {
            if (snapEnabled.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final enabled = snapEnabled.data!;

            // 3) Filtra apenas o que o usuário habilitou
            final filtered =
                all.where((h) => enabled.contains(h.type)).toList();

            // se não houver nenhum, não renderiza título, carousel nem espaçamento
            if (filtered.isEmpty) {
              return const SizedBox.shrink();
            }

            // 4) Renderiza título, carousel e espaçamento de 32*scale
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Text(
                    'Alertas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 8 * scale),
                AlertsCarousel(allAlerts: filtered, enabledTypes: enabled),
                SizedBox(height: 32 * scale),
              ],
            );
          },
        );
      },
    );
  }
}
