import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/workout_result_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/athlete_result.dart';

// UI utilitários
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/back_button.dart';
import 'package:flutter_app/shared/widgets/utils/date_selector.dart';
import 'package:flutter_app/shared/widgets/utils/text_action_button.dart';
import 'package:flutter_app/shared/widgets/utils/athlete_result_list_item.dart';

// Bottom sheet mock

class AthleteResultsScreen extends StatefulWidget {
  static const routeName = '/athletes_results';
  const AthleteResultsScreen({Key? key}) : super(key: key);

  @override
  State<AthleteResultsScreen> createState() => _AthleteResultsScreenState();
}

class _AthleteResultsScreenState extends State<AthleteResultsScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _allCategories = [
    'WOD',
    'LPO',
    'Ginástica',
    'Endurance',
  ];

  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  List<ClassSlot> _classes = [];
  String? _selectedClassId; // null = todas as turmas do dia

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _allCategories.length, vsync: this);
    _reloadDayData(_selectedDate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _reloadDayData(DateTime date) async {
    final classes = await WorkoutResultService.fetchClassesForDate(date);
    if (!mounted) return;
    setState(() {
      _selectedDate = date;
      _classes = classes;
      _selectedClassId = null; // reset ao trocar a data
    });
  }

  String _formatLongDate(DateTime d) {
    final day = DateFormat('dd/MM/yyyy').format(d);
    final raw = DateFormat.EEEE('pt_BR').format(d);
    final nice = toBeginningOfSentenceCase(raw).replaceAll('-feira', ' Feira');
    return '$nice dia $day';
  }

  // Navegações / ações
  void _onDateChanged(DateTime d) => _reloadDayData(d);

  void _onClassChanged(String? classId) {
    setState(() => _selectedClassId = classId);
  }

  void _openAlerts() {
    Navigator.of(context).pushNamed(AppRoutes.athleteAlerts);
  }

  void _openAthleteProfile(AthleteResult r) {
    Navigator.of(context).pushNamed(
      AppRoutes.athleteProfileDetail,
      arguments: {'athleteId': r.athleteId, 'athleteName': r.athleteName},
    );
  }

  /// Tipos de treino que EXISTIRAM no dia (derivado das turmas do dia).
  Set<String> get _dayTypes => _classes.map((c) => c.type).toSet();

  Future<List<AthleteResult>> _fetchResultsForTab(String tabCategory) {
    // Turma selecionada → resultados só daquela turma (se tipo bater).
    // Sem turma selecionada → resultados do dia para aquela categoria.
    return WorkoutResultService.fetchAthleteResults(
      date: _selectedDate,
      classId: _selectedClassId,
      category: tabCategory,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),

      bottomNavigationBar: const BottomNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // back
          Padding(
            padding: EdgeInsets.only(
              top: 8 * scale,
              left: 6 * scale,
              right: 6 * scale,
            ),
            child: const AppBackButton(),
          ),

          // ===== CABEÇALHO FIXO =====
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 10 * scale,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // (1) Título
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Text(
                    'Você está vendo registros do dia:',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                SizedBox(height: 8 * scale),

                // (2) DateSelector
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: DateSelector(
                    initialDate: _selectedDate,
                    onDateChanged: _onDateChanged,
                  ),
                ),

                SizedBox(height: 12 * scale),

                // (3) Linha com seletor de turma + botão "Alertas sobre Alunos"
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: Row(
                    children: [
                      Text(
                        'Turma:',
                        style: TextStyle(
                          fontWeight: AppFontWeight.bold,
                          fontSize: 14 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                      SizedBox(width: 8 * scale),
                      Expanded(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _selectedClassId,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Todas as turmas do dia'),
                            ),
                            ..._classes.map((c) {
                              final h = c.startAt.hour.toString().padLeft(
                                2,
                                '0',
                              );
                              final m = c.startAt.minute.toString().padLeft(
                                2,
                                '0',
                              );
                              return DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text('$h:$m - ${c.type}'),
                              );
                            }).toList(),
                          ],
                          onChanged: _onClassChanged,
                        ),
                      ),
                      // Botão vermelho + fonte menor (usa props do TextActionButton)
                      TextActionButton(
                        icon: Icons.add,
                        text: 'Alertas sobre Alunos',
                        color: AppColors.baseMagenta,
                        fontSize: 12, // menor
                        onPressed: _openAlerts,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12 * scale),

                // (4) TabBar – ajustada (respiro e alinhamento)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    // Se sua versão do Flutter não tiver TabAlignment, remova a linha abaixo:
                    tabAlignment: TabAlignment.center,
                    labelPadding: EdgeInsets.symmetric(horizontal: 16 * scale),
                    labelColor: AppColors.baseBlue,
                    unselectedLabelColor: AppColors.mediumGray,
                    indicatorColor: AppColors.baseBlue,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: _allCategories.map((c) => Tab(text: c)).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ===== CONTEÚDO SCROLLÁVEL POR ABA =====
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12 * scale),
              child: TabBarView(
                controller: _tabController,
                children:
                    _allCategories.map((cat) {
                      return FutureBuilder<List<AthleteResult>>(
                        future: _fetchResultsForTab(cat),
                        builder: (ctx, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          final list = snap.data ?? [];

                          // Regras de vazio:
                          final hasClassOfCat = _dayTypes.contains(cat);

                          if (_selectedClassId == null) {
                            if (!hasClassOfCat) {
                              return _EmptyMessage(
                                text:
                                    'Sem aula de $cat na data ${_formatLongDate(_selectedDate)}',
                              );
                            }
                            if (list.isEmpty) {
                              return _EmptyMessage(
                                text:
                                    'Nenhum aluno registrou resultado para $cat em ${_formatLongDate(_selectedDate)}',
                              );
                            }
                          } else {
                            final slot = _classes.firstWhere(
                              (c) => c.id == _selectedClassId,
                            );
                            final h = slot.startAt.hour.toString().padLeft(
                              2,
                              '0',
                            );
                            final m = slot.startAt.minute.toString().padLeft(
                              2,
                              '0',
                            );
                            final hm = '$h:$m';

                            if (slot.type != cat) {
                              return _EmptyMessage(
                                text:
                                    'Não teve treino do tipo $cat no dia ${_formatLongDate(_selectedDate)}, às $hm',
                              );
                            }
                            if (list.isEmpty) {
                              return _EmptyMessage(
                                text:
                                    'Nenhum aluno registrou resultado para $cat no dia ${_formatLongDate(_selectedDate)}, às $hm',
                              );
                            }
                          }

                          // Lista de resultados (agora rola normalmente)
                          return ListView.builder(
                            padding: EdgeInsets.only(
                              top: 8 * scale,
                              bottom: 16 * scale,
                            ),
                            physics: const ClampingScrollPhysics(),
                            itemCount: list.length,
                            itemBuilder: (ctx, i) {
                              final r = list[i];
                              return AthleteResultListItem(
                                result: r,
                                onTapMore: () => _openAthleteProfile(r),
                              );
                            },
                          );
                        },
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  const _EmptyMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
