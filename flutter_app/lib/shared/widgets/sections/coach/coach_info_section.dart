// lib/shared/widgets/sections/coach/coach_info_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/models/coach_profile.dart';
import 'package:flutter_app/shared/widgets/utils/icon_text_action_button.dart';
import 'package:flutter_app/features/user/coach/edit_profile_coach_screen.dart';
import 'package:flutter_app/routes/app_routes.dart';

class CoachInfoSection extends StatelessWidget {
  final CoachProfileEditable profile;
  final VoidCallback? onRefreshRequest;

  const CoachInfoSection({
    super.key,
    required this.profile,
    this.onRefreshRequest,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    // Lógica de Progresso
    int filled = 0;
    if ((profile.cref ?? '').trim().isNotEmpty) filled++;
    if (profile.specialties.isNotEmpty) filled++;
    if (profile.certifications.isNotEmpty) filled++;
    const total = 3;
    final pct = filled / total;

    final btnReserve = 128 * scale;

    // ✅ CORREÇÃO DO ERRO DE IMAGEM:
    // Verificamos se não é nulo E TAMBÉM se não é vazio.
    final hasValidPhoto =
        profile.photoUrl != null && profile.photoUrl!.isNotEmpty;

    void goToEdit() async {
      final changed = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EditProfileCoachScreen()),
      );

      if (changed == true && onRefreshRequest != null) {
        onRefreshRequest!();
      }
    }

    final editBtn = OutlinedButton.icon(
      onPressed: goToEdit,
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
          // CABEÇALHO
          Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ FOTO COM A PROTEÇÃO APLICADA
                  CircleAvatar(
                    radius: 28 * scale,
                    backgroundColor: AppColors.lightGray,
                    backgroundImage:
                        hasValidPhoto ? NetworkImage(profile.photoUrl!) : null,
                    child:
                        !hasValidPhoto
                            ? Icon(
                              Icons.person,
                              size: 28 * scale,
                              color: AppColors.mediumGray,
                            )
                            : null,
                  ),
                  SizedBox(width: 6 * scale),

                  // Nome + CREF
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: btnReserve),
                          child: Text(
                            profile.name.isEmpty ? 'Coach' : profile.name,
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

                        Row(
                          children: [
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
                                          onPressed: goToEdit,
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

          // BLOCOS
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _LabeledListBlock(
                  scale: scale,
                  icon: Icons.workspace_premium_outlined,
                  label: 'Especialidades:',
                  items: profile.specialties,
                  emptyCta: goToEdit,
                ),
              ),
              SizedBox(width: 18 * scale),
              Expanded(
                child: _LabeledListBlock(
                  scale: scale,
                  icon: Icons.verified_outlined,
                  label: 'Certificações:',
                  items: profile.certifications,
                  emptyCta: goToEdit,
                ),
              ),
            ],
          ),

          SizedBox(height: 24 * scale),

          // BARRA DE PROGRESSO
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

          // BOTÕES INFERIORES
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (pct < 1.0) ...[
                OutlinedButton.icon(
                  onPressed: goToEdit,
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
                  Navigator.pushNamed(context, AppRoutes.coachSettings);
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
  }
}

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
