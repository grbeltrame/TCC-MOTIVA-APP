// lib/shared/screens/athlete_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/athlete_info_section.dart';
import 'package:flutter_app/shared/widgets/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/top_navbar.dart';

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
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),
      bottomNavigationBar: const BottomNavBar(),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 16 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [const AthleteInfoSection(), const SizedBox(height: 24)],
        ),
      ),
    );
  }
}
