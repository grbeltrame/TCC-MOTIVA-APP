// lib/shared/widgets/profile_nav_hub_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';

class ProfileNavHubSection extends StatelessWidget {
  const ProfileNavHubSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 375.0;

    // Esse deve bater com o padding horizontal da tela (AthleteProfileScreen)
    final outerPagePadding = 8 * scale;

    final items = <_NavItem>[
      _NavItem(
        'Minha Evolução',
        'assets/icons/bar_chart_4_bars.svg',
        '/evolution',
      ),
      _NavItem(
        'Minhas Projeções',
        'assets/icons/trending_up.svg',
        '/projections',
      ),
      _NavItem('Objetivos e Metas', 'assets/icons/crisis_alert.svg', '/goals'),
      _NavItem(
        'Funcionalidades Ativas',
        'assets/icons/settings.svg',
        '/features',
      ),
    ];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Fundo cinza "full-bleed": pinta para fora do padding do pai
        Positioned(
          left: -outerPagePadding,
          right: -outerPagePadding,
          top: 0,
          bottom: 0,
          child: const ColoredBox(color: Color(0xFFD9D9D9)),
        ),

        // Conteúdo normal da section
        Padding(
          // padding interno da própria section
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scale,
            vertical: 8 * scale,
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _NavRow(
                  item: items[i],
                  height: 44 * scale,
                  onTap: () {
                    // TODO: trocar pelas rotas reais
                    Navigator.pushNamed(context, items[i].route);
                    // Se quiser substituir a tela atual:
                    // Navigator.pushReplacementNamed(context, items[i].route);
                  },
                ),
                if (i < items.length - 1)
                  Divider(
                    height: 1 * scale,
                    thickness: 1 * scale,
                    color: AppColors.darkText.withOpacity(0.2),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final String title;
  final String svg;
  final String route;
  const _NavItem(this.title, this.svg, this.route);
}

class _NavRow extends StatelessWidget {
  final _NavItem item;
  final double height;
  final VoidCallback onTap;

  const _NavRow({
    Key? key,
    required this.item,
    required this.height,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            SvgPicture.asset(
              item.svg, // TODO: trocar pelos caminhos reais
              width: 18 * scale,
              height: 18 * scale,
            ),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.regular,
                  fontSize: 14 * scale,
                  color: AppColors.darkText,
                ),
              ),
            ),
            IconButton(
              onPressed: onTap,
              icon: Icon(
                Icons.chevron_right,
                size: 20 * scale,
                color: AppColors.darkText,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 18 * scale,
              tooltip: 'Abrir',
            ),
          ],
        ),
      ),
    );
  }
}
