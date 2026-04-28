// lib/routes/app_routes.dart
import 'package:flutter/material.dart';

import 'package:flutter_app/features/auth/presentation/select_profile_screen.dart';
import 'package:flutter_app/features/setting/admin_manage_box_screen.dart';
import 'package:flutter_app/features/setting/setting_app_permissions_screen.dart';
import 'package:flutter_app/features/setting/settings_bug_report_screen.dart';
import 'package:flutter_app/features/setting/settings_data_download_screen.dart';
import 'package:flutter_app/features/setting/settings_data_sharing_screen.dart';
import 'package:flutter_app/features/setting/settings_deactivate_account_screen.dart';
import 'package:flutter_app/features/setting/settings_delete_account_screen.dart';
import 'package:flutter_app/features/setting/settings_feedback_screen.dart';
import 'package:flutter_app/features/setting/settings_reset_password_screen.dart';
import 'package:flutter_app/features/setting/settings_supporte_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_all_championships_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_all_goals_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_class_details_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_classes_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_edit_profile_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_evolution_insights_detail_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_evolution_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_pre_workout_insights_detail_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_weekly_insights_detail_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_full_training_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_general_settings_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_goals_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_home_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_insights_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_pr_item_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_pr_list_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_profile_screen.dart';
import 'package:flutter_app/features/user/athlete/athlete_training_screen.dart';

import 'package:flutter_app/features/user/coach/athlete_alerts_screen.dart';
import 'package:flutter_app/features/user/coach/athlete_profile_detail_screen.dart';
import 'package:flutter_app/features/user/coach/athlete_results_screen.dart';
import 'package:flutter_app/features/user/coach/coach_all_cycles_page.dart';
import 'package:flutter_app/features/user/coach/coach_cycle_insight_topic_detail_screen.dart';
import 'package:flutter_app/features/user/coach/coach_cycle_training_type_detail_screen.dart';
import 'package:flutter_app/features/user/coach/coach_cycles_detail_sceen.dart';
import 'package:flutter_app/features/user/coach/coach_general_setting_screen.dart';
import 'package:flutter_app/features/user/coach/coach_home_screen.dart';

import 'package:flutter_app/features/auth/presentation/login_screen.dart';
import 'package:flutter_app/features/auth/presentation/signup_screen.dart';
import 'package:flutter_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:flutter_app/features/auth/presentation/verify_otp_screen.dart';
import 'package:flutter_app/features/auth/presentation/reset_password_screen.dart';
import 'package:flutter_app/features/auth/presentation/terms_screen.dart';
import 'package:flutter_app/features/auth/presentation/privacy_policy_screen.dart';

import 'package:flutter_app/features/splash/presentation/splash_screen.dart';

import 'package:flutter_app/features/user/coach/coach_profile_screen.dart';
import 'package:flutter_app/features/user/coach/coach_registered_trainings_screen.dart';
import 'package:flutter_app/features/user/coach/coach_training_detail_screen.dart';
import 'package:flutter_app/features/user/coach/coach_trainings_screen.dart';
import 'package:flutter_app/features/user/coach/coach_evolutions_screen.dart';
import 'package:flutter_app/features/user/coach/coach_insights_screen.dart';
import 'package:flutter_app/features/user/coach/coach_training_insights_screen.dart';
import 'package:flutter_app/features/user/coach/edit_profile_coach_screen.dart';
import 'package:flutter_app/features/user/coach/interested_athletes_per_class.dart';
import 'package:flutter_app/features/user/coach/coach_training_edit_screen.dart';

/// Centralização de nomes e mapeamento de rotas da aplicação.
class AppRoutes {
  // Auth / Splash
  static const String splash = SplashScreen.routeName; // '/'
  static const String login = LoginScreen.routeName; // '/login'
  static const String signup = SignupScreen.routeName; // '/signup'
  static const String selectProfile = SelectProfileScreen.routeName;
  static const String forgotPassword = ForgotPasswordScreen.routeName;
  static const String verifyOtp = VerifyOtpScreen.routeName;
  static const String resetPassword = ResetPasswordScreen.routeName;
  static const String terms = TermsScreen.routeName;
  static const String privacyPolicy = PrivacyPolicyScreen.routeName;

  // Athlete
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
  static const String athleteProfileEdit = EditProfileAthleteScreen.routeName;
  static const String athleteSettings = AthleteGeneralSettingsScreen.routeName;
  static const String athleteWeeklyInsightsDetail =
      AthleteWeeklyInsightsDetailScreen.routeName;
  static const String athleteEvolutionInsightsDetail =
      AthleteEvolutionInsightsDetailScreen.routeName;
  static const String athletePreWorkoutInsightsDetail =
      AthletePreWorkoutInsightsDetailScreen.routeName;

  // Coach
  static const String coachHome = CoachHomeScreen.routeName;
  static const String coachTrainings = CoachTrainingScreen.routeName;
  static const String coachRegisteredTrainings =
      CoachRegisteredTrainingScreen.routeName;
  static const String coachTrainingDetail = CoachTrainingDetailScreen.routeName;

  static const String athletesResults = AthleteResultsScreen.routeName;
  static const String athleteAlerts = AthleteAlertsScreen.routeName;
  static const String athleteProfileDetail =
      AthleteProfileDetailScreen.routeName;

  static const String coachEvolutions = CoachEvolutionsScreen.routeName;
  static const String coachInsights = CoachInsightsScreen.routeName;
  static const String coachTrainingInsights =
      CoachTrainingInsightsScreen.routeName;
  static const String interestedAtlhetes = InterestedAthletesScreen.routeName;

  static const String coachProfile = CoachProfileScreen.routeName;
  static const String coachTrainingEdit = CoachTrainingEditScreen.routeName;
  static const String coachProfileEdit = EditProfileCoachScreen.routeName;

  static const String coachAllCycles = CoachAllCyclesScreen.routeName;
  static const String coachCycleDetail = CoachCycleDetailScreen.routeName;
  static const String coachCycleTrainingTypeDetail =
      CoachCycleTrainingTypeDetailScreen.routeName;
  static const String coachCycleInsightTopicDetail =
      CoachCycleInsightTopicDetailScreen.routeName;

  static const String coachSettings = CoachGeneralSettingsScreen.routeName;

  // =========================
  // ✅ SETTINGS (TELAS REAIS)
  // =========================

  // Privacidade e Segurança
  static const String settingsDataSharing = SettingsDataSharingScreen.routeName;
  static const String settingsDataDownload =
      SettingsDataDownloadScreen.routeName;
  static const String settingsAppPermissions =
      SettingsAppPermissionsScreen.routeName;

  // Conta
  static const String settingsResetPassword =
      SettingsResetPasswordScreen.routeName;
  static const String settingsDeactivateAccount =
      SettingsDeactivateAccountScreen.routeName;
  static const String settingsDeleteAccount =
      SettingsDeleteAccountScreen.routeName;

  // Suporte e Feedback
  static const String settingsSupport = SettingsSupportScreen.routeName;
  static const String settingsFeedback = SettingsFeedbackScreen.routeName;
  static const String settingsBugReport = SettingsBugReportScreen.routeName;

  // Admin (futuro)
  static const String adminManageBox = AdminManageBoxScreen.routeName;
}

/// Mapeamento de rotas
final Map<String, WidgetBuilder> appRouteMap = {
  // Splash / Auth
  AppRoutes.splash: (_) => const SplashScreen(),
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.signup: (_) => const SignupScreen(),
  AppRoutes.selectProfile: (_) => const SelectProfileScreen(),
  AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
  AppRoutes.verifyOtp: (_) => const VerifyOtpScreen(email: ''),
  AppRoutes.resetPassword: (_) => const ResetPasswordScreen(email: ''),
  AppRoutes.terms: (_) => const TermsScreen(),
  AppRoutes.privacyPolicy: (_) => const PrivacyPolicyScreen(),

  // Athlete
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
  AppRoutes.athleteProfileEdit: (ctx) {
    final settings = ModalRoute.of(ctx)!.settings;
    return EditProfileAthleteScreen.fromArgs(settings);
  },
  AppRoutes.athleteSettings: (_) => const AthleteGeneralSettingsScreen(),
  AppRoutes.athleteWeeklyInsightsDetail:
      (_) => const AthleteWeeklyInsightsDetailScreen(),
  AppRoutes.athleteEvolutionInsightsDetail:
      (_) => const AthleteEvolutionInsightsDetailScreen(),
  AppRoutes.athletePreWorkoutInsightsDetail:
      (_) => const AthletePreWorkoutInsightsDetailScreen(),

  // Coach
  AppRoutes.coachHome: (_) => const CoachHomeScreen(),
  AppRoutes.coachTrainings: (_) => const CoachTrainingScreen(),
  AppRoutes.coachRegisteredTrainings:
      (_) => const CoachRegisteredTrainingScreen(),
  AppRoutes.coachTrainingDetail: (_) => const CoachTrainingDetailScreen(),
  AppRoutes.athletesResults: (_) => const AthleteResultsScreen(),
  AppRoutes.athleteAlerts: (_) => const AthleteAlertsScreen(),
  AppRoutes.athleteProfileDetail: (_) => const AthleteProfileDetailScreen(),
  AppRoutes.coachEvolutions: (_) => const CoachEvolutionsScreen(),
  AppRoutes.coachInsights: (_) => const CoachInsightsScreen(),
  AppRoutes.coachTrainingInsights: (_) => const CoachTrainingInsightsScreen(),
  AppRoutes.interestedAtlhetes: (_) => const InterestedAthletesScreen(),
  AppRoutes.coachProfile: (_) => const CoachProfileScreen(),
  AppRoutes.coachTrainingEdit: (ctx) {
    final settings = ModalRoute.of(ctx)!.settings;
    return CoachTrainingEditScreen.fromArgs(settings);
  },
  AppRoutes.coachProfileEdit: (_) => const EditProfileCoachScreen(),
  AppRoutes.coachAllCycles: (_) => const CoachAllCyclesScreen(),
  AppRoutes.coachCycleDetail: (_) => const CoachCycleDetailScreen(),
  AppRoutes.coachCycleTrainingTypeDetail:
      (_) => const CoachCycleTrainingTypeDetailScreen(),
  AppRoutes.coachCycleInsightTopicDetail:
      (_) => const CoachCycleInsightTopicDetailScreen(),
  AppRoutes.coachSettings: (_) => const CoachGeneralSettingsScreen(),

  // =========================
  // ✅ SETTINGS (TELAS REAIS)
  // =========================
  AppRoutes.settingsDataSharing: (_) => const SettingsDataSharingScreen(),
  AppRoutes.settingsDataDownload: (_) => const SettingsDataDownloadScreen(),
  AppRoutes.settingsAppPermissions: (_) => const SettingsAppPermissionsScreen(),

  AppRoutes.settingsResetPassword: (_) => const SettingsResetPasswordScreen(),
  AppRoutes.settingsDeactivateAccount:
      (_) => const SettingsDeactivateAccountScreen(),
  AppRoutes.settingsDeleteAccount: (_) => const SettingsDeleteAccountScreen(),

  AppRoutes.settingsSupport: (_) => const SettingsSupportScreen(),
  AppRoutes.settingsFeedback: (_) => const SettingsFeedbackScreen(),
  AppRoutes.settingsBugReport: (_) => const SettingsBugReportScreen(),

  AppRoutes.adminManageBox: (_) => const AdminManageBoxScreen(),
};
