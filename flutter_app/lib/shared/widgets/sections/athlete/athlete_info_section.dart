// lib/shared/widgets/athlete_info_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/services/users/athlete/athlete_service.dart';
import 'package:flutter_app/shared/models/athlete_profile.dart';
import 'package:flutter_app/shared/widgets/utils/icon_text_action_button.dart';
import 'package:flutter_app/shared/widgets/mocks/app_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/box_signup_coach.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_svg/svg.dart';

/// Seção de informações do perfil do atleta:
/// • Container com borda arredondada
/// • Foto, nome, categoria e botão Editar Perfil (posicionado)
/// • Blocos: Perfil Referência, Boxes cadastrados (em dropdown)
/// • Barra de progresso e botões de ação
class AthleteInfoSection extends StatefulWidget {
  const AthleteInfoSection({Key? key}) : super(key: key);

  @override
  State<AthleteInfoSection> createState() => _AthleteInfoSectionState();
}

class _AthleteInfoSectionState extends State<AthleteInfoSection> {
  late Future<AthleteProfile> _futProfile;
  String? _selectedBox;

  @override
  void initState() {
    super.initState();
    _futProfile = AthleteService.fetchAthleteProfile(); // TODO: fetch real
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

        // Inicializa dropdown de box
        if (profile.boxes.isNotEmpty && _selectedBox == null) {
          _selectedBox = profile.boxes.first;
        }

        // calcula % de perfil completo
        int filled = 0;
        if (profile.category != null) filled++;
        if (profile.reference != null) filled++;
        if (profile.boxes.isNotEmpty) filled++;
        const total = 3;
        final pct = filled / total;

        // largura reservada para o botão "Editar Perfil" ao lado do nome
        final btnReserve = 128 * scale;

        // botão "Editar Perfil" (reutilizado no Stack)
        final editBtn = OutlinedButton.icon(
          onPressed: () {
            // TODO: navegar para editar perfil
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
              // ─── Cabeçalho em Stack: conteúdo ocupa 100% e o botão é posicionado ───
              Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Foto do atleta
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

                      // Nome e Categoria
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome (com padding à direita para não ficar sob o botão)
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

                            // Categoria: container decorado envolve apenas ícone + label
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
                                        'assets/icons/rewards.svg', // ajuste se necessário
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

                                // Valor/CTA fora do container decorado
                                if (profile.category != null)
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
                                        onPressed: () {
                                          // TODO: navegar para completar perfil
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

                  // Botão Editar Perfil posicionado no topo-direito
                  Positioned(top: 0, right: 0, child: editBtn),
                ],
              ),

              SizedBox(height: 16 * scale),

              // ─── Blocos de informação ───
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Perfil Referência
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
                            onPressed: () {
                              // TODO: navegar para completar perfil
                            },
                          ),
                      ],
                    ),
                  ),

                  SizedBox(width: 18 * scale),

                  // Boxes cadastrados em Dropdown
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
                                Icons.home_outlined,
                                size: 16 * scale,
                                color: AppColors.darkBlue,
                              ),
                              SizedBox(width: 4 * scale),
                              Text(
                                'Boxes Cadastrados:',
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
                        if (profile.boxes.isNotEmpty)
                          DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedBox,
                            underline: const SizedBox.shrink(),
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppColors.darkText,
                            ),
                            items:
                                profile.boxes
                                    .map(
                                      (b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => setState(() => _selectedBox = v),
                          )
                        else
                          IconTextActionButton(
                            text: 'Cadastrar-se em um box',
                            iconData: Icons.add,
                            fontSize: 12 * scale,
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

              SizedBox(height: 24 * scale),

              // ─── Barra de progresso ───
              if (pct < 1.0) ...[
                // Label + texto ao lado (pedido)
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

                // Linha de status + porcentagem (apenas número) ao lado
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4 * scale),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6 * scale,
                          backgroundColor: AppColors.lightGray,
                          valueColor: AlwaysStoppedAnimation(
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
            ],
          ),
        );
      },
    );
  }
}
