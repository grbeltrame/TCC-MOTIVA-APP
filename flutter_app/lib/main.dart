import 'package:flutter/material.dart';
//importe o helper de locale
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';

Future<void> main() async {
  // garante que tudo do Flutter esteja pronto
  WidgetsFlutterBinding.ensureInitialized();
  // carrega as regras de formatação para pt_BR
  await initializeDateFormatting('pt_BR', null);
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
      initialRoute: AppRoutes.splash,
      routes: appRouteMap,
    );
  }
}
