import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/effort_service.dart';

/// Paleta dinâmica para o slider de esforço
class _EffortPalette {
  final Color active; // trilho à esquerda do thumb
  final Color inactive; // trilho à direita do thumb
  final Color thumb; // bolinha
  final Color overlay; // ripple ao segurar
  const _EffortPalette({
    required this.active,
    required this.inactive,
    required this.thumb,
    required this.overlay,
  });
}

class SectionEffort extends StatefulWidget {
  const SectionEffort({super.key, required this.classId, this.onEffortChanged});

  /// Turma selecionada (pode ser null).
  final String? classId;

  /// Notifica o orquestrador do valor (1..10).
  final ValueChanged<int>? onEffortChanged;

  @override
  State<SectionEffort> createState() => _SectionEffortState();
}

class _SectionEffortState extends State<SectionEffort> {
  final _service = EffortService();
  int _effort = 5;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDefault();
  }

  Future<void> _loadDefault() async {
    setState(() => _loading = true);
    try {
      final def = await _service.fetchDefaultEffort();
      final clamped = def.clamp(1, 10);
      _effort = clamped is int ? clamped : (clamped as num).toInt();
      widget.onEffortChanged?.call(_effort);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  _EffortPalette _palette(BuildContext context) {
    // cores base do app
    final neutral = AppColors.mediumGray;
    final inactive = AppColors.lightGray;
    final blue = AppColors.darkBlue;
    final red = Theme.of(context).colorScheme.error;

    if (_effort < 5) {
      return _EffortPalette(
        active: blue,
        inactive: inactive,
        thumb: blue,
        overlay: blue.withValues(alpha: 0.15),
      );
    } else if (_effort == 5) {
      return _EffortPalette(
        active: neutral,
        inactive: inactive,
        thumb: neutral,
        overlay: neutral.withValues(alpha: 0.15),
      );
    } else {
      return _EffortPalette(
        active: red,
        inactive: inactive,
        thumb: red,
        overlay: red.withValues(alpha: 0.15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16 * scale),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final palette = _palette(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          'Como você define sua percepção de esforço?',
          style: TextStyle(
            fontFamily: AppFonts.montserrat,
            fontWeight: AppFontWeight.bold,
            fontSize: 16 * scale,
            color: AppColors.darkText,
          ),
        ),
        SizedBox(height: 10 * scale),

        SizedBox(height: 6 * scale),

        // Slider 1..10 com cores dinâmicas (azul <5, cinza =5, vermelho >5)
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: palette.active,
            inactiveTrackColor: palette.inactive,
            thumbColor: palette.thumb,
            overlayColor: palette.overlay,
            trackHeight: 4 * scale,
          ),
          child: Slider(
            value: _effort.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$_effort', // exibe 1,2,3… (sem "/10")
            onChanged: (v) {
              setState(() => _effort = v.round());
              widget.onEffortChanged?.call(_effort);
            },
          ),
        ),

        // Labels (esquerda, centro, direita)
        Padding(
          padding: EdgeInsets.only(top: 2 * scale),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Me sinto bem para seguir meu dia',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.darkText.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Foi ruim mas foi bom',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.darkText.withValues(alpha: 0.9),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Minha alma me abandonou no meio do WOD',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.darkText.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
