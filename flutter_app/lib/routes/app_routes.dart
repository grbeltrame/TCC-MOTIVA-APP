// lib/routes/app_routes.dart

import 'package:flutter/material.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/terms_screen.dart';
import '../features/auth/presentation/privacy_policy.dart';
import '../main.dart' show MyHomePage;

/// Centralização de nomes e mapeamento de rotas da aplicação.
class AppRoutes {
  static const String splash = SplashScreen.routeName;
  static const String login = LoginScreen.routeName;
  static const String signup = SignupScreen.routeName;
  static const String forgotPassword = ForgotPasswordScreen.routeName;
  static const String terms = TermsScreen.routeName;
  static const String privacyPolicy = PrivacyPolicyScreen.routeName;
}

/// Map de rotas para passar direto ao MaterialApp(routes:)
final Map<String, WidgetBuilder> appRouteMap = {
  AppRoutes.splash: (_) => const SplashScreen(),
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.signup: (_) => const SignupScreen(),
  AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
  AppRoutes.terms: (_) => const TermsScreen(),
  AppRoutes.privacyPolicy: (_) => const PrivacyPolicyScreen(),
};
