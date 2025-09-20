// lib/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/features/user/athlete/athlete_all_championships_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_all_goals_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_class_details_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_classes_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_evolution_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_full_training_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_goals_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_home_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_insights_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_pr_item_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_pr_list_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_profile_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_training_screen.dart';
import 'package:flutter_app/features/user/coach/coach_home_screen.dart';
import 'package:flutter_app/features/auth/presentation/login_screen.dart';
import 'package:flutter_app/features/auth/presentation/signup_screen.dart';
import 'package:flutter_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:flutter_app/features/auth/presentation/verify_otp_screen.dart';
import 'package:flutter_app/features/auth/presentation/reset_password_screen.dart';
import 'package:flutter_app/features/auth/presentation/terms_screen.dart';
import 'package:flutter_app/features/auth/presentation/privacy_policy_screen.dart';
import 'package:flutter_app/features/splash/presentation/splash_screen.dart';
import 'package:flutter_app/features/user/coach/coach_registered_trainings_screen.dart';
import 'package:flutter_app/features/user/coach/coach_training_detail_screen.dart';
import 'package:flutter_app/features/user/coach/coach_trainings_screen.dart';

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

  // Rotas de exemplo para telas aluno
  static const String athleteHome = AthleteHomeScreen.routeName;
  static const String athleteInsight = AthleteInsightScreen.routeName;
  static const String athleteEvolution = AthleteEvolutionScreen.routeName;
  static const String athleteTraining = AthleteTrainingScreen.routeName;
  static const String athleteProfile = AthleteProfileScreen.routeName;
  static const String athleteGoals = AthleteGoalsScreen.routeName;
  static const String athleteAllGoals = AthleteAllGoalsScreen.routeName;
  static const String athletePrList = AthletePrListScreen.routeName;
  static const String athletePrItem = AthletePrItemScreen.routeName;
  static const String athleteFullTraining = FullTrainingScreen.routeName;
  static const String athleteClasses = ClassesOfDayScreen.routeName;
  static const String athleteClassesDetails = ClassDetailScreen.routeName;
  static const String athleteAllChampionships =
      AllChampionshipsScreen.routeName;

  static const String coachHome = CoachHomeScreen.routeName;
  static const String coachTrainings = CoachTrainingScreen.routeName;
  static const String coachRegisteredTrainings =
      CoachRegisteredTrainingScreen.routeName;
  static const String coachTrainingDetail = CoachTrainingDetailScreen.routeName;
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
  AppRoutes.athleteHome: (_) => const AthleteHomeScreen(),
  AppRoutes.athleteInsight: (_) => const AthleteInsightScreen(),
  AppRoutes.athleteEvolution: (_) => const AthleteEvolutionScreen(),
  AppRoutes.athleteTraining: (_) => const AthleteTrainingScreen(),
  AppRoutes.athleteProfile: (_) => const AthleteProfileScreen(),
  AppRoutes.athleteGoals: (_) => const AthleteGoalsScreen(),
  AppRoutes.athleteAllGoals: (_) => const AthleteAllGoalsScreen(),
  AppRoutes.athletePrList: (_) => const AthletePrListScreen(),
  AppRoutes.athletePrItem: (_) => const AthletePrItemScreen(),
  AppRoutes.athleteFullTraining: (_) => const FullTrainingScreen(),
  AppRoutes.athleteClasses: (_) => const ClassesOfDayScreen(),
  AppRoutes.athleteClassesDetails: (_) => const ClassDetailScreen(),
  AppRoutes.athleteAllChampionships: (_) => const AllChampionshipsScreen(),

  AppRoutes.coachHome: (_) => const CoachHomeScreen(),
  AppRoutes.coachTrainings: (_) => const CoachTrainingScreen(),
  AppRoutes.coachRegisteredTrainings:
      (_) => const CoachRegisteredTrainingScreen(),
  AppRoutes.coachTrainingDetail: (_) => const CoachTrainingDetailScreen(),
};
