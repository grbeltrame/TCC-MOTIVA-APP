import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

class CoachRegisteredTrainingScreen extends StatefulWidget {
  static const routeName = '/coach_registered_training';
  const CoachRegisteredTrainingScreen({Key? key}) : super(key: key);

  @override
  State<CoachRegisteredTrainingScreen> createState() =>
      _CoachRegisteredTrainingScreenState();
}

class _CoachRegisteredTrainingScreenState
    extends State<CoachRegisteredTrainingScreen> {
  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const Placeholder());
    // TODO: trocar Placeholder pelo bottom sheet real quando existir
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: TopNavbar(onRegisterBox: () => _openRegisterBoxSheet(context)),
      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 8 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [AppBackButton()],
        ),
      ),
    );
  }
}
