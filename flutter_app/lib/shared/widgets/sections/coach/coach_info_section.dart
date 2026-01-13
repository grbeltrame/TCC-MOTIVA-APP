// lib/shared/widgets/sections/coach/coach_info_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/users/coach/coach_service.dart';
import 'package:flutter_app/routes/app_routes.dart';
import 'package:flutter_app/shared/models/coach_profile.dart';
import 'package:flutter_app/shared/widgets/utils/icon_text_action_button.dart';

/// Card de informações do COACH (professor), baseado no AthleteInfoSection.
/// Alterações:
/// - "Categoria"  -> "CREF:" (chip com ícone e valor/CTA)
/// - "Perfil Referência" -> "Especialidades:" (lista simples)
/// - "Boxes Cadastrados" -> "Certificações:" (lista simples)
/// - Mantém botão "Editar Perfil"
/// - Remove botão "Cadastrar Box" (ficam só dois botões: Completar Perfil / Configurações)
/// - Barra de progresso considerando: CREF, 1+ especialidade, 1+ certificação
class CoachInfoSection extends StatefulWidget {
  const CoachInfoSection({super.key});

  @override
  State<CoachInfoSection> createState() => _CoachInfoSectionState();
}

class _CoachInfoSectionState extends State<CoachInfoSection> {
  late Future<CoachProfile> _futProfile;

  @override
  void initState() {
    super.initState();
    _futProfile = CoachService.fetchCoachProfile(); // mock
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<CoachProfile>(
      future: _futProfile,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = snap.data!;

        // progresso: 3 pontos (CREF, Especialidades, Certificações)
        int filled = 0;
        if ((profile.cref ?? '').trim().isNotEmpty) filled++;
        if (profile.specialties.isNotEmpty) filled++;
        if (profile.certifications.isNotEmpty) filled++;
        const total = 3;
        final pct = filled / total;

        final btnReserve = 128 * scale;

        final editBtn = OutlinedButton.icon(
          onPressed: () async {
            final changed = await Navigator.of(
              context,
            ).pushNamed(AppRoutes.coachProfileEdit);

            if (changed == true) {
              setState(() {
                _futProfile =
                    CoachService.fetchCoachProfile(); // ou o service real do coach
              });
            }
          },

          icon: Icon(Icons.edit, size: 14 * scale, color: AppColors.baseBlue),
          label: Text(
            'Editar Perfil',
            style: TextStyle(fontSize: 10 * scale, color: AppColors.baseBlue),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: 4 * scale,
              vertical: 12 * scale,
            ),
            minimumSize: const Size(0, 0),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: AppColors.baseBlue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8 * scale),
            ),
          ),
        );

        return Container(
          margin: EdgeInsets.symmetric(vertical: 16 * scale),
          padding: EdgeInsets.symmetric(
            vertical: 16 * scale,
            horizontal: 6 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.mediumGray),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 28 * scale,
                        backgroundImage:
                            profile.photoUrl != null
                                ? NetworkImage(profile.photoUrl!)
                                : null,
                        child:
                            profile.photoUrl == null
                                ? Icon(Icons.person, size: 28 * scale)
                                : null,
                      ),
                      SizedBox(width: 6 * scale),

                      // Nome + CREF
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome com espaço reservado pro botão
                            Padding(
                              padding: EdgeInsets.only(right: btnReserve),
                              child: Text(
                                profile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppFonts.roboto,
                                  fontWeight: AppFontWeight.bold,
                                  fontSize: 18 * scale,
                                  color: AppColors.darkText,
                                ),
                              ),
                            ),
                            SizedBox(height: 4 * scale),

                            // CREF
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6 * scale,
                                    vertical: 2 * scale,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.lightBlue.withAlpha(50),
                                    borderRadius: BorderRadius.circular(
                                      8 * scale,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.badge_outlined,
                                        size: 16 * scale,
                                        color: AppColors.darkBlue,
                                      ),
                                      SizedBox(width: 4 * scale),
                                      Text(
                                        'CREF:',
                                        style: TextStyle(
                                          fontFamily: AppFonts.roboto,
                                          fontWeight: AppFontWeight.bold,
                                          fontSize: 12 * scale,
                                          color: AppColors.darkBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 6 * scale),

                                // Valor/CTA
                                Expanded(
                                  child:
                                      ((profile.cref ?? '').trim().isNotEmpty)
                                          ? Text(
                                            profile.cref!,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12 * scale,
                                              color: AppColors.darkText,
                                            ),
                                          )
                                          : Align(
                                            alignment: Alignment.centerLeft,
                                            child: IconTextActionButton(
                                              text: 'Complete seu perfil',
                                              iconData: Icons.add,
                                              fontSize: 12 * scale,
                                              onPressed: () {
                                                // TODO: editar/complete
                                              },
                                            ),
                                          ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(top: 0, right: 0, child: editBtn),
                ],
              ),

              SizedBox(height: 16 * scale),

              // Blocos: Especialidades / Certificações
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Especialidades
                  Expanded(
                    child: _LabeledListBlock(
                      scale: scale,
                      icon: Icons.workspace_premium_outlined,
                      label: 'Especialidades:',
                      items: profile.specialties,
                      emptyCta: () {
                        // TODO: editar especialidades
                      },
                    ),
                  ),
                  SizedBox(width: 18 * scale),

                  // Certificações
                  Expanded(
                    child: _LabeledListBlock(
                      scale: scale,
                      icon: Icons.verified_outlined,
                      label: 'Certificações:',
                      items: profile.certifications,
                      emptyCta: () {
                        // TODO: editar certificações
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24 * scale),

              // Barra de progresso
              if (pct < 1.0) ...[
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Status do Perfil: ',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.bold,
                          fontSize: 14 * scale,
                          color: AppColors.baseBlue,
                        ),
                      ),
                      TextSpan(
                        text: '${(pct * 100).round()}% completo',
                        style: TextStyle(
                          fontFamily: AppFonts.roboto,
                          fontWeight: AppFontWeight.regular,
                          fontSize: 14 * scale,
                          color: AppColors.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4 * scale),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4 * scale),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6 * scale,
                          backgroundColor: AppColors.lightGray,
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.baseBlue,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Text(
                      '${(pct * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 16 * scale),

              // Botões de ação (sem "Cadastrar Box")
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (pct < 1.0) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: editar/complete
                      },
                      icon: Icon(
                        Icons.edit,
                        size: 14 * scale,
                        color: AppColors.baseBlue,
                      ),
                      label: Text(
                        'Completar Perfil',
                        style: TextStyle(
                          fontSize: 11 * scale,
                          color: AppColors.baseBlue,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * scale,
                          vertical: 1 * scale,
                        ),
                        side: const BorderSide(color: AppColors.baseBlue),
                        backgroundColor: AppColors.lightBlue.withAlpha(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8 * scale),
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    SizedBox(width: 6 * scale),
                  ],
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: configurações do coach
                    },
                    icon: Icon(
                      Icons.settings,
                      size: 14 * scale,
                      color: AppColors.baseBlue,
                    ),
                    label: Text(
                      'Configurações',
                      style: TextStyle(
                        fontSize: 11 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6 * scale,
                        vertical: 1 * scale,
                      ),
                      side: const BorderSide(color: AppColors.baseBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bloco reutilizável (rótulo com chip + lista de itens ou CTA "Complete seu perfil")
class _LabeledListBlock extends StatelessWidget {
  final double scale;
  final IconData icon;
  final String label;
  final List<String> items;
  final VoidCallback emptyCta;

  const _LabeledListBlock({
    required this.scale,
    required this.icon,
    required this.label,
    required this.items,
    required this.emptyCta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // “chip” de título
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 6 * scale,
            vertical: 2 * scale,
          ),
          decoration: BoxDecoration(
            color: AppColors.lightBlue.withAlpha(50),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16 * scale, color: AppColors.darkBlue),
              SizedBox(width: 4 * scale),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 12 * scale,
                  color: AppColors.darkBlue,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 4 * scale),

        if (items.isEmpty)
          IconTextActionButton(
            text: 'Complete seu perfil',
            iconData: Icons.add,
            fontSize: 12 * scale,
            onPressed: emptyCta,
          )
        else
          _BulletList(items: items, scale: scale),
      ],
    );
  }
}

/// Lista simples com marcadores (“• item”)
class _BulletList extends StatelessWidget {
  final List<String> items;
  final double scale;

  const _BulletList({required this.items, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          items
              .map(
                (t) => Padding(
                  padding: EdgeInsets.only(bottom: 2 * scale),
                  child: Text(
                    '• $t',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 13 * scale,
                      fontFamily: AppFonts.roboto,
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}
