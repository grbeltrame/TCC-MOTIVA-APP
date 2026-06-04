// lib/shared/screens/athlete_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/athlete_info_section.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/profile_summarry_section.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class AthleteProfileScreen extends StatefulWidget {
  static const routeName = '/athlete_profile';
  const AthleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<AthleteProfileScreen> createState() => _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends State<AthleteProfileScreen> {
  int _refreshTick = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshTick++);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),

      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: 16 * scale,
            horizontal: 8 * scale,
          ),
          child: KeyedSubtree(
            key: ValueKey('athlete_profile_$_refreshTick'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Informações sobre o perfil
                AthleteInfoSection(),

                // Informações de Resumo de Registros do Usuario
                ProfileSummarySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
