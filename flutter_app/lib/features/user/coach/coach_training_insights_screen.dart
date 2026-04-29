import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_cycle_insights_section.dart';

class CoachTrainingInsightsScreen extends StatefulWidget {
  static const routeName = '/coach_training_insights';
  const CoachTrainingInsightsScreen({super.key});

  @override
  State<CoachTrainingInsightsScreen> createState() =>
      _CoachTrainingInsightsScreenState();
}

class _CoachTrainingInsightsScreenState
    extends State<CoachTrainingInsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // Leitura opcional de argumentos (para no futuro já vir com mês específico).
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final monthArg = args?['month'];
    final DateTime? monthFromArg =
        monthArg is DateTime ? _validMonth(monthArg) : null;
    final DateTime? initialMonth =
        monthFromArg ?? _monthFromKey(args?['monthKey']);
    final String boxId = (args?['boxId'] as String?) ?? '1';

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: 8 * scale,
          horizontal: 12 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Topo: voltar + Ver todos os ciclos ───────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppBackButton(),
                GestureDetector(
                  onTap:
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.coachAllCycles,
                      ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver todos os ciclos',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 11 * scale,
                          color: AppColors.baseBlue,
                          fontWeight: AppFontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 3 * scale),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 10 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12 * scale),

            CoachCycleInsightsSection(boxId: boxId, initialMonth: initialMonth),

            SizedBox(height: 16 * scale),
          ],
        ),
      ),
    );
  }

  DateTime? _monthFromKey(dynamic monthKey) {
    if (monthKey is! String || monthKey.trim().isEmpty) return null;
    final parts = monthKey.trim().split(RegExp(r'[-/]'));
    if (parts.length < 2) return null;

    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    if (first == null || second == null) return null;

    if (_isSupportedYear(first) && _isValidMonth(second)) {
      return DateTime(first, second);
    }

    if (_isValidMonth(first) && _isSupportedYear(second)) {
      return DateTime(second, first);
    }

    return null;
  }

  DateTime? _validMonth(DateTime date) {
    final normalized = DateTime(date.year, date.month);
    if (!_isSupportedYear(normalized.year)) return null;
    return normalized;
  }

  bool _isValidMonth(int month) => month >= 1 && month <= 12;

  bool _isSupportedYear(int year) {
    final now = DateTime.now();
    return year >= 2020 && year <= now.year + 2;
  }
}
