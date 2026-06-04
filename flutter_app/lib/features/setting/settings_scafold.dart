import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_training_bottom_sheet.dart';

class SettingsScaffold extends StatelessWidget {
  final Widget child;

  const SettingsScaffold({super.key, required this.child});

  void _openRegisterTraining(BuildContext context) {
    showRegisterTrainingBottomSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterTraining(context)),
      bottomNavigationBar: const BottomNavBar(),
      body: SafeArea(child: child),
    );
  }
}

class SettingsHeader extends StatelessWidget {
  final String title;
  const SettingsHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppBackButton(),
        SizedBox(height: 12 * scale),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 16 * scale),
      ],
    );
  }
}
