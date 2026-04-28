// lib/shared/widgets/sections/athlete/evolution_charts_section.dart
//
// Seção de gráficos de evolução da tela /athlete_evolution.
// Duas abas: Volume (dias de treino por semana) e PRs (linha-escada do
// melhor registro ao longo do tempo). Reaproveita o período [from, to]
// selecionado no topo da tela.

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_prs_service.dart';
import 'package:flutter_app/core/services/weekly_load_service.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// =============================================================================
// Zonas de Gabbett (ACWR) — cores semânticas.
// Stroke: usado em rótulos de status, marcadores e legenda.
// Fill:   usado nas zonas coloridas de fundo do gráfico (preenchidas).
// =============================================================================

const Color _zoneRecoveryStroke = Color(0xFF60A5FA);
const Color _zoneSafeStroke = Color(0xFF22C55E);
const Color _zoneRiskStroke = Color(0xFFEF4444);

const Color _zoneRecoveryFill = Color(0xFFD6E9FF); // azul muito claro
const Color _zoneSafeFill = Color(0xFFDDF4E2); // verde muito claro
const Color _zoneRiskFill = Color(0xFFFFDDDE); // vermelho muito claro

// Cor distinta para o card "Volume da Semana" — roxo, deliberadamente
// diferente dos azuis da zona de Recuperação para evitar confusão cognitiva.
const Color _volumeCardColor = Color(0xFF7C3AED);

// =============================================================================
// Estilo estrutural compartilhado entre os dois gráficos (Volume e PRs).
// =============================================================================

/// Altura padrão do plot do gráfico (escala aplicada pelo caller).
/// Usada em [_AcwrComboChart].
const double _kChartHeight = 220.0;

/// Altura do plot do gráfico de PRs. É maior que [_kChartHeight] em uma
/// quantidade equivalente à altura da legenda do gráfico de Volume — assim
/// os dois cards (frame + título + chart + legenda) terminam com a mesma
/// altura total visível.
const double _kPrChartHeight = 260.0;

/// Estilo compartilhado dos labels dos eixos.
TextStyle _kAxisLabelStyle(double scale) => TextStyle(
  fontFamily: AppFonts.roboto,
  fontSize: 9 * scale,
  color: AppColors.mediumGray,
);

/// Linhas de grade horizontais — mesmo tom nos dois gráficos.
MajorGridLines get _kGridLines =>
    const MajorGridLines(width: 0.5, color: AppColors.lightGray);

AxisLine get _kAxisLineSoft =>
    const AxisLine(width: 0.5, color: AppColors.lightGray);

String _icnStatusLabel(double? icn) {
  if (icn == null) return 'Sem histórico';
  if (icn < 40) return 'Recuperação';
  if (icn < 75) return 'Ideal';
  return 'Sobrecarga';
}

/// Frase descritiva do status (tooltip).
String _icnStatusTooltip(double? icn) {
  if (icn == null) return 'Sem base histórica ainda';
  if (icn < 40) return '🔵 Recuperação ativa.';
  if (icn < 75) return '🟢 Evolução perfeita.';
  return '🔴 Sobrecarga. Risco de lesão.';
}

Color _icnStatusColor(double? icn) {
  if (icn == null) return AppColors.mediumGray;
  if (icn < 40) return _zoneRecoveryStroke;
  if (icn < 75) return _zoneSafeStroke;
  return _zoneRiskStroke;
}

/// Classificação qualitativa do volume relativo à média do próprio período.
/// - Alto:   volume > 1.2 × média
/// - Baixo:  volume < 0.8 × média
/// - Médio:  dentro dessa faixa
String _volumeQualitative(double volume, double referenceAvg) {
  if (referenceAvg <= 0) return 'Médio';
  final ratio = volume / referenceAvg;
  if (ratio > 1.2) return 'Alto';
  if (ratio < 0.8) return 'Baixo';
  return 'Médio';
}

/// Modal educativo com valores dinâmicos do atleta.
void _showEffortInfoModal(
  BuildContext context, {
  required double lastWeekVolume,
  double? cargaCronica,
}) {
  final scale = MediaQuery.of(context).size.width / 375.0;
  final baseStr =
      cargaCronica != null ? '${cargaCronica.toStringAsFixed(0)} pts' : '—';
  final weekStr = '${lastWeekVolume.toStringAsFixed(0)} pts';

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder:
        (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scale),
          ),
          titlePadding: EdgeInsets.fromLTRB(
            20 * scale,
            18 * scale,
            12 * scale,
            0,
          ),
          contentPadding: EdgeInsets.fromLTRB(
            20 * scale,
            12 * scale,
            20 * scale,
            4 * scale,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  'Como ler o seu gráfico?',
                  style: TextStyle(
                    fontFamily: AppFonts.montserrat,
                    fontWeight: FontWeight.bold,
                    fontSize: 14 * scale,
                    color: AppColors.darkText,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                icon: Icon(
                  Icons.close,
                  size: 20 * scale,
                  color: AppColors.mediumGray,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SingleChildScrollView(
            // Adicionado para evitar quebra de tela em celulares pequenos
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoMetaphorLine(
                  emoji: '📈',
                  title: 'A linha é o termômetro do seu corpo',
                  text:
                      'O gráfico funciona como uma balança. Ele não mostra apenas o quanto você suou, mas como o seu corpo está reagindo. A linha sobe ou desce comparando o seu esforço desta semana com a base de resistência que você já construiu nas semanas anteriores.',
                  scale: scale,
                ),
                SizedBox(height: 10 * scale),
                _InfoMetaphorLine(
                  emoji: '🚦',
                  title: 'O semáforo (As cores)',
                  text:
                      'A cor Azul indica que você está exigindo menos do corpo (Recuperação). A Verde mostra que está evoluindo com segurança (Ideal). Se a linha cruzar para a Vermelha, significa que você pisou fundo demais e o risco de se machucar é alto (Sobrecarga). Tudo isso com base no seu histórico, então é ajustado e muda toda semana quando você registra treinos.',
                  scale: scale,
                ),
                SizedBox(height: 10 * scale),
                _InfoMetaphorLine(
                  emoji: '🛡️',
                  title: 'Proteção 100% personalizada',
                  text:
                      'Não existe um limite fixo igual para todos. O seu limite depende exclusivamente do seu histórico. Se você dobrar o seu volume normal de treinos de uma vez só, o gráfico vai te alertar. Mantenha a linha no Verde para ganhar condicionamento físico sem se lesionar.',
                  scale: scale,
                ),
                SizedBox(height: 12 * scale),
                Container(
                  padding: EdgeInsets.all(10 * scale),
                  decoration: BoxDecoration(
                    color: AppColors.baseBlue.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10 * scale),
                    border: Border.all(
                      color: AppColors.baseBlue.withValues(alpha: 0.20),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontSize: 12 * scale,
                        color: AppColors.darkText,
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(
                          text: '📌 Seu resumo atual:\n',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text: 'Volume Base: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: '$baseStr/semana\n'),
                        const TextSpan(
                          text: 'Última semana: ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: weekStr),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: EdgeInsets.fromLTRB(
            12 * scale,
            0,
            12 * scale,
            10 * scale,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Entendi',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: FontWeight.bold,
                  fontSize: 12 * scale,
                  color: AppColors.baseBlue,
                ),
              ),
            ),
          ],
        ),
  );
}

class _InfoMetaphorLine extends StatelessWidget {
  final String emoji;
  final String title;
  final String text;
  final double scale;

  const _InfoMetaphorLine({
    required this.emoji,
    required this.title,
    required this.text,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: TextStyle(fontSize: 18 * scale)),
        SizedBox(width: 8 * scale),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.darkText,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EvolutionChartsSection extends StatefulWidget {
  final DateTime from;
  final DateTime to;

  const EvolutionChartsSection({Key? key, required this.from, required this.to})
    : super(key: key);

  @override
  State<EvolutionChartsSection> createState() => _EvolutionChartsSectionState();
}

class _EvolutionChartsSectionState extends State<EvolutionChartsSection> {
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6 * scale),
            child: Text(
              'Evolução',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 4 * scale),
          TabBar(
            labelColor: AppColors.baseBlue,
            unselectedLabelColor: AppColors.mediumGray,
            indicatorColor: AppColors.baseBlue,
            labelStyle: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.bold,
              fontSize: 12 * scale,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
            ),
            tabs: const [Tab(text: 'Volume'), Tab(text: 'PRs')],
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            height: 400 * scale,
            child: TabBarView(
              children: [
                _VolumeEvolutionTab(from: widget.from, to: widget.to),
                _PrsEvolutionTab(from: widget.from, to: widget.to),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Aba Volume — combo chart ACWR (barras de volume + linha de ICN)
// =============================================================================

class _VolumeEvolutionTab extends StatefulWidget {
  final DateTime from;
  final DateTime to;
  const _VolumeEvolutionTab({required this.from, required this.to});

  @override
  State<_VolumeEvolutionTab> createState() => _VolumeEvolutionTabState();
}

class _VolumeEvolutionTabState extends State<_VolumeEvolutionTab> {
  late Future<List<WeeklyLoadEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(_VolumeEvolutionTab old) {
    super.didUpdateWidget(old);
    if (old.from != widget.from || old.to != widget.to) {
      setState(() {});
    }
  }

  // PRs já vêm contabilizados no campo prsCount de cada WeeklyLoadEntry —
  // não é necessário fazer uma segunda query na coleção prs/.
  Future<List<WeeklyLoadEntry>> _load() =>
      WeeklyLoadService.fetchHistory(limit: 52);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 2 * scale),
      child: FutureBuilder<List<WeeklyLoadEntry>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(
              height: 300 * scale,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          final allWeeks = snap.data ?? const <WeeklyLoadEntry>[];

          // Filtra pelas semanas que intersectam o período, limita a 12.
          final fromDay = DateTime(
            widget.from.year,
            widget.from.month,
            widget.from.day,
          );
          final toDay = DateTime(
            widget.to.year,
            widget.to.month,
            widget.to.day,
          );
          final filtered =
              allWeeks.where((e) {
                  final start = DateTime.tryParse(e.weekStart);
                  if (start == null) return false;
                  final end =
                      DateTime.tryParse(e.weekEnd) ??
                      start.add(const Duration(days: 6));
                  return !end.isBefore(fromDay) && !start.isAfter(toDay);
                }).toList()
                ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

          final trimmed =
              filtered.length > 12
                  ? filtered.sublist(filtered.length - 12)
                  : filtered;

          if (trimmed.isEmpty) {
            return _ChartCard(
              title: 'VOLUME E STATUS DO CORPO',
              scale: scale,
              child: _EmptyMessage(
                text: 'Sem treinos registrados no período selecionado.',
                scale: scale,
              ),
            );
          }

          // _AcwrPoint lê prsCount diretamente do WeeklyLoadEntry —
          // sem query extra à coleção prs/.
          final points =
              trimmed
                  .map(
                    (w) => _AcwrPoint(
                      label: _shortLabel(w),
                      weekStart: w.weekStart,
                      volume: w.totalLoadAll,
                      icn: w.icnAll,
                      cargaCronica: w.cargaCronica,
                      baselineType: w.baselineType,
                      prCount: w.prsCount,
                    ),
                  )
                  .toList();

          // Stats de cabeçalho — volume da ÚLTIMA semana (não soma).
          final lastPoint = points.last;
          final lastWeekVolume = lastPoint.volume;
          final lastWeekCargaCronica = lastPoint.cargaCronica;

          final weeksWithIcn =
              points.where((p) => p.icn != null).map((p) => p.icn!).toList();
          final avgIcn =
              weeksWithIcn.isEmpty
                  ? null
                  : weeksWithIcn.reduce((a, b) => a + b) / weeksWithIcn.length;
          final currentIcn = lastPoint.icn;

          return _ChartCard(
            title: 'VOLUME E STATUS DO CORPO',
            scale: scale,
            trailing: IconButton(
              tooltip: 'Como calculamos o seu esforço?',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: BoxConstraints.tightFor(
                width: 24 * scale,
                height: 24 * scale,
              ),
              icon: Icon(
                Icons.info_outline,
                size: 18 * scale,
                color: AppColors.mediumGray,
              ),
              onPressed:
                  () => _showEffortInfoModal(
                    context,
                    lastWeekVolume: lastWeekVolume,
                    cargaCronica: lastWeekCargaCronica,
                  ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AcwrStatsHeader(
                  lastWeekVolume: lastWeekVolume,
                  cargaCronica: lastWeekCargaCronica,
                  avgIcn: avgIcn,
                  currentIcn: currentIcn,
                  scale: scale,
                ),
                SizedBox(height: 10 * scale),
                _AcwrComboChart(points: points, scale: scale),
                SizedBox(height: 8 * scale),
                _AcwrLegend(scale: scale),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _shortLabel(WeeklyLoadEntry e) {
    final start = DateTime.tryParse(e.weekStart);
    if (start == null) return e.weekLabel;
    return DateFormat('dd/MM').format(start);
  }
}

// =============================================================================
// Modelos e helpers da aba ACWR
// =============================================================================

class _AcwrPoint {
  final String label; // "dd/MM" do início da semana
  final String weekStart; // ISO YYYY-MM-DD
  final double volume; // totalLoadAll
  final double? icn; // icnAll (null em cold_start)
  final double? cargaCronica; // média das últimas 4 semanas (Volume Base)
  final String baselineType;
  final int prCount; // prsCount do weekly_load doc

  bool get hasPr => prCount > 0;

  _AcwrPoint({
    required this.label,
    required this.weekStart,
    required this.volume,
    required this.icn,
    required this.cargaCronica,
    required this.baselineType,
    required this.prCount,
  });
}

// =============================================================================
// Stats Header da aba ACWR
// =============================================================================

class _AcwrStatsHeader extends StatelessWidget {
  final double lastWeekVolume;
  final double? cargaCronica;
  final double? avgIcn;
  final double? currentIcn;
  final double scale;

  const _AcwrStatsHeader({
    required this.lastWeekVolume,
    required this.cargaCronica,
    required this.avgIcn,
    required this.currentIcn,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final baseLabel =
        cargaCronica != null
            ? 'Base: ${cargaCronica!.toStringAsFixed(0)} pts/sem'
            : 'Base: sem histórico';

    // IntrinsicHeight força os 3 cards à mesma altura, independente de quantas
    // linhas o subtítulo ocupa em cada um.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MiniStat(
              label: 'VOLUME DA SEMANA',
              value: lastWeekVolume.toStringAsFixed(0),
              subtitle: baseLabel,
              scale: scale,
              // Cor distinta dos azuis da zona de Recuperação para evitar
              // confusão cognitiva entre "card" e "status".
              color: _volumeCardColor,
            ),
          ),
          SizedBox(width: 6 * scale),
          Expanded(
            child: _MiniStat(
              label: 'RITMO MÉDIO',
              value: avgIcn == null ? '—' : _icnStatusLabel(avgIcn),
              subtitle: 'últimas 12 sem.',
              scale: scale,
              color: _icnStatusColor(avgIcn),
            ),
          ),
          SizedBox(width: 6 * scale),
          Expanded(
            child: _MiniStat(
              label: 'STATUS ATUAL',
              value: _icnStatusLabel(currentIcn),
              subtitle: 'nesta semana',
              scale: scale,
              color: _icnStatusColor(currentIcn),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Combo chart (barras de volume + linha de ICN + zonas Gabbett + PR stars)
// =============================================================================

class _AcwrComboChart extends StatelessWidget {
  final List<_AcwrPoint> points;
  final double scale;

  const _AcwrComboChart({required this.points, required this.scale});

  @override
  Widget build(BuildContext context) {
    // Fronteiras DINÂMICAS das zonas, derivadas da cargaCronica mais recente.
    // 0.8× e 1.5× são constantes biológicas (Gabbett, 2016) — fixas.
    // Os valores em AU mudam por atleta conforme a base individual dele.
    final lastChronic =
        points
            .lastWhere((p) => p.cargaCronica != null, orElse: () => points.last)
            .cargaCronica;

    final recoveryLoad = lastChronic != null ? lastChronic * 0.8 : null;
    final riskLoad = lastChronic != null ? lastChronic * 1.5 : null;

    // ── Teto do eixo de volume ─────────────────────────────────────────────
    // Inclui o limiar de sobrecarga e o pico de volume + 10% de folga.
    final maxVolume = points.fold<double>(
      0,
      (m, p) => p.volume > m ? p.volume : m,
    );
    final maxIcn = points.fold<double>(0, (m, p) {
      final i = p.icn;
      return (i != null && i > m) ? i : m;
    });
    final maxY = [maxVolume, riskLoad ?? 0.0].reduce((a, b) => a > b ? a : b);
    var volumeCeiling =
        maxY > 0 ? ((maxY * 1.10) / 100).ceil() * 100.0 : 100.0;

    // Garante que TODOS os ICN dos pontos caibam dentro do icnCeiling
    // proporcional. Como icnCeiling = (volumeCeiling / cargaCronica) × 50,
    // para que maxIcn ≤ icnCeiling precisamos de
    //   volumeCeiling ≥ (maxIcn × cargaCronica) / 50.
    // Sem isso, semanas antigas com ICN próximo do clamp (≈150) saem fora
    // do gráfico quando a cargaCronica atual disparou em relação à da época
    // daquele ponto. O fator 1.10 garante folga vertical pra bolinha não
    // grudar no topo.
    if (lastChronic != null && lastChronic > 0 && maxIcn > 0) {
      final requiredCeiling = (maxIcn * lastChronic / 50.0) * 1.10;
      if (requiredCeiling > volumeCeiling) {
        volumeCeiling = (requiredCeiling / 100).ceil() * 100.0;
      }
    }

    // ── Teto DINÂMICO do eixo de ICN, proporcional ao eixo de volume ───────
    // Como ICN = (volume / cargaCronica) × 50:
    //   ICN=40 cai em 0.8×chronic, ICN=75 em 1.5×chronic, ICN=icnCeiling
    //   em volumeCeiling. As PlotBands coloridas (no eixo de volume) ficam
    //   visualmente trancadas com a linha de Evolução (no icnAxis).
    final icnCeiling =
        (lastChronic != null && lastChronic > 0)
            ? (volumeCeiling / lastChronic) * 50.0
            : 150.0;

    final avgVolume =
        points.isEmpty
            ? 0.0
            : points.map((p) => p.volume).reduce((a, b) => a + b) /
                points.length;

    // Zonas coloridas preenchidas no eixo esquerdo (primaryYAxis = volume AU).
    // shouldRenderAboveSeries: false (default) → ficam ATRÁS de tudo:
    //   z-order final: zonas (fundo) → barras → linha de Evolução → troféus.
    // Cold start (sem cargaCronica): nenhuma zona é desenhada; o gráfico
    // funciona normalmente sem fundo colorido.
    final bands = <PlotBand>[
      if (recoveryLoad != null)
        PlotBand(
          start: 0,
          end: recoveryLoad,
          color: _zoneRecoveryFill,
          borderWidth: 0,
        ),
      if (recoveryLoad != null && riskLoad != null)
        PlotBand(
          start: recoveryLoad,
          end: riskLoad,
          color: _zoneSafeFill,
          borderWidth: 0,
        ),
      if (riskLoad != null)
        PlotBand(
          start: riskLoad,
          end: volumeCeiling,
          color: _zoneRiskFill,
          borderWidth: 0,
        ),
    ];

    return SizedBox(
      height: _kChartHeight * scale,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,

        // Marcadores da linha de ICN mudam de cor conforme a zona do ponto.
        onMarkerRender: (MarkerRenderArgs args) {
          final idx = args.pointIndex;
          if (idx == null || idx < 0 || idx >= points.length) return;
          final icn = points[idx].icn;
          if (icn == null) return;
          args.color = _icnStatusColor(icn);
          args.borderColor = Colors.white;
        },

        primaryXAxis: CategoryAxis(
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: _kAxisLineSoft,
          labelStyle: _kAxisLabelStyle(scale),
          majorTickLines: const MajorTickLines(size: 0),
          labelRotation: -25,
        ),

        // Eixo esquerdo: Volume em AU, com linhas de fronteira dinâmicas.
        primaryYAxis: NumericAxis(
          minimum: 0,
          maximum: volumeCeiling,
          majorGridLines: _kGridLines,
          axisLine: const AxisLine(width: 0),
          labelStyle: _kAxisLabelStyle(scale),
          majorTickLines: const MajorTickLines(size: 0),
          labelFormat: '{value}',
          plotBands: bands,
        ),

        // Eixo direito: apenas para posicionar a linha de ICN internamente.
        // Labels totalmente ocultos — os valores visíveis estão no eixo esquerdo.
        axes: [
          NumericAxis(
            name: 'icnAxis',
            opposedPosition: true,
            minimum: 0,
            maximum: icnCeiling,
            axisLine: const AxisLine(width: 0),
            majorGridLines: const MajorGridLines(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            axisLabelFormatter: (args) => ChartAxisLabel('', args.textStyle),
          ),
        ],

        annotations: <CartesianChartAnnotation>[
          for (final p in points)
            if (p.hasPr && p.icn != null)
              CartesianChartAnnotation(
                coordinateUnit: CoordinateUnit.point,
                // chart (e não plotArea) evita que o troféu seja recortado
                // quando o ICN do ponto está perto do topo do eixo.
                region: AnnotationRegion.chart,
                x: p.label,
                y: p.icn!,
                yAxisName: 'icnAxis',
                horizontalAlignment: ChartAlignment.center,
                verticalAlignment: ChartAlignment.far,
                widget: Padding(
                  padding: EdgeInsets.only(bottom: 4 * scale),
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.amber.shade600,
                    size: 16 * scale,
                  ),
                ),
              ),
        ],

        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (data, point, series, pointIndex, seriesIndex) {
            if (data is! _AcwrPoint) return const SizedBox.shrink();
            final volLabel = _volumeQualitative(data.volume, avgVolume);
            final baseStr =
                data.cargaCronica != null
                    ? ' (base: ${data.cargaCronica!.toStringAsFixed(0)})'
                    : '';
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 6 * scale,
              ),
              decoration: BoxDecoration(
                color: AppColors.darkText,
                borderRadius: BorderRadius.circular(6 * scale),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Semana ${data.label}',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 10 * scale,
                      color: Colors.white.withValues(alpha: 0.80),
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    'Volume: $volLabel (${data.volume.toStringAsFixed(0)} pts$baseStr)',
                    style: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight: FontWeight.bold,
                      fontSize: 11 * scale,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3 * scale),
                  Text(
                    'Status: ${_icnStatusTooltip(data.icn)}',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.w600,
                      fontSize: 10.5 * scale,
                      color: Colors.white,
                    ),
                  ),
                  if (data.hasPr) ...[
                    SizedBox(height: 3 * scale),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 12 * scale,
                        ),
                        SizedBox(width: 4 * scale),
                        Text(
                          '${data.prCount} ${data.prCount == 1 ? "PR" : "PRs"} nesta semana',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontSize: 10 * scale,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        series: <CartesianSeries>[
          // Barras ao fundo (primeiro na pilha de renderização).
          ColumnSeries<_AcwrPoint, String>(
            dataSource: points,
            xValueMapper: (p, _) => p.label,
            yValueMapper: (p, _) => p.volume,
            name: 'Volume da Semana',
            color: const Color(0xFF94A3B8).withValues(alpha: 0.65),
            width: 0.55,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(3 * scale),
              topRight: Radius.circular(3 * scale),
            ),
          ),

          // Linha de ICN no topo (último na pilha = acima das barras e bands).
          // Marcadores coloridos por zona via onMarkerRender.
          LineSeries<_AcwrPoint, String>(
            dataSource: points,
            xValueMapper: (p, _) => p.label,
            yValueMapper: (p, _) => p.icn,
            yAxisName: 'icnAxis',
            name: 'Status do Corpo',
            color: AppColors.darkBlue,
            width: 2.5,
            markerSettings: MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              width: 7 * scale,
              height: 7 * scale,
              color: AppColors.darkBlue, // sobrescrito por onMarkerRender
              borderColor: Colors.white,
              borderWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Legenda da aba ACWR — linha azul + zonas + troféu de PR
// =============================================================================

class _AcwrLegend extends StatelessWidget {
  final double scale;
  const _AcwrLegend({required this.scale});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: AppFonts.roboto,
      fontSize: 10 * scale,
      color: AppColors.darkText,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10 * scale,
      runSpacing: 4 * scale,
      children: [
        // Linha azul — Evolução (linha principal de status do atleta)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18 * scale,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.darkBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 4 * scale),
            Text(
              'Evolução',
              style: textStyle.copyWith(
                color: AppColors.darkBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        // Zonas coloridas (fundo do gráfico)
        Text('🔵 Recuperação', style: textStyle),
        Text('🟢 Ideal', style: textStyle),
        Text('🔴 Sobrecarga', style: textStyle),
        // Troféu — semana com PR
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events,
              color: Colors.amber.shade600,
              size: 13 * scale,
            ),
            SizedBox(width: 4 * scale),
            Text('PR', style: textStyle),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// Aba PRs — linha-escada do recorde + narrativa
// =============================================================================

class _PrsEvolutionTab extends StatefulWidget {
  final DateTime from;
  final DateTime to;
  const _PrsEvolutionTab({required this.from, required this.to});

  @override
  State<_PrsEvolutionTab> createState() => _PrsEvolutionTabState();
}

class _PrsEvolutionTabState extends State<_PrsEvolutionTab> {
  late Future<List<AthletePr>> _future;
  String? _selectedMovementId;

  @override
  void initState() {
    super.initState();
    _future = AthletePrsService.fetchUserPrs();
  }

  @override
  void didUpdateWidget(_PrsEvolutionTab old) {
    super.didUpdateWidget(old);
    if (old.from != widget.from || old.to != widget.to) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 2 * scale),
      child: FutureBuilder<List<AthletePr>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return SizedBox(
              height: 300 * scale,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          final all = snap.data ?? const <AthletePr>[];
          if (all.isEmpty) {
            return _ChartCard(
              title: 'PROGRESSO POR MOVIMENTO',
              scale: scale,
              child: _EmptyMessage(
                text: 'Registre seu primeiro PR para ver sua evolução aqui.',
                scale: scale,
              ),
            );
          }

          // Agrupa por movimento
          final Map<String, _MovementGroup> groups = {};
          for (final pr in all) {
            final g = groups.putIfAbsent(
              pr.movementId,
              () => _MovementGroup(
                id: pr.movementId,
                name: pr.movementName,
                prType: pr.prType,
                unit: pr.unit,
              ),
            );
            g.prs.add(pr);
          }
          final sortedMovements =
              groups.values.toList()..sort((a, b) {
                final byCount = b.prs.length.compareTo(a.prs.length);
                if (byCount != 0) return byCount;
                return a.name.toLowerCase().compareTo(b.name.toLowerCase());
              });

          _selectedMovementId ??= sortedMovements.first.id;
          final selected = sortedMovements.firstWhere(
            (g) => g.id == _selectedMovementId,
            orElse: () => sortedMovements.first,
          );

          final fromDay = DateTime(
            widget.from.year,
            widget.from.month,
            widget.from.day,
          );
          final toDay = DateTime(
            widget.to.year,
            widget.to.month,
            widget.to.day,
            23,
            59,
            59,
          );
          final inRange =
              selected.prs
                  .where(
                    (pr) =>
                        !pr.date.isBefore(fromDay) && !pr.date.isAfter(toDay),
                  )
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date));

          return _ChartCard(
            title: 'PROGRESSO POR MOVIMENTO',
            scale: scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MovementPicker(
                  scale: scale,
                  movements: sortedMovements,
                  selectedId: selected.id,
                  onChanged: (id) => setState(() => _selectedMovementId = id),
                ),
                SizedBox(height: 10 * scale),
                if (inRange.isEmpty)
                  _EmptyMessage(
                    text: 'Sem PRs deste movimento no período selecionado.',
                    scale: scale,
                  )
                else ...[
                  _PrNarrativeHeader(
                    prs: inRange,
                    movementName: selected.name,
                    unit: selected.unit,
                    prType: selected.prType,
                    scale: scale,
                  ),
                  SizedBox(height: 8 * scale),
                  _PrSteppedLineChart(
                    prs: inRange,
                    from: fromDay,
                    to: widget.to,
                    unit: selected.unit,
                    prType: selected.prType,
                    scale: scale,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MovementGroup {
  final String id;
  final String name;
  final PrType prType;
  final String unit;
  final List<AthletePr> prs = [];

  _MovementGroup({
    required this.id,
    required this.name,
    required this.prType,
    required this.unit,
  });
}

class _MovementPicker extends StatelessWidget {
  final double scale;
  final List<_MovementGroup> movements;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _MovementPicker({
    required this.scale,
    required this.movements,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 2 * scale,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(8 * scale),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            size: 18 * scale,
            color: AppColors.darkText,
          ),
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontSize: 12 * scale,
            color: AppColors.darkText,
          ),
          items:
              movements
                  .map(
                    (g) => DropdownMenuItem(
                      value: g.id,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 6 * scale),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6 * scale,
                              vertical: 1 * scale,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.baseBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6 * scale),
                            ),
                            child: Text(
                              '${g.prs.length}',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontWeight: FontWeight.bold,
                                fontSize: 10 * scale,
                                color: AppColors.baseBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _PrNarrativeHeader extends StatelessWidget {
  final List<AthletePr> prs;
  final String movementName;
  final String unit;
  final PrType prType;
  final double scale;

  const _PrNarrativeHeader({
    required this.prs,
    required this.movementName,
    required this.unit,
    required this.prType,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final isTimeBased = prType == PrType.time;

    // Melhor PR no período (max ou min dependendo do tipo)
    final best =
        isTimeBased
            ? prs.map((p) => p.value).reduce((a, b) => a < b ? a : b)
            : prs.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    final first = prs.first.value;
    final delta = isTimeBased ? first - best : best - first;

    // Nome do movimento já está visível no dropdown acima → não repetir
    // na frase pra evitar truncamento quando o nome é longo.
    final String narrative;
    if (prs.length == 1) {
      narrative = 'Primeiro PR registrado: ${_fmt(best)} $unit.';
    } else if (delta.abs() < 0.05) {
      narrative =
          '${prs.length} PRs registrados — melhor marca: ${_fmt(best)} $unit.';
    } else if (delta > 0) {
      final fmtStart = DateFormat("d 'de' MMM", 'pt_BR');
      final period = fmtStart.format(prs.first.date);
      final verb = isTimeBased ? 'Você melhorou' : 'Você evoluiu';
      narrative = '$verb ${_fmt(delta)} $unit desde $period.';
    } else {
      narrative = 'Melhor marca no período: ${_fmt(best)} $unit.';
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          10 * scale,
          8 * scale,
          10 * scale,
          9 * scale,
        ),
        decoration: BoxDecoration(
          color: AppColors.baseBlue.withValues(alpha: 0.06),
          border: Border.all(color: AppColors.baseBlue.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2 * scale),
              child: Icon(
                Icons.trending_up,
                color: AppColors.baseBlue,
                size: 18 * scale,
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              // RichText bypassa qualquer DefaultTextStyle ancestral que
              // esteja forçando maxLines/overflow. Text herda esses valores
              // quando não são explicitamente setados — RichText não herda
              // nada e garante o comportamento esperado.
              child: RichText(
                softWrap: true,
                overflow: TextOverflow.visible,
                maxLines: 99,
                text: TextSpan(
                  text: narrative,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 11.5 * scale,
                    color: AppColors.darkText,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _PrSteppedLineChart extends StatelessWidget {
  final List<AthletePr> prs;
  final DateTime from;
  final DateTime to;
  final String unit;
  final PrType prType;
  final double scale;

  const _PrSteppedLineChart({
    required this.prs,
    required this.from,
    required this.to,
    required this.unit,
    required this.prType,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final isTimeBased = prType == PrType.time;

    // Constrói pontos com "isNewPr" marcando só onde a linha sobe.
    final List<_PrPoint> points = [];
    double? runningBest;
    for (final pr in prs) {
      bool isNew;
      if (runningBest == null) {
        runningBest = pr.value;
        isNew = true;
      } else {
        final improved =
            isTimeBased ? pr.value < runningBest : pr.value > runningBest;
        isNew = improved;
        if (improved) runningBest = pr.value;
      }
      points.add(_PrPoint(pr.date, runningBest, isNew, pr.value));
    }

    // Calcula intervalo do eixo X para evitar labels duplicadas.
    final totalDays = to.difference(from).inDays.clamp(1, 3650);
    final intervalDays = (totalDays / 4).ceil().toDouble();

    // Altura maior compensa a ausência de legenda nesta aba — os dois
    // cards (Volume e PRs) terminam com a mesma altura total.
    return SizedBox(
      height: _kPrChartHeight * scale,
      child: SfCartesianChart(
        margin: EdgeInsets.zero,
        plotAreaBorderWidth: 0,
        primaryXAxis: DateTimeAxis(
          minimum: from,
          maximum: to,
          intervalType: DateTimeIntervalType.days,
          interval: intervalDays,
          dateFormat: DateFormat('dd/MM'),
          majorGridLines: const MajorGridLines(width: 0),
          axisLine: _kAxisLineSoft,
          labelStyle: _kAxisLabelStyle(scale),
          majorTickLines: const MajorTickLines(size: 0),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: _kGridLines,
          axisLine: const AxisLine(width: 0),
          labelStyle: _kAxisLabelStyle(scale),
          majorTickLines: const MajorTickLines(size: 0),
          labelFormat: '{value} $unit',
        ),
        tooltipBehavior: TooltipBehavior(
          enable: true,
          builder: (data, point, series, pointIndex, seriesIndex) {
            if (data is! _PrPoint) return const SizedBox.shrink();
            final date = DateFormat("d 'de' MMM", 'pt_BR').format(data.date);
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 * scale,
                vertical: 6 * scale,
              ),
              decoration: BoxDecoration(
                color: AppColors.darkText,
                borderRadius: BorderRadius.circular(6 * scale),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_fmt(data.actual)} $unit',
                    style: TextStyle(
                      fontFamily: AppFonts.montserrat,
                      fontWeight: FontWeight.bold,
                      fontSize: 13 * scale,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    data.isNewPr ? '$date — novo PR!' : date,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontSize: 10 * scale,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        onMarkerRender: (args) {
          final idx = args.pointIndex;
          if (idx == null || idx >= points.length) return;
          final p = points[idx];
          final c = p.isNewPr ? AppColors.baseBlue : AppColors.mediumGray;
          args.color = c;
          args.borderColor = c;
          args.markerHeight = 10 * scale;
          args.markerWidth = 10 * scale;
        },
        series: <CartesianSeries>[
          LineSeries<_PrPoint, DateTime>(
            dataSource: points,
            xValueMapper: (p, _) => p.date,
            yValueMapper: (p, _) => p.actual,
            color: AppColors.baseBlue.withValues(alpha: 0.55),
            width: 2,
            name: 'Registros',
            markerSettings: MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.circle,
              borderWidth: 0,
            ),
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelAlignment: ChartDataLabelAlignment.middle,
              builder: (data, point, series, pointIndex, seriesIndex) {
                if (pointIndex >= points.length) {
                  return const SizedBox.shrink();
                }
                final current = points[pointIndex];
                final hasPrev = pointIndex > 0;
                final hasNext = pointIndex < points.length - 1;
                // A linha passa ACIMA do ponto atual se algum vizinho
                // (anterior ou próximo) tem valor MAIOR. Nesse caso o
                // rótulo vai ABAIXO pra não ser atravessado pela linha.
                // Caso contrário (pico, vale sem vizinho maior, único
                // ponto), rótulo vai acima.
                final prevHigher =
                    hasPrev && points[pointIndex - 1].actual > current.actual;
                final nextHigher =
                    hasNext && points[pointIndex + 1].actual > current.actual;
                final labelBelow = prevHigher || nextHigher;
                return Transform.translate(
                  offset: Offset(0, labelBelow ? 14 * scale : -14 * scale),
                  child: Text(
                    _fmt(current.actual),
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.w600,
                      fontSize: 9 * scale,
                      color: AppColors.darkText,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double v) {
    if (v % 1 == 0) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _PrPoint {
  final DateTime date;
  final double runningBest;
  final bool isNewPr;
  final double actual;
  _PrPoint(this.date, this.runningBest, this.isNewPr, this.actual);
}

// =============================================================================
// Componentes compartilhados
// =============================================================================

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double scale;
  final String? subtitle;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
    required this.scale,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(7 * scale, 6 * scale, 7 * scale, 7 * scale),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      // Ocupa toda a altura disponível para casar com os outros cards
      // quando embrulhados em IntrinsicHeight pelo caller.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: FontWeight.bold,
              fontSize: 8.5 * scale,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.montserrat,
              fontWeight: FontWeight.bold,
              fontSize: 13 * scale,
              color: AppColors.darkText,
              height: 1,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 3 * scale),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 8 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final double scale;
  final Widget child;
  final Widget? trailing;

  const _ChartCard({
    required this.title,
    required this.scale,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 3 * scale),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(14 * scale),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          10 * scale,
          8 * scale,
          10 * scale,
          9 * scale,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.5 * scale,
                      color: AppColors.darkBlue,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            SizedBox(height: 8 * scale),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  final double scale;
  const _EmptyMessage({required this.text, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scale,
        vertical: 20 * scale,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppFonts.roboto,
          fontSize: 11.5 * scale,
          color: AppColors.mediumGray,
        ),
      ),
    );
  }
}
