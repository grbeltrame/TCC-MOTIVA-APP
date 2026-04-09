// lib/shared/widgets/cards/daily_training_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/training.dart';

/*
  Card "Treino de hoje" (atleta)
  ─────────────────────────────────────────────────────────────
  Usa a mesma fonte de dados do coach: fetchTrainingsListForDate.
  Hierarquia visual:
    1. Dropdown de tipo (WOD / LPO / Ginástica / Endurance)
    2. Nome do WOD  → partes[key]['nomeWod']
    3. Foco do dia  → 1ª frase de analysis.overview
    4. Estímulos    → analysis.keyMetrics (chips)
    5. "Ver treino" → AppRoutes.athleteTraining
  ─────────────────────────────────────────────────────────────
*/

// ─────────────────────────────────────────────────────────────────────────────
// Constantes de estilo
// ─────────────────────────────────────────────────────────────────────────────

const _kBlue = Color(0xFF224DFF);
const _kRadius = 12.0;

// ─────────────────────────────────────────────────────────────────────────────
// Modelo interno — dados do card para o tipo selecionado
// ─────────────────────────────────────────────────────────────────────────────

class _CardData {
  final String? wodName;
  final String? focusText;
  final List<String> keyMetrics;

  const _CardData({this.wodName, this.focusText, this.keyMetrics = const []});
}

// ─────────────────────────────────────────────────────────────────────────────
// Opção do dropdown — tipo de treino + id do documento
// ─────────────────────────────────────────────────────────────────────────────

class _DropdownOption {
  final String label;
  final String type;
  final String? trainingId;

  const _DropdownOption({
    required this.label,
    required this.type,
    this.trainingId,
  });

  @override
  bool operator ==(Object other) =>
      other is _DropdownOption &&
      label == other.label &&
      type == other.type &&
      trainingId == other.trainingId;

  @override
  int get hashCode => Object.hash(label, type, trainingId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget principal
// ─────────────────────────────────────────────────────────────────────────────

class DailyTrainingSummaryCard extends StatefulWidget {
  const DailyTrainingSummaryCard({Key? key}) : super(key: key);

  @override
  State<DailyTrainingSummaryCard> createState() =>
      _DailyTrainingSummaryCardState();
}

class _DailyTrainingSummaryCardState extends State<DailyTrainingSummaryCard> {
  static const String _boxId = 'BOX_PRINCIPAL';

  late final Future<List<_DropdownOption>> _futOptions;
  _DropdownOption? _selected;
  Future<_CardData>? _futCardData;

  // ── Partes ignoradas na detecção de tipo ──────────────────────────────────
  static const _kSupportParts = {
    'WARM UP',
    'WARMUP',
    'EXTRA TRAINING',
    'EXTRA',
    'MOBILIDADE',
    'MOBILITY',
    'SKILL',
  };

  // ── Detecta tipo principal do documento ───────────────────────────────────
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
    final main = partes.keys.firstWhere(
      (k) => !_kSupportParts.contains(k.toUpperCase()),
      orElse: () => partes.keys.first,
    );
    return main.toUpperCase();
  }

  // ── Monta opções do dropdown — um Training = uma opção ────────────────────
  Future<List<_DropdownOption>> _buildDropdownOptions() async {
    final trainings = await TrainingService.fetchTrainingsListForDate(
      boxId: _boxId,
      date: DateTime.now(),
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
          type: type,
          trainingId: t.id,
        ),
      );
    }

    opts.sort((a, b) {
      if (a.type == 'WOD') return -1;
      if (b.type == 'WOD') return 1;
      return a.label.compareTo(b.label);
    });

    return opts;
  }

  // ── Carrega dados do tipo selecionado ─────────────────────────────────────
  Future<_CardData> _loadCardData(_DropdownOption opt) async {
    final trainings = await TrainingService.fetchTrainingsListForDate(
      boxId: _boxId,
      date: DateTime.now(),
    );

    Training? matched;
    if (opt.trainingId != null) {
      matched = trainings.cast<Training?>().firstWhere(
        (t) => t?.id == opt.trainingId,
        orElse: () => null,
      );
    }
    matched ??= trainings.cast<Training?>().firstWhere(
      (t) => t?.partes.isNotEmpty ?? false,
      orElse: () => null,
    );

    if (matched == null) return const _CardData();

    // ── nomeWod: busca na parte principal (não-suporte)
    String? wodName;
    final mainKey = matched.partes.keys.firstWhere(
      (k) => !_kSupportParts.contains(k.toUpperCase()),
      orElse: () => matched!.partes.keys.first,
    );
    final mainPart = matched.partes[mainKey] as Map<String, dynamic>?;
    final raw = mainPart?['nomeWod']?.toString().trim();
    if (raw != null && raw.isNotEmpty) wodName = raw;

    // ── focusText: 1ª frase do overview da IA
    String? focusText;
    final overview = matched.analysis?.overview;
    if (overview != null && overview.trim().isNotEmpty) {
      final dotIdx = overview.indexOf('.');
      focusText =
          dotIdx > 0
              ? overview.substring(0, dotIdx + 1).trim()
              : (overview.trim().length > 120
                  ? '${overview.trim().substring(0, 120)}...'
                  : overview.trim());
    }

    // ── keyMetrics da IA
    final keyMetrics = matched.analysis?.keyMetrics ?? [];

    return _CardData(
      wodName: wodName,
      focusText: focusText,
      keyMetrics: keyMetrics,
    );
  }

  @override
  void initState() {
    super.initState();
    _futOptions = _buildDropdownOptions();
    _futOptions.then((opts) {
      if (!mounted || opts.isEmpty) return;
      final def = opts.firstWhere(
        (o) => o.type == 'WOD',
        orElse: () => opts.first,
      );
      setState(() {
        _selected = def;
        _futCardData = _loadCardData(def);
      });
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<List<_DropdownOption>>(
      future: _futOptions,
      builder: (context, snap) {
        // Sem dados ainda
        if (!snap.hasData) return const SizedBox.shrink();

        // Nenhum treino hoje → CTA para cadastrar box
        if (snap.data!.isEmpty) {
          return _buildEmptyState(scale);
        }

        // Tem treino → card completo
        return Container(
          margin: EdgeInsets.only(bottom: 6 * scale),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kRadius * scale),
            border: Border.all(color: _kBlue, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _kBlue.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            12 * scale,
            8 * scale,
            12 * scale,
            10 * scale,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Dropdown de tipo ────────────────────────────────────────
              _buildDropdown(snap.data!, textTheme, scale),

              const SizedBox(height: 8),

              // ── Conteúdo dinâmico ───────────────────────────────────────
              FutureBuilder<_CardData>(
                future: _futCardData,
                builder: (context, dataSnap) {
                  final data = dataSnap.data;
                  return _buildContent(
                    textTheme: textTheme,
                    scale: scale,
                    wodName: data?.wodName,
                    focusText: data?.focusText,
                    keyMetrics: data?.keyMetrics ?? [],
                    loading: dataSnap.connectionState != ConnectionState.done,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dropdown
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildDropdown(
    List<_DropdownOption> opts,
    TextTheme textTheme,
    double scale,
  ) {
    if (opts.length == 1) {
      // Só um tipo → texto simples sem dropdown
      return Text(
        opts.first.label,
        style: textTheme.titleMedium?.copyWith(
          color: _kBlue,
          fontSize: 18 * scale,
          fontWeight: AppFontWeight.bold,
        ),
      );
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<_DropdownOption>(
        value: _selected,
        icon: const Icon(Icons.arrow_drop_down, color: _kBlue, size: 20),
        isDense: true,
        style: textTheme.titleMedium?.copyWith(
          color: _kBlue,
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
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Conteúdo: wodName + focusText + chips + botão
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildContent({
    required TextTheme textTheme,
    required double scale,
    required String? wodName,
    required String? focusText,
    required List<String> keyMetrics,
    required bool loading,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome do WOD
        _labelValueRow(
          textTheme: textTheme,
          scale: scale,
          label: 'Treino do dia: ',
          value: loading ? '...' : (wodName ?? '—'),
        ),

        const SizedBox(height: 8),

        // Foco do dia
        _labelValueRow(
          textTheme: textTheme,
          scale: scale,
          label: 'Foco do dia: ',
          value: loading ? '...' : (focusText ?? '—'),
          valueSize: 12 * scale,
        ),

        // Chips de estímulos
        if (!loading && keyMetrics.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6 * scale,
            runSpacing: 4 * scale,
            children:
                keyMetrics
                    .map((m) => _StimulusChip(label: m, scale: scale))
                    .toList(),
          ),
        ],

        const SizedBox(height: 10),
        Divider(color: Colors.black.withOpacity(0.12), height: 16),
        const SizedBox(height: 6),

        // CTA
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap:
                  () => Navigator.pushNamed(context, AppRoutes.athleteTraining),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ver treino',
                    style: TextStyle(
                      color: _kBlue,
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 11 * scale,
                    ),
                  ),
                  SizedBox(width: 3 * scale),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10 * scale,
                    color: _kBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _labelValueRow({
    required TextTheme textTheme,
    required double scale,
    required String label,
    required String value,
    double? valueSize,
  }) {
    final size = valueSize ?? 16 * scale;
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.darkText,
              fontSize: size,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          TextSpan(
            text: value,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.mediumGray,
              fontSize: size,
              fontWeight: AppFontWeight.medium,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Estado vazio — nenhum treino cadastrado
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildEmptyState(double scale) {
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de estímulo da IA
// ─────────────────────────────────────────────────────────────────────────────

class _StimulusChip extends StatelessWidget {
  final String label;
  final double scale;

  const _StimulusChip({required this.label, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: AppColors.baseBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: AppColors.baseBlue.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 11 * scale,
          color: AppColors.baseBlue,
          fontWeight: AppFontWeight.medium,
        ),
      ),
    );
  }
}
