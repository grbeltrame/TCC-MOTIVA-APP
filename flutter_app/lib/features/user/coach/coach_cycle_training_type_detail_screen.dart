import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/sections/athlete/worked_muscles_section.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/cycle_service.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/training_block.dart';

import 'package:flutter_app/shared/widgets/utils/date_selector.dart';

// ✅ bottom sheet correto
import 'package:flutter_app/shared/widgets/bottom_sheets/register_training_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/training_edit_delete_buttons.dart';

class CoachCycleTrainingTypeDetailScreen extends StatefulWidget {
  static const routeName = '/coach_cycle_training_type_detail';
  const CoachCycleTrainingTypeDetailScreen({Key? key}) : super(key: key);

  @override
  State<CoachCycleTrainingTypeDetailScreen> createState() =>
      _CoachCycleTrainingTypeDetailScreenState();
}

class _CoachCycleTrainingTypeDetailScreenState
    extends State<CoachCycleTrainingTypeDetailScreen> {
  static const String _boxId = '1';

  bool _didInit = false;

  late int _year;
  late int _month;
  late String _typeKey;
  late String _typeLabel;

  late String _category;
  late DateTime _selectedDate;

  bool _cycleExists = true;

  Future<Map<String, TrainingBlock?>>? _futBlocks;

  // delete local (mock)
  final Set<String> _locallyDeletedBlockIds = {};

  void _openRegisterBoxSheet() {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  void _openRegisterTraining(BuildContext context) {
    showRegisterTrainingBottomSheet(context);
  }

  String _mapTypeKeyToCategory(String typeKey, String typeLabel) {
    final k = typeKey.toLowerCase().trim();
    final l = typeLabel.toLowerCase().trim();

    if (k.contains('wod') || l.contains('wod')) return 'WOD';
    if (k.contains('lpo') || l.contains('lpo')) return 'LPO';
    if (k.contains('endurance') || l.contains('endurance')) return 'Endurance';
    if (k.contains('gin') || l.contains('gin')) return 'Ginastica';

    final cleaned = typeLabel.trim();
    if (cleaned.isEmpty) return 'WOD';
    if (cleaned.toLowerCase() == 'wods') return 'WOD';
    return cleaned;
  }

  String _titleTypeLabel() {
    final t = _typeLabel.trim();
    if (t.toLowerCase() == 'wods') return 'WOD';
    return t;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? {};

    _year = (args['year'] ?? DateTime.now().year) as int;
    _month = (args['month'] ?? DateTime.now().month) as int;
    _typeKey = (args['typeKey'] ?? 'wod') as String;
    _typeLabel = (args['typeLabel'] ?? 'Treinos') as String;

    _category = _mapTypeKeyToCategory(_typeKey, _typeLabel);

    final now = DateTime.now();
    _selectedDate =
        (now.year == _year && now.month == _month)
            ? DateTime(now.year, now.month, now.day)
            : DateTime(_year, _month, 1);

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _checkCycleExists();
    _reloadBlocks();
  }

  Future<void> _checkCycleExists() async {
    final exists = await CycleAll.isCycleRegistered(
      boxId: _boxId,
      year: _year,
      month: _month,
    );

    if (!mounted) return;
    setState(() => _cycleExists = exists);
  }

  void _reloadBlocks() {
    _futBlocks = TrainingService.fetchTrainingBlocksByCategoryForDate(
      boxId: _boxId,
      date: _selectedDate,
    );
    setState(() {});
  }

  void _handleDateChanged(DateTime d) {
    setState(() => _selectedDate = d);
    _reloadBlocks();
  }

  Future<void> _handleMonthChanged(int year, int month) async {
    _year = year;
    _month = month;

    _selectedDate = DateTime(year, month, _selectedDate.day);

    await _checkCycleExists();
    _reloadBlocks();
  }

  void _openCoachTrainingDetail(TrainingBlock block) {
    Navigator.of(context).pushNamed(
      AppRoutes.coachTrainingDetail,
      arguments: {
        'boxId': _boxId,
        'date': _selectedDate,
        'category': _category,
        'blockId': block.id,
        'expectedTitle': block.title,
      },
    );
  }

  void _onTapComentariosDoCriador() {
    /* TODO */
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    final monthTitle = CycleService.monthTitlePtBR(_month);
    final headerTitle = 'Mensal - $monthTitle - ${_titleTypeLabel()}';

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scale,
          vertical: 8 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppBackButton(),
            SizedBox(height: 12 * scale),

            Text(
              'Esses são os treinos do seu ciclo.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 6 * scale),
            Text(
              headerTitle,
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            ),

            SizedBox(height: 16 * scale),

            CycleAwareDateSelector(
              initialDate: _selectedDate,
              onDateChanged: _handleDateChanged,
              onMonthChanged: (y, m) => _handleMonthChanged(y, m),
            ),

            SizedBox(height: 14 * scale),

            if (!_cycleExists) ...[
              Text(
                'O Ciclo $monthTitle/$_year não existe ainda',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 13 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
              SizedBox(height: 8 * scale),
              TextButton(
                onPressed: () => _openRegisterTraining(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Registrar treino',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontWeight: AppFontWeight.bold,
                    color: AppColors.baseBlue,
                    fontSize: 13 * scale,
                  ),
                ),
              ),
            ] else ...[
              FutureBuilder<Map<String, TrainingBlock?>>(
                future: _futBlocks,
                builder: (ctx, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return SizedBox(
                      height: 160 * scale,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  final map = snap.data ?? {};
                  final rawBlock = map[_category];

                  final shouldHide =
                      rawBlock != null &&
                      _locallyDeletedBlockIds.contains(rawBlock.id);

                  final TrainingBlock? block = shouldHide ? null : rawBlock;

                  // ===== CARD =====
                  Widget card;
                  if (block == null) {
                    card = Container(
                      margin: EdgeInsets.symmetric(horizontal: 4 * scale),
                      padding: EdgeInsets.all(12 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10 * scale),
                        border: Border.all(color: AppColors.mediumGray),
                      ),
                      child: Text(
                        'Não existe um treino desse tipo nesse dia.',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 12 * scale,
                          color: AppColors.mediumGray,
                        ),
                      ),
                    );
                  } else {
                    card = Container(
                      margin: EdgeInsets.symmetric(horizontal: 4 * scale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10 * scale),
                        border: Border.all(color: AppColors.mediumGray),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              12 * scale,
                              12 * scale,
                              12 * scale,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  block.title,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontWeight: AppFontWeight.bold,
                                    fontSize: 16 * scale,
                                    color: AppColors.darkText,
                                  ),
                                ),
                                SizedBox(height: 4 * scale),
                                Text(
                                  block.subtitle,
                                  style: TextStyle(
                                    fontFamily: AppFonts.roboto,
                                    fontSize: 12 * scale,
                                    color: AppColors.mediumGray,
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                                ...block.items.map(
                                  (line) => Padding(
                                    padding: EdgeInsets.only(bottom: 4 * scale),
                                    child: Text(
                                      line,
                                      style: TextStyle(
                                        fontFamily: AppFonts.roboto,
                                        fontSize: 12 * scale,
                                        color: AppColors.mediumGray,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8 * scale),
                              ],
                            ),
                          ),

                          Container(height: 1, color: AppColors.lightGray),

                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 6 * scale,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: _onTapComentariosDoCriador,
                                  icon: Icon(
                                    Icons.comment_outlined,
                                    size: 14 * scale,
                                    color: AppColors.baseBlue,
                                  ),
                                  label: Text(
                                    'Comentários do criador',
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
                                      fontWeight: AppFontWeight.bold,
                                      fontSize: 11 * scale,
                                      color: AppColors.baseBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            height: 1,
                            color: AppColors.lightGray.withOpacity(0.6),
                          ),

                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8 * scale,
                              vertical: 6 * scale,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed:
                                      () => _openCoachTrainingDetail(block),
                                  icon: Icon(
                                    Icons.visibility_outlined,
                                    size: 16 * scale,
                                    color: AppColors.baseBlue,
                                  ),
                                  label: Text(
                                    'Ver treino completo',
                                    style: TextStyle(
                                      fontFamily: AppFonts.roboto,
                                      fontWeight: AppFontWeight.bold,
                                      fontSize: 13 * scale,
                                      color: AppColors.baseBlue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      card,
                      SizedBox(height: 12 * scale),

                      // ✅ agora os botões recebem o MESMO block do card
                      TrainingEditDeleteButtons(
                        boxId: _boxId,
                        date: _selectedDate,
                        category: _category,
                        currentBlock: block,
                        onDeleted: () {
                          if (block != null) {
                            _locallyDeletedBlockIds.add(block.id);
                          }
                          setState(() {}); // força sumir card + muscles
                        },
                        onEdited: () {
                          _reloadBlocks();
                        },
                      ),

                      SizedBox(height: 18 * scale),

                      // ✅ muscles também depende do MESMO block
                      if (block != null) WorkedMusclesSection(lastBlock: block),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
