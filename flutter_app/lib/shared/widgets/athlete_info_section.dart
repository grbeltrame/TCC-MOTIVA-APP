// lib/shared/widgets/athlete_info_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/athlete_service.dart';
import 'package:flutter_app/shared/models/athlete_profile.dart';
import 'package:flutter_app/shared/widgets/icon_text_action_button.dart';
import 'package:flutter_app/shared/widgets/text_action_button.dart';
import 'package:flutter_app/shared/widgets/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/box_signup_coach.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

/// Seção de informações do perfil do atleta:
/// • Container com borda arredondada
/// • Foto, nome, categoria e botão Editar Perfil
/// • Blocos: Perfil Referência, Boxes cadastrados
/// • Barra de progresso e botões de ação
class AthleteInfoSection extends StatefulWidget {
  const AthleteInfoSection({Key? key}) : super(key: key);

  @override
  State<AthleteInfoSection> createState() => _AthleteInfoSectionState();
}

class _AthleteInfoSectionState extends State<AthleteInfoSection> {
  late Future<AthleteProfile> _futProfile;

  @override
  void initState() {
    super.initState();
    _futProfile =
        AthleteService.fetchAthleteProfile(); // TODO: implementar fetch real
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<AthleteProfile>(
      future: _futProfile,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = snap.data!;

        // calcula % de perfil completo
        int filled = 0;
        if (profile.category != null) filled++;
        if (profile.reference != null) filled++;
        if (profile.boxes.isNotEmpty) filled++;
        const total = 3;
        final pct = filled / total;

        return Container(
          margin: EdgeInsets.symmetric(vertical: 16 * scale),
          padding: EdgeInsets.symmetric(
            vertical: 16 * scale,
            horizontal: 4 * scale,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.mediumGray),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Foto + Nome + Categoria (label + valor/CTA) + Editar Perfil ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto do atleta
                  CircleAvatar(
                    radius: 32 * scale,
                    backgroundImage:
                        profile.photoUrl != null
                            ? NetworkImage(profile.photoUrl!)
                            : null,
                    child:
                        profile.photoUrl == null
                            ? Icon(Icons.person, size: 32 * scale)
                            : null,
                  ),
                  SizedBox(width: 12 * scale),
                  // Nome e Categoria em duas linhas
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome
                        Text(
                          profile.name,
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.bold,
                            fontSize: 20 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        // Categoria: label + valor ou CTA
                        Row(
                          children: [
                            Text(
                              'Categoria:',
                              style: TextStyle(
                                fontFamily: AppFonts.roboto,
                                fontWeight: AppFontWeight.bold,
                                fontSize: 12 * scale,
                                color: AppColors.darkText,
                              ),
                            ),
                            SizedBox(width: 6 * scale),
                            if (profile.category != null)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8 * scale,
                                  vertical: 2 * scale,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray,
                                  borderRadius: BorderRadius.circular(
                                    8 * scale,
                                  ),
                                ),
                                child: Text(
                                  profile.category!,
                                  style: TextStyle(
                                    fontSize: 12 * scale,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              )
                            else
                              IconTextActionButton(
                                text: 'Complete seu perfil',
                                iconData: Icons.add,
                                fontSize: 12 * scale,
                                onPressed: () {
                                  // TODO: navegar para completar perfil
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Botão Editar Perfil
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: navegar para editar perfil
                    },
                    icon: Icon(
                      Icons.edit,
                      size: 16 * scale,
                      color: AppColors.baseBlue,
                    ),
                    label: Text(
                      'Editar Perfil',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6 * scale,
                        vertical: 1 * scale,
                      ),
                      side: BorderSide(color: AppColors.baseBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16 * scale),

              // ─── Blocos de informação (Perfil Referência, Boxes) ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Perfil de Referência
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfil de Referência:',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.bold,
                            fontSize: 12 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        if (profile.reference != null) ...[
                          Text(profile.reference!.gender),
                          Text(profile.reference!.ageRange),
                          Text(profile.reference!.weightRange),
                          Text(profile.reference!.practiceYears),
                          Text(profile.reference!.heightRange),
                        ] else
                          IconTextActionButton(
                            text: 'Complete seu perfil',
                            iconData: Icons.add,
                            fontSize: 12 * scale,
                            onPressed: () {
                              // TODO: navegar para completar perfil
                            },
                          ),
                      ],
                    ),
                  ),

                  SizedBox(width: 12 * scale),

                  // Boxes cadastrados
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Boxes Cadastrados:',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.bold,
                            fontSize: 12 * scale,
                            color: AppColors.darkText,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        if (profile.boxes.isNotEmpty)
                          Text(profile.boxes.join(', '))
                        else
                          TextActionButton(
                            text: 'Cadastrar-se em um box',
                            icon: Icons.add,
                            onPressed:
                                () => showAppBottomSheet(
                                  context,
                                  const BoxSignupCoach(),
                                ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16 * scale),

              // ─── Barra de progresso ───
              Text(
                'Status do perfil: ${(pct * 100).round()}% completo',
                style: TextStyle(fontSize: 12 * scale),
              ),
              SizedBox(height: 4 * scale),
              ClipRRect(
                borderRadius: BorderRadius.circular(4 * scale),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6 * scale,
                  backgroundColor: AppColors.lightGray,
                  valueColor: AlwaysStoppedAnimation(AppColors.baseBlue),
                ),
              ),

              SizedBox(height: 16 * scale),

              // ─── Botões de ação ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (pct < 1.0) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: navegar para completar perfil
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
                        side: BorderSide(color: AppColors.baseBlue),
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
                    onPressed:
                        () =>
                            showAppBottomSheet(context, const BoxSignupCoach()),
                    icon: Icon(
                      Icons.add,
                      size: 14 * scale,
                      color: AppColors.baseBlue,
                    ),
                    label: Text(
                      'Cadastrar Box',
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
                      side: BorderSide(color: AppColors.baseBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  SizedBox(width: 6 * scale),
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: navegar para configurações gerais
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
                      side: BorderSide(color: AppColors.baseBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8 * scale),
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),

              SizedBox(
                height: 24 * scale,
              ), // espaçamento para a próxima section
            ],
          ),
        );
      },
    );
  }
}
