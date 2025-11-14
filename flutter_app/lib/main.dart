// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'package:flutter_app/core/services/championship_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // 1) prepara o Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // 2) carrega locale pt_BR
  await initializeDateFormatting('pt_BR', null);

  // 3) verifica se a seção de Campeonatos está ativa
  final enabled = await ChampionshipService.fetchChampionshipSectionEnabled();

  // 4) só agenda se usuário tiver habilitado Campeonatos
  if (enabled) {
    ChampionshipService.schedulePushNotifications();
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 5) inicia o app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Motiva',
      theme: AppTheme.lightTheme,

      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      initialRoute: AppRoutes.splash,
      routes: appRouteMap,

      // --- ADIÇÃO DO ESPIÃO DE ROTAS ---
      // Esta linha registra o SimpleRouteObserver para monitorar a navegação.
      navigatorObservers: [SimpleRouteObserver()],
      // --- FIM DA ADIÇÃO ---
    );
  }
}

// --- CLASSE DO ESPIÃO DE ROTAS ADICIONADA ---

/// Observador de navegação (espião) que imprime as rotas no console
/// para fins de depuração (debug).
class SimpleRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      // Imprime no console quando você abre uma nova tela
      print('>>> [NAVEGAÇÃO] Abrindo tela: ${route.settings.name}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    // Verifica se a rota anterior tem um nome para evitar prints desnecessários
    if (previousRoute?.settings.name != null) {
      // Imprime no console quando você volta
      print('<<< [NAVEGAÇÃO] Voltando para: ${previousRoute!.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      // Imprime no console quando você substitui uma tela
      print('>>> [NAVEGAÇÃO] Substituindo por: ${newRoute!.settings.name}');
    }
  }
}
