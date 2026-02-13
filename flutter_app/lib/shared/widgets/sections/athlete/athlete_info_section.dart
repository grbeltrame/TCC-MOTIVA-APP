// lib/shared/widgets/athlete_info_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/users/athlete/athlete_service.dart';
import 'package:flutter_app/shared/models/athlete_profile.dart';
import 'package:flutter_app/shared/widgets/utils/icon_text_action_button.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_svg/svg.dart';

import 'package:flutter_app/features/user/athlete/athlete_edit_profile_screen.dart';
import 'package:flutter_app/routes/app_routes.dart';

/// Seção de informações do perfil do atleta:
/// • Container com borda arredondada
/// • Foto, nome, categoria e botão Editar Perfil (posicionado)
/// • Bloco: Perfil Referência
/// • Barra de progresso e botões de ação
class AthleteInfoSection extends StatefulWidget {
  final VoidCallback? onRefreshRequest;

  const AthleteInfoSection({Key? key, this.onRefreshRequest}) : super(key: key);

  @override
  State<AthleteInfoSection> createState() => _AthleteInfoSectionState();
}

class _AthleteInfoSectionState extends State<AthleteInfoSection> {
  late Future<AthleteProfile> _futProfile;

  @override
  void initState() {
    super.initState();
    _futProfile = AthleteService.fetchAthleteProfile(); // TODO(back): real
  }

  void _reloadProfile() {
    setState(() {
      _futProfile = AthleteService.fetchAthleteProfile(); // TODO(back): real
    });
  }

  Future<void> _goToEditProfile(BuildContext context) async {
    // Mantém o mesmo padrão do coach: abre tela e, se voltar "true", recarrega
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.athleteProfileEdit,
    );

    if (changed == true) {
      _reloadProfile();
      widget.onRefreshRequest?.call();
    }
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
        if (!snap.hasData) {
          return const Center(child: Text('Falha ao carregar perfil.'));
        }

        final profile = snap.data!;

        // calcula % de perfil completo (sem box)
        int filled = 0;
        if ((profile.category ?? '').trim().isNotEmpty) filled++;
        if (profile.reference != null) filled++;
        const total = 2;
        final pct = filled / total;

        final btnReserve = 128 * scale;

        // proteção (igual coach): não nulo e não vazio
        final hasValidPhoto =
            profile.photoUrl != null && profile.photoUrl!.isNotEmpty;

        final editBtn = OutlinedButton.icon(
          onPressed: () => _goToEditProfile(context),
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
              // ─── Cabeçalho em Stack ───
              Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto do atleta (com proteção)
                      CircleAvatar(
                        radius: 28 * scale,
                        backgroundColor: AppColors.lightGray,
                        backgroundImage:
                            hasValidPhoto
                                ? NetworkImage(profile.photoUrl!)
                                : null,
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

                      // Nome e Categoria
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: btnReserve),
                              child: Text(
                                (profile.name).isEmpty
                                    ? 'Atleta'
                                    : profile.name,
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

                            // Categoria: label decorado + valor/CTA fora
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
                                      SvgPicture.asset(
                                        'assets/icons/rewards.svg',
                                        width: 16 * scale,
                                        height: 16 * scale,
                                        color: AppColors.darkBlue,
                                      ),
                                      SizedBox(width: 4 * scale),
                                      Text(
                                        'Categoria:',
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

                                if ((profile.category ?? '').trim().isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      profile.category!,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12 * scale,
                                        color: AppColors.darkText,
                                      ),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: IconTextActionButton(
                                        text: 'Complete seu perfil',
                                        iconData: Icons.add,
                                        fontSize: 12 * scale,
                                        onPressed:
                                            () => _goToEditProfile(context),
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

              // ─── Bloco: Perfil Referência ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
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
                              Icon(
                                Icons.search,
                                size: 16 * scale,
                                color: AppColors.darkBlue,
                              ),
                              SizedBox(width: 4 * scale),
                              Text(
                                'Perfil Referência:',
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
                        if (profile.reference != null) ...[
                          Text(
                            profile.reference!.gender,
                            style: TextStyle(color: AppColors.darkText),
                          ),
                          Text(
                            profile.reference!.ageRange,
                            style: TextStyle(color: AppColors.darkText),
                          ),
                          Text(
                            profile.reference!.weightRange,
                            style: TextStyle(color: AppColors.darkText),
                          ),
                          Text(
                            profile.reference!.practiceYears,
                            style: TextStyle(color: AppColors.darkText),
                          ),
                          Text(
                            profile.reference!.heightRange,
                            style: TextStyle(color: AppColors.darkText),
                          ),
                        ] else
                          IconTextActionButton(
                            text: 'Complete seu perfil',
                            iconData: Icons.add,
                            fontSize: 12 * scale,
                            onPressed: () => _goToEditProfile(context),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24 * scale),

              // ─── Barra de progresso ───
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

              // ─── Botões de ação ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (pct < 1.0) ...[
                    OutlinedButton.icon(
                      onPressed: () => _goToEditProfile(context),
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
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.athleteSettings);
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
            ],
          ),
        );
      },
    );
  }
}
