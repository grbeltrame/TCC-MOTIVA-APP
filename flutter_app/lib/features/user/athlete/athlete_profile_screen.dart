// lib/shared/screens/athlete_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/achievements_badges_section.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/athlete_info_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/profile_nav_hub_section.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/profile_summarry_section.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class AthleteProfileScreen extends StatefulWidget {
  static const routeName = '/athlete_profile';
  const AthleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<AthleteProfileScreen> createState() => _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends State<AthleteProfileScreen> {
  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 16 * scale,
          horizontal: 8 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informações sobre o perfil
            AthleteInfoSection(),

            // Informações de Resumo de Registros do Usuario
            ProfileSummarySection(),

            // Hub de navegação
            ProfileNavHubSection(),

            // Metas concluidas
            AchievementsBadgesSection(),
          ],
        ),
      ),
    );
  }
}
