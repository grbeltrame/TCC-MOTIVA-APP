import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/workout/muscles_service.dart';
import 'package:flutter_app/shared/models/training_block.dart';
import 'package:flutter_app/shared/models/worked_muscle.dart';

class WorkedMusclesSection extends StatefulWidget {
  final TrainingBlock lastBlock;

  const WorkedMusclesSection({Key? key, required this.lastBlock})
    : super(key: key);

  @override
  State<WorkedMusclesSection> createState() => _WorkedMusclesSectionState();
}

class _WorkedMusclesSectionState extends State<WorkedMusclesSection> {
  late Future<List<WorkedMuscle>> _fut;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _fut = MusclesService.fetchWorkedMusclesForLastBlock(widget.lastBlock);
  }

  @override
  void didUpdateWidget(covariant WorkedMusclesSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Se mudou o bloco (dia/tipo), refaz o fetch e reseta o carrossel
    if (oldWidget.lastBlock.id != widget.lastBlock.id) {
      setState(() {
        _index = 0;
        _fut = MusclesService.fetchWorkedMusclesForLastBlock(widget.lastBlock);
      });
    }
  }

  void _prev(int len) => setState(
    () => _index = (_index - 1) % len < 0 ? len - 1 : (_index - 1) % len,
  );
  void _next(int len) => setState(() => _index = (_index + 1) % len);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<List<WorkedMuscle>>(
      future: _fut,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final list = snap.data ?? const <WorkedMuscle>[];
        if (list.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 8 * scale,
            ),
            child: Text(
              'Sem dados para este movimento',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                color: AppColors.mediumGray,
                fontSize: 12 * scale,
              ),
            ),
          );
        }

        if (_index >= list.length) _index = 0;
        final item = list[_index];

        return Padding(
          padding: EdgeInsets.fromLTRB(12 * scale, 12 * scale, 12 * scale, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Músculos Trabalhados:',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 18 * scale,
                  color: AppColors.darkText,
                ),
              ),
              SizedBox(height: 8 * scale),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _prev(list.length),
                  ),
                  SizedBox(width: 6 * scale),
                  Flexible(
                    child: Text(
                      item.muscle,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.montserrat,
                        fontWeight: AppFontWeight.bold,
                        fontSize: 16 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  SizedBox(width: 6 * scale),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _next(list.length),
                  ),
                ],
              ),

              SizedBox(height: 8 * scale),

              LayoutBuilder(
                builder: (_, constraints) {
                  final maxW = constraints.maxWidth.clamp(0.0, 390.0);
                  final imgs = item.imageAssetPaths;

                  final isTwoCols = imgs.length >= 2;
                  final spacing = 8 * scale;

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child:
                          isTwoCols
                              ? Row(
                                children: [
                                  Expanded(child: _ImageCard(path: imgs[0])),
                                  SizedBox(width: spacing),
                                  Expanded(
                                    child: _ImageCard(
                                      path: imgs.length > 1 ? imgs[1] : imgs[0],
                                    ),
                                  ),
                                ],
                              )
                              : _ImageCard(path: imgs.first),
                    ),
                  );
                },
              ),

              SizedBox(height: 12 * scale),

              Text(
                'Movimento: ${item.movement}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontSize: 12 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.mediumGray),
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder:
              (_, __, ___) => Center(
                child: Text(
                  'Imagem não encontrada',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    color: AppColors.mediumGray,
                    fontSize: 12 * scale,
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
