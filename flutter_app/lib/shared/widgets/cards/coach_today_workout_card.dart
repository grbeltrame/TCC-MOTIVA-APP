import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/training.dart';

/*
  Card "Treino de hoje" (professor)
  ─────────────────────────────────────────────────────────────
  • Dropdown filtra por TIPO DE TREINO (WOD / LPO / Ginástica /
    Endurance) — cada opção = um documento do dia no Firestore.
    Se houver 2 WODs no dia: "WOD" e "WOD (2)".
  • "Treino do dia:"  → nomeWod da parte principal do documento
  • "Foco do dia:"    → 1ª frase do overview da IA (até o '.')
  • Divisor sutil + botão "Ver treino"
  • Borda azul arredondada no card
*/

// ─────────────────────────────────────────────────────────────────────────────
// Modelo interno — agrega Summary + wodName + focusText num único Future
// ─────────────────────────────────────────────────────────────────────────────

class _CardData {
  final DailyWorkoutSummary? summary;
  final String? wodName; // nomeWod da parte selecionada
  final String? focusText; // 1ª frase do overview da IA

  const _CardData({this.summary, this.wodName, this.focusText});
}

// ─────────────────────────────────────────────────────────────────────────────
// Opção do dropdown — label exibido + chave de busca
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownOption {
  final String label; // ex: "WOD", "WOD (2)", "ENDURANCE"
  final String category; // chave da parte: "WOD", "ENDURANCE" …
  final String? trainingId; // ID do documento (para múltiplos WODs no dia)

  const _DropdownOption({
    required this.label,
    required this.category,
    this.trainingId,
  });

  @override
  bool operator ==(Object other) =>
      other is _DropdownOption &&
      label == other.label &&
      category == other.category &&
      trainingId == other.trainingId;

  @override
  int get hashCode => Object.hash(label, category, trainingId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────

class CoachTodayWorkoutCard extends StatefulWidget {
  final String boxId;
  final DateTime date;

  const CoachTodayWorkoutCard({
    super.key,
    required this.boxId,
    required this.date,
  });

  @override
  State<CoachTodayWorkoutCard> createState() => _CoachTodayWorkoutCardState();
}

class _CoachTodayWorkoutCardState extends State<CoachTodayWorkoutCard> {
  // Futuro das opções do dropdown
  late final Future<List<_DropdownOption>> _futOptions;

  _DropdownOption? _selected;
  Future<_CardData>? _futCardData;

  // Estilo
  static const Color kBlue = Color(0xFF224DFF);
  static const Color kBlueBorder = Color(0xFF224DFF);
  static const Color kGreyBody = Color(0xFF666666);
  static const double kRadius = 12;

  // ── Inicialização ───────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _futOptions = _buildDropdownOptions();
    _futOptions.then((opts) {
      if (!mounted || opts.isEmpty) return;
      // Padrão: primeiro WOD, senão primeira opção disponível
      final def = opts.firstWhere(
        (o) => o.category.toUpperCase() == 'WOD',
        orElse: () => opts.first,
      );
      setState(() {
        _selected = def;
        _futCardData = _loadCardData(def);
      });
    });
  }

  // ── Constrói as opções do dropdown ─────────────────────────────────────────
  //
  // Cada Training do dia = um documento = uma opção.
  // O TIPO é determinado pela parte principal do documento:
  //   LPO > Ginástica > Endurance > WOD (em ordem de especificidade)
  // Partes de suporte (WARM UP, EXTRA TRAINING) são ignoradas para o label.
  // Se dois docs têm o mesmo tipo: "WOD" e "WOD (2)".

  static const _kSupportParts = {
    'WARM UP',
    'WARMUP',
    'EXTRA TRAINING',
    'EXTRA',
    'MOBILIDADE',
    'MOBILITY',
  };

  String _detectType(Map<String, dynamic> partes) {
    final keys = partes.keys.map((k) => k.toUpperCase()).toSet();
    if (keys.contains('LPO')) return 'LPO';
    if (keys.any((k) => k.contains('GINASTIC') || k.contains('GYMNAST'))) {
      return 'Ginástica';
    }
    if (keys.any(
      (k) => k.contains('ENDUR') || k.contains('RUNNING') || k.contains('RUN'),
    )) {
      return 'Endurance';
    }
    if (keys.contains('WOD')) return 'WOD';
    // Fallback: primeira parte que não seja suporte
    final main = partes.keys.firstWhere(
      (k) => !_kSupportParts.contains(k.toUpperCase()),
      orElse: () => partes.keys.first,
    );
    return main.toUpperCase();
  }

  Future<List<_DropdownOption>> _buildDropdownOptions() async {
    final trainings = await TrainingService.fetchTrainingsListForDate(
      boxId: widget.boxId,
      date: widget.date,
    );

    final List<_DropdownOption> opts = [];
    final Map<String, int> typeCount = {};

    for (final t in trainings) {
      if (t.partes.isEmpty) continue;
      final type = _detectType(t.partes);
      typeCount[type] = (typeCount[type] ?? 0) + 1;
      final count = typeCount[type]!;
      opts.add(
        _DropdownOption(
          label: count == 1 ? type : '$type ($count)',
          category: type,
          trainingId: t.id,
        ),
      );
    }

    // Ordena: WOD primeiro, depois alfabético
    opts.sort((a, b) {
      if (a.category == 'WOD') return -1;
      if (b.category == 'WOD') return 1;
      return a.label.compareTo(b.label);
    });

    return opts;
  }

  // ── Carrega Summary + wodName + focusText em paralelo ──────────────────────

  Future<_CardData> _loadCardData(_DropdownOption opt) async {
    // Busca todos os trainings do dia (o service tem cache implícito na sessão)
    final trainings = await TrainingService.fetchTrainingsListForDate(
      boxId: widget.boxId,
      date: widget.date,
    );

    // Encontra o Training correto: por ID se disponível, senão por categoria
    Training? matched;
    if (opt.trainingId != null) {
      matched = trainings.cast<Training?>().firstWhere(
        (t) => t?.id == opt.trainingId,
        orElse: () => null,
      );
    }
    matched ??= trainings.cast<Training?>().firstWhere(
      (t) => t?.partes.containsKey(opt.category) ?? false,
      orElse: () => null,
    );

    // ── wodName: busca nomeWod dentro da parte selecionada
    String? wodName;
    if (matched != null) {
      final parte =
          matched.partes[opt.category] as Map<String, dynamic>? ??
          matched.partes[opt.category.toUpperCase()] as Map<String, dynamic>?;
      final raw = parte?['nomeWod']?.toString().trim();
      if (raw != null && raw.isNotEmpty) wodName = raw;
    }

    // ── focusText: 1ª frase do overview da IA
    String? focusText;
    final overview = matched?.analysis?.overview;
    if (overview != null && overview.trim().isNotEmpty) {
      final dotIdx = overview.indexOf('.');
      focusText =
          dotIdx > 0
              ? overview.substring(0, dotIdx + 1).trim()
              : (overview.trim().length > 120
                  ? '${overview.trim().substring(0, 120)}...'
                  : overview.trim());
    }

    // ── DailyWorkoutSummary (para compatibilidade futura)
    final summary =
        await TodayWorkoutHelpers.fetchDailyWorkoutSummaryByCategory(
          boxId: widget.boxId,
          date: widget.date,
          category: opt.category,
        );

    return _CardData(summary: summary, wodName: wodName, focusText: focusText);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBlueBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kBlue.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dropdown de categoria / treino ──────────────────────────────
          FutureBuilder<List<_DropdownOption>>(
            future: _futOptions,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Row(
                  children: [
                    Text(
                      'Carregando…',
                      style: textTheme.titleMedium?.copyWith(
                        color: AppColors.baseBlue,
                        fontSize: 18 * scale,
                        fontWeight: AppFontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                );
              }

              if (snap.hasError || snap.data!.isEmpty) {
                return Text(
                  snap.hasError
                      ? 'Falha ao carregar treinos'
                      : 'Nenhum treino disponível hoje',
                  style: textTheme.bodyMedium?.copyWith(color: kGreyBody),
                );
              }

              final opts = snap.data!;

              return DropdownButtonHideUnderline(
                child: DropdownButton<_DropdownOption>(
                  value: _selected,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: kBlue,
                    size: 20,
                  ),
                  isDense: true,
                  style: textTheme.titleMedium?.copyWith(
                    color: kBlue,
                    fontWeight: FontWeight.w700,
                  ),
                  items:
                      opts
                          .map(
                            (opt) => DropdownMenuItem<_DropdownOption>(
                              value: opt,
                              child: Text(
                                opt.label,
                                style: textTheme.titleMedium?.copyWith(
                                  color: AppColors.baseBlue,
                                  fontSize: 18 * scale,
                                  fontWeight: AppFontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() {
                      _selected = val;
                      _futCardData = _loadCardData(val);
                    });
                  },
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Conteúdo dinâmico ───────────────────────────────────────────
          FutureBuilder<_CardData>(
            future: _futCardData,
            builder: (context, snap) {
              // Skeleton enquanto carrega
              if (_selected == null ||
                  snap.connectionState == ConnectionState.waiting ||
                  snap.connectionState == ConnectionState.active) {
                return _buildContent(
                  textTheme: textTheme,
                  scale: scale,
                  wodName: null,
                  focusText: null,
                );
              }

              if (snap.hasError) {
                return _buildContent(
                  textTheme: textTheme,
                  scale: scale,
                  wodName: '—',
                  focusText: 'Não foi possível carregar o foco.',
                );
              }

              final data = snap.data!;
              return _buildContent(
                textTheme: textTheme,
                scale: scale,
                wodName: data.wodName,
                focusText: data.focusText,
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Conteúdo: Treino do dia + Foco do dia + botões
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContent({
    required TextTheme textTheme,
    required double scale,
    required String? wodName,
    required String? focusText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Treino do dia: NOME DO WOD"
        _labelValueRow(
          textTheme: textTheme,
          scale: scale,
          label: 'Treino do dia: ',
          value: wodName ?? '—',
          valueFontSize: 16 * scale,
          valueWeight: AppFontWeight.medium,
        ),

        const SizedBox(height: 8),

        // "Foco do dia: 1ª frase do overview da IA"
        _labelValueRow(
          textTheme: textTheme,
          scale: scale,
          label: 'Foco do dia: ',
          value: focusText ?? '—',
          valueFontSize: 12 * scale,
          valueWeight: AppFontWeight.regular,
          valueHeight: 1.3,
        ),

        const SizedBox(height: 10),
        Divider(color: Colors.black.withValues(alpha: 0.12), height: 16),
        const SizedBox(height: 6),
        _buttonsRow(textTheme),
      ],
    );
  }

  Widget _labelValueRow({
    required TextTheme textTheme,
    required double scale,
    required String label,
    required String value,
    required double valueFontSize,
    required FontWeight valueWeight,
    double? valueHeight,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.darkText, // título: sempre escuro
              fontSize: valueFontSize,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          TextSpan(
            text: value,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mediumGray, // valor: sempre cinza
              fontSize: valueFontSize,
              fontWeight: valueWeight,
              height: valueHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttonsRow(TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.coachTrainings),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ver treino',
                style: TextStyle(
                  color: kBlue,
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.arrow_forward_ios, size: 10, color: kBlue),
            ],
          ),
        ),
      ],
    );
  }
}
