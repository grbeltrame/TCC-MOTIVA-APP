// lib/features/coach_home/presentation/coach_home_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/shared/widgets/cards/coach_today_workout_card.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';

// =============================================================================
// MODELO INTERNO — agrega todos os dados da home
// =============================================================================

class _HomeData {
  final List<Training> trainings; // treinos do dia (com analysis da IA)
  final Map<String, dynamic>? cycle; // documento do ciclo mensal

  const _HomeData({required this.trainings, this.cycle});

  bool get hasTraining => trainings.isNotEmpty;

  // Junta os key_metrics de todos os treinos do dia, deduplica
  List<String> get allKeyMetrics {
    final seen = <String>{};
    final out = <String>[];
    for (final t in trainings) {
      for (final m in t.analysis?.keyMetrics ?? []) {
        final key = m.trim().toLowerCase();
        if (seen.add(key)) out.add(m.trim());
      }
    }
    return out;
  }

  // Junta todos os alertas da IA dos treinos do dia
  Map<String, String> get allAlerts {
    final out = <String, String>{};
    for (final t in trainings) {
      out.addAll(t.analysis?.alerts ?? {});
    }
    return out;
  }
}

// =============================================================================
// TELA PRINCIPAL
// =============================================================================

class CoachHomeScreen extends StatefulWidget {
  static const routeName = '/coach_home';
  const CoachHomeScreen({Key? key}) : super(key: key);

  @override
  State<CoachHomeScreen> createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  late Future<_HomeData> _futureData;
  final String _boxId = 'BOX_PRINCIPAL';

  @override
  void initState() {
    super.initState();
    _futureData = _loadHomeData();
  }

  Future<_HomeData> _loadHomeData() async {
    final now = DateTime.now();

    // Busca em paralelo: treinos do dia + ciclo mensal
    final results = await Future.wait([
      TrainingService.fetchTrainingsListForDate(boxId: _boxId, date: now),
      _fetchCycleData(now),
    ]);

    return _HomeData(
      trainings: results[0] as List<Training>,
      cycle: results[1] as Map<String, dynamic>?,
    );
  }

  Future<Map<String, dynamic>?> _fetchCycleData(DateTime date) async {
    try {
      final key = '${date.month.toString().padLeft(2, '0')}-${date.year}';
      final doc =
          await FirebaseFirestore.instance.collection('cycles').doc(key).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  void _openRegisterBoxSheet(BuildContext context) {
    showAppBottomSheet(context, const BoxSignupCoach());
  }

  void _refresh() => setState(() => _futureData = _loadHomeData());

  // ── Texto de saudação pelo horário ──────────────────────────────────────────
  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bom dia';
    if (h < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  // ── Nome do usuário logado (primeiro nome apenas) ───────────────────────────
  String get _userName {
    final displayName =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    if (displayName.isEmpty) return 'Coach';
    // Retorna só o primeiro nome
    return displayName.split(' ').first;
  }

  // ── Data formatada para exibição ────────────────────────────────────────────
  String get _formattedDate {
    final now = DateTime.now();
    final weekday = DateFormat('EEEE', 'pt_BR').format(now);
    final day = now.day;
    final month = DateFormat('MMMM', 'pt_BR').format(now);
    // "quarta-feira, 11 de março"
    return '$weekday, $day de $month';
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),
      bottomNavigationBar: const BottomNavBar(),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: AppColors.baseBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: 16 * scale,
            horizontal: 12 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Item 4: Saudação contextual ──────────────────────────────
              _GreetingHeader(
                greeting: _greeting,
                userName: _userName,
                dateLabel: _formattedDate,
                scale: scale,
              ),

              SizedBox(height: 24 * scale),

              SizedBox(height: 4 * scale),

              // ── Treino de Hoje + dados da IA ─────────────────────────────
              FutureBuilder<_HomeData>(
                future: _futureData,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snap.hasError) {
                    return _ErrorState(onRetry: _refresh, scale: scale);
                  }

                  final data = snap.data!;

                  // ── Item 5: Estado vazio inteligente ─────────────────────
                  if (!data.hasTraining) {
                    return _EmptyTrainingState(
                      scale: scale,
                      onCadastrar:
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.coachTrainings,
                          ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Card do treino de hoje
                      CoachTodayWorkoutCard(
                        boxId: _boxId,
                        date: DateTime.now(),
                      ),

                      // ── Item 1: Chips de estímulo da IA ──────────────────
                      if (data.allKeyMetrics.isNotEmpty) ...[
                        SizedBox(height: 10 * scale),
                        _AIMetricsChips(
                          metrics: data.allKeyMetrics,
                          scale: scale,
                        ),
                      ],

                      // ── Item 2: Carrossel de alertas da IA ───────────────
                      if (data.allAlerts.isNotEmpty) ...[
                        SizedBox(height: 20 * scale),
                        _AIAlertCarousel(alerts: data.allAlerts, scale: scale),
                      ],

                      // ── Item 3: Card de ciclo mensal ─────────────────────
                      if (data.cycle != null) ...[
                        SizedBox(height: 24 * scale),
                        _SectionLabel(
                          label: 'Ciclo Mensal',
                          scale: scale,
                          color: AppColors.darkText,
                        ),
                        SizedBox(height: 8 * scale),
                        _CycleCard(
                          cycle: data.cycle!,
                          date: DateTime.now(),
                          scale: scale,
                        ),
                      ],
                    ],
                  );
                },
              ),

              SizedBox(height: 16 * scale),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _GreetingHeader — Item 4
// =============================================================================

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.greeting,
    required this.userName,
    required this.dateLabel,
    required this.scale,
  });

  final String greeting;
  final String userName;
  final String dateLabel;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Data contextual em destaque pequeno
        Text(
          dateLabel,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 12 * scale,
            fontWeight: AppFontWeight.regular,
            color: AppColors.mediumGray,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 2 * scale),
        // Saudação principal com nome do usuário
        Text(
          '$greeting, $userName',
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 22 * scale,
            fontWeight: AppFontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _SectionLabel — label de seção reutilizável
// =============================================================================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.scale, this.color});

  final String label;
  final double scale;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: AppFonts.roboto,
        fontSize: 13 * scale,
        fontWeight: AppFontWeight.bold,
        color: color ?? AppColors.mediumGray,
        letterSpacing: 0.8,
      ),
    );
  }
}

// =============================================================================
// _AIMetricsChips — Item 1: key_metrics da IA como chips horizontais
// =============================================================================

class _AIMetricsChips extends StatelessWidget {
  const _AIMetricsChips({required this.metrics, required this.scale});

  final List<String> metrics;
  final double scale;

  // Mapeia cada tipo de métrica a um ícone representativo
  IconData _iconFor(String metric) {
    final m = metric.toLowerCase();
    if (m.contains('força')) return Icons.fitness_center;
    if (m.contains('potência') || m.contains('potencia')) return Icons.bolt;
    if (m.contains('cardio') || m.contains('cardiovascular')) {
      return Icons.favorite_outline;
    }
    if (m.contains('resistência') || m.contains('resistencia')) {
      return Icons.timer_outlined;
    }
    if (m.contains('coordenação') || m.contains('coordenacao')) {
      return Icons.psychology_outlined;
    }
    if (m.contains('estabilidade')) return Icons.balance;
    if (m.contains('mobilidade') || m.contains('flexibilidade')) {
      return Icons.self_improvement;
    }
    return Icons.star_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 12 * scale,
              color: AppColors.baseBlue,
            ),
            SizedBox(width: 4 * scale),
            Text(
              'Estímulos identificados pela IA',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 11 * scale,
                color: AppColors.baseBlue,
                fontWeight: AppFontWeight.medium,
              ),
            ),
          ],
        ),
        SizedBox(height: 6 * scale),
        Wrap(
          spacing: 6 * scale,
          runSpacing: 6 * scale,
          children:
              metrics.map((m) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale,
                    vertical: 5 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.baseBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20 * scale),
                    border: Border.all(
                      color: AppColors.baseBlue.withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconFor(m),
                        size: 12 * scale,
                        color: AppColors.baseBlue,
                      ),
                      SizedBox(width: 4 * scale),
                      Text(
                        m,
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontSize: 12 * scale,
                          color: AppColors.baseBlue,
                          fontWeight: AppFontWeight.medium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

// =============================================================================
// _AIAlertCarousel — Item 2: carrossel de alertas (um card por alerta)
// =============================================================================

class _AIAlertCarousel extends StatefulWidget {
  const _AIAlertCarousel({required this.alerts, required this.scale});

  final Map<String, String> alerts;
  final double scale;

  @override
  State<_AIAlertCarousel> createState() => _AIAlertCarouselState();
}

class _AIAlertCarouselState extends State<_AIAlertCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // "fadiga_acumulada_ombros" → "Fadiga Acumulada Ombros"
  String _formatTitle(String key) => key
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final entries = widget.alerts.entries.toList();
    final s = widget.scale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Label da seção ────────────────────────────────────────────────
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 13 * s,
              color: const Color(0xFFFFB300),
            ),
            SizedBox(width: 5 * s),
            Text(
              'Alertas do treino',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13 * s,
                fontWeight: AppFontWeight.bold,
                color: AppColors.darkText,
                letterSpacing: 0.8,
              ),
            ),
            const Spacer(),
            // Indicador "1 / N"
            Text(
              '${_currentPage + 1} / ${entries.length}',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 11 * s,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ),
        SizedBox(height: 8 * s),

        // ── PageView dos cards ────────────────────────────────────────────
        SizedBox(
          height: 62 * s,
          child: PageView.builder(
            controller: _controller,
            itemCount: entries.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, i) {
              final e = entries[i];
              return Padding(
                padding: EdgeInsets.only(right: 8 * s),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(10 * s),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withOpacity(0.6),
                      width: 1.0,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * s,
                    vertical: 0,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Container(
                        width: 6 * s,
                        height: 6 * s,
                        margin: EdgeInsets.only(right: 8 * s),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB300),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _formatTitle(e.key),
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 13 * s,
                            fontWeight: AppFontWeight.medium,
                            color: AppColors.darkText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 8 * s),

        // ── Pontos indicadores + CTA ──────────────────────────────────────
        Row(
          children: [
            // Dots
            ...List.generate(entries.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: 4 * s),
                width: active ? 16 * s : 6 * s,
                height: 6 * s,
                decoration: BoxDecoration(
                  color:
                      active
                          ? const Color(0xFFFFB300)
                          : const Color(0xFFFFB300).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3 * s),
                ),
              );
            }),
            const Spacer(),
            // CTA → Insights
            GestureDetector(
              onTap:
                  () => Navigator.pushNamed(context, AppRoutes.coachInsights),
              child: Row(
                children: [
                  Text(
                    'Ver Insights completos',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 11 * s,
                      color: const Color(0xFFFFB300),
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 3 * s),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10 * s,
                    color: const Color(0xFFFFB300),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// _CycleCard — Item 3: resumo do ciclo mensal
// =============================================================================

class _CycleCard extends StatelessWidget {
  const _CycleCard({
    required this.cycle,
    required this.date,
    required this.scale,
  });

  final Map<String, dynamic> cycle;
  final DateTime date;
  final double scale;

  String get _monthLabel {
    return DateFormat('MMMM yyyy', 'pt_BR').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final overviewStats =
        (cycle['overview_stats'] as Map<String, dynamic>?) ?? {};
    final trainingsCount = overviewStats['trainingsCount'] as int? ?? 0;
    final biggestStimulus = cycle['biggestStimulusLabel']?.toString() ?? '—';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: const Color(0xFF224DFF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF224DFF).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        14 * scale,
        16 * scale,
        14 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: mês + badge IA ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _monthLabel.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 11 * scale,
                  fontWeight: AppFontWeight.bold,
                  color: AppColors.mediumGray,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 3 * scale,
                ),
                decoration: BoxDecoration(
                  color: AppColors.baseBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20 * scale),
                  border: Border.all(
                    color: AppColors.baseBlue.withOpacity(0.2),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 10 * scale,
                      color: AppColors.baseBlue,
                    ),
                    SizedBox(width: 3 * scale),
                    Text(
                      'Análise IA',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 10 * scale,
                        color: AppColors.baseBlue,
                        fontWeight: AppFontWeight.medium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12 * scale),

          // ── Estatísticas rápidas ──────────────────────────────────────────
          Row(
            children: [
              _CycleStat(
                value: '$trainingsCount',
                label: 'Treinos no mês',
                scale: scale,
              ),
              SizedBox(width: 32 * scale),
              _CycleStat(
                value: biggestStimulus,
                label: 'Estímulo dominante',
                scale: scale,
              ),
            ],
          ),

          SizedBox(height: 12 * scale),
          Divider(color: AppColors.mediumGray.withOpacity(0.15), height: 1),
          SizedBox(height: 8 * scale),

          // ── CTA: Ver Ciclo Mensal ─────────────────────────────────────────
          GestureDetector(
            onTap:
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.coachTrainingInsights,
                ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Ver Ciclo Mensal',
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
    );
  }
}

class _CycleStat extends StatelessWidget {
  const _CycleStat({
    required this.value,
    required this.label,
    required this.scale,
  });

  final String value;
  final String label;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 20 * scale,
            fontWeight: AppFontWeight.bold,
            color: AppColors.darkText, // dado principal: sempre escuro
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 10 * scale,
            fontWeight: AppFontWeight.regular,
            color: AppColors.mediumGray, // rótulo de suporte: cinza
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// _EmptyTrainingState — Item 5: nenhum treino cadastrado hoje
// =============================================================================

class _EmptyTrainingState extends StatelessWidget {
  const _EmptyTrainingState({required this.scale, required this.onCadastrar});

  final double scale;
  final VoidCallback onCadastrar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 36 * scale,
        horizontal: 20 * scale,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(
          color: AppColors.mediumGray.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 40 * scale,
            color: AppColors.mediumGray,
          ),
          SizedBox(height: 12 * scale),
          Text(
            'Nenhum treino cadastrado hoje',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 15 * scale,
              fontWeight: AppFontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 6 * scale),
          Text(
            'Cadastre o treino do dia para que seus alunos\npossam acompanhar e a IA possa analisar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20 * scale),
          ElevatedButton.icon(
            onPressed: onCadastrar,
            icon: Icon(Icons.add, size: 16 * scale),
            label: Text(
              'Cadastrar treino',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13 * scale,
                fontWeight: AppFontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.baseBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: 24 * scale,
                vertical: 12 * scale,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8 * scale),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _ErrorState — quando fetch falha
// =============================================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.scale});

  final VoidCallback onRetry;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32 * scale),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 36 * scale,
            color: AppColors.mediumGray,
          ),
          SizedBox(height: 10 * scale),
          Text(
            'Não foi possível carregar os dados.',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 13 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          SizedBox(height: 12 * scale),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Tentar novamente',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 13 * scale,
                color: AppColors.baseBlue,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
