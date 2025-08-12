// lib/shared/widgets/home_greeting_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/athlete_service.dart';
import 'package:flutter_app/shared/models/athlete_profile.dart';
import 'package:flutter_app/shared/widgets/performance_insights_carousel.dart';

/// Saudação da Home:
/// Exibe "Olá, {nome}! Vamos começar mais um dia com movimento?"
class HomeGreetingSection extends StatefulWidget {
  /// Se true, mostra apenas o primeiro nome. Default: true.
  final bool useFirstName;

  /// Padding externo opcional.
  final EdgeInsetsGeometry? padding;

  const HomeGreetingSection({Key? key, this.useFirstName = true, this.padding})
    : super(key: key);

  @override
  State<HomeGreetingSection> createState() => _HomeGreetingSectionState();
}

class _HomeGreetingSectionState extends State<HomeGreetingSection> {
  late Future<AthleteProfile> _future;

  @override
  void initState() {
    super.initState();
    // TODO backend: este service deve buscar o perfil atual do usuário logado.
    _future = AthleteService.fetchAthleteProfile();
  }

  String _firstName(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? full : parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    final pad =
        widget.padding ??
        EdgeInsets.fromLTRB(12 * scale, 8 * scale, 12 * scale, 8 * scale);

    return FutureBuilder<AthleteProfile>(
      future: _future,
      builder: (context, snap) {
        String name = '...';
        if (snap.hasData) {
          name =
              widget.useFirstName
                  ? _firstName(snap.data!.name)
                  : snap.data!.name;
        }

        return Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Olá, $name! Vamos começar mais um dia com movimento?',
                style: TextStyle(
                  fontFamily: AppFonts.montserrat,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 20 * scale,
                  color: AppColors.darkText,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8 * scale),
              Divider(
                color: AppColors.mediumGray,
                thickness: .5 * scale,
                height: .5 * scale, // altura total ocupada pelo divisor
              ),
              SizedBox(height: 8 * scale),
            ],
          ),
        );
      },
    );
  }
}
