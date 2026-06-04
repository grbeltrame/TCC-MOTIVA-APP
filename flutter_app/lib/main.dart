// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // <--- 1. ADICIONADO: Pacote Provider

// Imports do seu projeto
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'core/services/championship_service.dart';

// <--- 2. ADICIONADO: Import do seu UserProvider
// (Confirme se o caminho está correto conforme onde você criou o arquivo)
import 'features/auth/presentation/providers/user_provider.dart';

Future<void> main() async {
  // 1) prepara o Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // <--- CORREÇÃO DE ORDEM: O Firebase deve iniciar ANTES de tudo
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) carrega locale pt_BR
  await initializeDateFormatting('pt_BR', null);

  // 3) verifica se a seção de Campeonatos está ativa
  // (Agora é seguro chamar isso pois o Firebase já iniciou)
  final enabled = await ChampionshipService.fetchChampionshipSectionEnabled();

  // 4) só agenda se usuário tiver habilitado Campeonatos
  if (enabled) {
    ChampionshipService.schedulePushNotifications();
  }

  // 5) inicia o app COM O PROVIDER
  runApp(
    MultiProvider(
      providers: [
        // Aqui nós injetamos o UserProvider na raiz do app
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
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

      // --- ESPIÃO DE ROTAS ---
      navigatorObservers: [SimpleRouteObserver()],
    );
  }
}

// --- CLASSE DO ESPIÃO DE ROTAS ---
class SimpleRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      print('>>> [NAVEGAÇÃO] Abrindo tela: ${route.settings.name}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      print('<<< [NAVEGAÇÃO] Voltando para: ${previousRoute!.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      print('>>> [NAVEGAÇÃO] Substituindo por: ${newRoute!.settings.name}');
    }
  }
}
