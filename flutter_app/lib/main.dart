// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'package:flutter_app/core/services/championship_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
    );
  }
}
