// lib/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart' show MyHomePage;
import 'package:flutter_app/features/auth/presentation/login_screen.dart';
import 'package:flutter_app/features/auth/presentation/signup_screen.dart';
import 'package:flutter_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:flutter_app/features/auth/presentation/verify_otp_screen.dart';
import 'package:flutter_app/features/auth/presentation/reset_password_screen.dart';
import 'package:flutter_app/features/auth/presentation/terms_screen.dart';
import 'package:flutter_app/features/auth/presentation/privacy_policy_screen.dart';
import 'package:flutter_app/features/splash/presentation/splash_screen.dart';

/// Centralização de nomes e mapeamento de rotas da aplicação.
class AppRoutes {
  static const String splash = SplashScreen.routeName; // '/'
  static const String login = LoginScreen.routeName; // '/login'
  static const String signup = SignupScreen.routeName; // '/signup'
  static const String forgotPassword =
      ForgotPasswordScreen.routeName; // '/forgot_password'
  static const String verifyOtp = VerifyOtpScreen.routeName; // '/verify_otp'
  static const String resetPassword =
      ResetPasswordScreen.routeName; // '/reset_password'
  static const String terms = TermsScreen.routeName; // '/terms'
  static const String privacyPolicy =
      PrivacyPolicyScreen.routeName; // '/privacy_policy'
}

/// Mapeamento de rotas para usar no MaterialApp(routes:)
final Map<String, WidgetBuilder> appRouteMap = {
  AppRoutes.splash: (_) => const SplashScreen(),
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.signup: (_) => const SignupScreen(),
  AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
  AppRoutes.verifyOtp: (_) => const VerifyOtpScreen(email: ''),
  AppRoutes.resetPassword: (_) => const ResetPasswordScreen(email: ''),
  AppRoutes.terms: (_) => const TermsScreen(),
  AppRoutes.privacyPolicy: (_) => const PrivacyPolicyScreen(),
};
