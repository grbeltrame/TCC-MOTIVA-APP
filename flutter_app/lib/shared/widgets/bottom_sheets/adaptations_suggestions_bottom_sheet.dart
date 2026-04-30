import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/adaptation_service.dart';
import 'package:flutter_app/core/theme/app_theme.dart';
import 'package:flutter_app/shared/widgets/carousels/highlights_carousel.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';

import 'package:flutter_app/core/services/insights_service.dart';
import 'package:flutter_app/shared/models/inisght_model.dart';

Future<void> showAdaptationSuggestionsBottomSheet(
  BuildContext context, {
  required String category,
  String? wodName,
  required Future<void> Function() onTapRegister,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => _AdaptationsSheet(
          category: category,
          wodName: wodName,
          onTapRegister: onTapRegister,
        ),
  );
}

class _AdaptationsSheet extends StatefulWidget {
  const _AdaptationsSheet({
    required this.category,
    this.wodName,
    required this.onTapRegister,
  });

  final String category;
  final String? wodName;
  final Future<void> Function() onTapRegister;

  @override
  State<_AdaptationsSheet> createState() => _AdaptationsSheetState();
}

class _AdaptationsSheetState extends State<_AdaptationsSheet> {
  final _svc = AdaptationsService();
  final _insSvc = InsightsService();

  bool _loading = true;
  AdaptationSuggestion? _suggestion;

  late Future<List<InsightsModel>> _insightsFut;

  @override
  void initState() {
    super.initState();
    _insightsFut = _insSvc.fetchAdaptationInsights(
      category: widget.category,
      wodName: widget.wodName,
    );
    _load();
  }

  Future<void> _load() async {
    final s = await _svc.fetchSuggestions(
      category: widget.category,
      wodName: widget.wodName,
    );
    if (!mounted) return;
    setState(() {
      _suggestion = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return AppBottomSheet(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16 * scale,
          12 * scale,
          16 * scale,
          18 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40 * scale,
                height: 4 * scale,
                decoration: BoxDecoration(
                  color: AppColors.mediumGray.withOpacity(.6),
                  borderRadius: BorderRadius.circular(2 * scale),
                ),
              ),
            ),
            SizedBox(height: 12 * scale),

            Text(
              'Adaptações Sugeridas',
              style: TextStyle(
                fontFamily: AppFonts.montserrat,
                fontWeight: AppFontWeight.bold,
                fontSize: 18 * scale,
                color: AppColors.darkText,
              ),
            ),
            SizedBox(height: 2 * scale),
            Text(
              'Com base nos seus registros:',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
            SizedBox(height: 10 * scale),

            if (_loading)
              _HeaderSkeleton(scale: scale)
            else
              _HeaderSuggestion(
                scale: scale,
                s: _suggestion!,
                category: widget.category,
              ),

            SizedBox(height: 10 * scale),

            if (_loading)
              _LinesSkeleton(scale: scale)
            else
              ..._suggestion!.lines.map(
                (l) => _AdaptationLineRow(scale: scale, line: l),
              ),

            SizedBox(height: 16 * scale),

            Text(
              'Análise inteligente',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 6 * scale),

            FutureBuilder<List<InsightsModel>>(
              future: _insightsFut,
              builder: (ctx, snap) {
                final data = snap.data ?? const <InsightsModel>[];
                if (data.isEmpty) return _InsightsSkeleton(scale: scale);

                final highlights =
                    data
                        .map(
                          (i) =>
                              HighlightModel(type: i.type, message: i.message),
                        )
                        .toList();
                final enabled = data.map((i) => i.type).toSet();

                return HighlightsCarousel(
                  allHighlights: highlights,
                  enabledHighlightsTypes: enabled,
                );
              },
            ),

            SizedBox(height: 14 * scale),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: AppTheme.secondaryButtonStyle(
                    AppColors.darkBlue,
                    AppColors.baseBlue,
                  ),
                  onPressed: () async {
                    await widget.onTapRegister();
                    if (!mounted) return;
                    Navigator.of(context).pop();
                  },
                  child: const Text('Registrar'),
                ),
                OutlinedButton(
                  style: AppTheme.tertiaryButtonStyle(AppColors.baseMagenta),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// —— UI helpers / skeletons (iguais ao anterior) ——

class _HeaderSuggestion extends StatelessWidget {
  const _HeaderSuggestion({
    required this.scale,
    required this.s,
    required this.category,
  });
  final double scale;
  final AdaptationSuggestion s;
  final String category;

  @override
  Widget build(BuildContext context) {
    if (category != 'WOD') return const SizedBox.shrink();

    Widget pill(String value, {String? suffix}) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 4 * scale,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.mediumGray),
          borderRadius: BorderRadius.circular(6 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 14 * scale,
                color: AppColors.darkText,
              ),
            ),
            if (suffix != null) ...[
              SizedBox(width: 4 * scale),
              Text(
                suffix,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 12 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (s.mode == AdaptationMode.forTime && s.timeSec != null) {
      final min = (s.timeSec! ~/ 60).toString();
      final sec = (s.timeSec! % 60).toString();
      return Row(
        children: [
          pill(min, suffix: 'min'),
          SizedBox(width: 8 * scale),
          pill(sec, suffix: 's'),
        ],
      );
    }
    if (s.mode == AdaptationMode.amrap) {
      return Row(
        children: [
          pill('${s.amrapRounds ?? 0}', suffix: 'rounds'),
          SizedBox(width: 8 * scale),
          pill('${s.amrapReps ?? 0}', suffix: 'reps'),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _AdaptationLineRow extends StatelessWidget {
  const _AdaptationLineRow({required this.scale, required this.line});
  final double scale;
  final AdaptationLine line;

  Widget _pill(String value, {String? suffix, bool expanded = false}) {
    final inner = Container(
      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.mediumGray),
        borderRadius: BorderRadius.circular(6 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 14 * scale,
              color: AppColors.darkText,
            ),
          ),
          if (suffix != null) ...[
            SizedBox(width: 4 * scale),
            Text(
              suffix,
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontSize: 12 * scale,
                color: AppColors.mediumGray,
              ),
            ),
          ],
        ],
      ),
    );
    return expanded ? Expanded(child: inner) : inner;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8 * scale),
      child: Row(
        children: [
          if (line.quantity != null) _pill('${line.quantity}'),
          SizedBox(width: 6 * scale),
          _pill(line.movement, expanded: true),
          if (line.loadKg != null) ...[
            SizedBox(width: 6 * scale),
            _pill(
              '${line.loadKg!.toStringAsFixed(line.loadKg! % 1 == 0 ? 0 : 1)}',
              suffix: 'kg',
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton({required this.scale});
  final double scale;
  Widget _bar(double w) => Container(
    width: w * scale,
    height: 24 * scale,
    decoration: BoxDecoration(
      color: AppColors.lightGray,
      borderRadius: BorderRadius.circular(6 * scale),
    ),
  );
  @override
  Widget build(BuildContext context) =>
      Row(children: [_bar(70), SizedBox(width: 8 * scale), _bar(50)]);
}

class _LinesSkeleton extends StatelessWidget {
  const _LinesSkeleton({required this.scale});
  final double scale;
  Widget _row() => Row(
    children: [
      Container(
        height: 32 * scale,
        width: 48 * scale,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(6 * scale),
        ),
      ),
      SizedBox(width: 6 * scale),
      Expanded(
        child: Container(
          height: 32 * scale,
          decoration: BoxDecoration(
            color: AppColors.lightGray,
            borderRadius: BorderRadius.circular(6 * scale),
          ),
        ),
      ),
      SizedBox(width: 6 * scale),
      Container(
        height: 32 * scale,
        width: 56 * scale,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          borderRadius: BorderRadius.circular(6 * scale),
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) =>
      Column(children: [_row(), SizedBox(height: 6 * scale), _row()]);
}

class _InsightsSkeleton extends StatelessWidget {
  const _InsightsSkeleton({required this.scale});
  final double scale;
  @override
  Widget build(BuildContext context) => Container(
    height: 72 * scale,
    decoration: BoxDecoration(
      color: AppColors.lightGray,
      borderRadius: BorderRadius.circular(12 * scale),
    ),
  );
}
