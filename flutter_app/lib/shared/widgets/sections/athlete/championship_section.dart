import 'package:flutter/material.dart';
import 'package:flutter_app/shared/widgets/bottom_sheets/register_champ_result_bottom_sheet.dart';
import 'package:flutter_app/shared/widgets/mocks/app_dialog.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/services/championship_service.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/models/championship.dart';

// bottom sheet: adicionar campeonato
import 'package:flutter_app/shared/widgets/bottom_sheets/add_championship_bottom_sheet.dart';

class ChampionshipsSection extends StatefulWidget {
  const ChampionshipsSection({Key? key}) : super(key: key);

  @override
  _ChampionshipsSectionState createState() => _ChampionshipsSectionState();
}

class _ChampionshipsSectionState extends State<ChampionshipsSection> {
  late Future<List<Championship>> _futureUpcoming;
  late Future<List<Championship>> _futureConcluded;

  @override
  void initState() {
    super.initState();
    _futureUpcoming = ChampionshipService.fetchUpcomingChampionships();
    _futureConcluded = ChampionshipService.fetchConcludedChampionships();
  }

  Future<void> _reload() async {
    setState(() {
      _futureUpcoming = ChampionshipService.fetchUpcomingChampionships();
      _futureConcluded = ChampionshipService.fetchConcludedChampionships();
    });
  }

  Future<void> _onAddChampionshipPressed() async {
    final input = await showAddChampionshipBottomSheet(context);
    if (input == null) return;

    final created = await ChampionshipService.createChampionship(
      name: input.name,
      date: input.date,
    );

    final fmt = DateFormat('dd/MM/yyyy');
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (dialogCtx) => AppDialog(
            icon: Icons.emoji_events_outlined,
            iconColor: AppColors.darkBlue,
            title: 'Campeonato cadastrado!',
            message:
                'O campeonato "${created.name}" em ${fmt.format(created.startDate)} '
                'foi registrado com sucesso.',
            primaryAction: TextButton(
              onPressed:
                  () => Navigator.of(dialogCtx, rootNavigator: true).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.darkBlue),
              child: const Text('OK'),
            ),
          ),
    );

    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_futureUpcoming, _futureConcluded]),
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final upcoming = snap.data![0] as List<Championship>;
        final concluded = snap.data![1] as List<Championship>;

        ChampionshipService.showInAppNotifications(context, upcoming);
        ChampionshipService.showPostEventNotification(context, concluded);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Título + adicionar ----
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Row(
                children: [
                  Text(
                    'Campeonatos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _onAddChampionshipPressed,
                    icon: Icon(
                      Icons.add,
                      size: 20 * scale,
                      color: AppColors.baseBlue,
                    ),
                    label: Text(
                      'Adicionar campeonato',
                      style: TextStyle(
                        fontFamily: AppFonts.roboto,
                        fontWeight: AppFontWeight.medium,
                        fontSize: 12 * scale,
                        color: AppColors.baseBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12 * scale),

            // ---- Próximos ----
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Text(
                'Próximos',
                style: TextStyle(
                  fontFamily: AppFonts.roboto,
                  fontWeight: AppFontWeight.bold,
                  fontSize: 14 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ),
            SizedBox(height: 8 * scale),
            if (upcoming.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                child: Text(
                  'Nenhum campeonato este mês.',
                  style: TextStyle(
                    fontFamily: AppFonts.roboto,
                    fontSize: 12 * scale,
                    color: AppColors.mediumGray,
                  ),
                ),
              )
            else
              SizedBox(
                height: 100 * scale,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                  scrollDirection: Axis.horizontal,
                  itemCount: upcoming.length,
                  separatorBuilder: (_, __) => SizedBox(width: 6 * scale),
                  itemBuilder:
                      (_, i) => _UpcomingCard(
                        champ: upcoming[i],
                        // ✅ quando concluir o envio no BS, recarrega as listas
                        onRegistered: _reload,
                      ),
                ),
              ),

            SizedBox(height: 16 * scale),

            // ---- Concluídos ----
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * scale),
              child: Row(
                children: [
                  Text(
                    'Concluídos',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.bold,
                      fontSize: 14 * scale,
                      color: AppColors.mediumGray,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // TODO: navegar para ver todos concluídos
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver todos',
                          style: TextStyle(
                            fontFamily: AppFonts.roboto,
                            fontWeight: AppFontWeight.medium,
                            fontSize: 12 * scale,
                            color: AppColors.baseBlue,
                          ),
                        ),
                        SizedBox(width: 4 * scale),
                        Icon(
                          Icons.navigate_next,
                          size: 20 * scale,
                          color: AppColors.baseBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8 * scale),
            if (concluded.isEmpty)
              const SizedBox.shrink()
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6 * scale),
                child: Wrap(
                  spacing: 6 * scale,
                  runSpacing: 6 * scale,
                  children:
                      concluded.map((c) => _ConcludedCard(champ: c)).toList(),
                ),
              ),

            SizedBox(height: 32 * scale),
          ],
        );
      },
    );
  }
}

/// Card de campeonato futuro
class _UpcomingCard extends StatelessWidget {
  final Championship champ;
  final VoidCallback onRegistered; // ✅ callback para recarregar listas

  const _UpcomingCard({
    Key? key,
    required this.champ,
    required this.onRegistered, // ✅ obrigatório
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Container(
      width: 140 * scale,
      padding: EdgeInsets.all(8 * scale),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withAlpha(31),
        border: Border.all(color: AppColors.baseBlue),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            champ.name,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 14 * scale,
              color: AppColors.darkText,
            ),
          ),
          Text(
            champ.startDate == champ.endDate
                ? DateFormat('dd/MM').format(champ.startDate)
                : '${DateFormat('dd/MM').format(champ.startDate)}–${DateFormat('dd/MM').format(champ.endDate)}',
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.medium,
              fontSize: 14 * scale,
              color: AppColors.darkText,
            ),
          ),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton(
              onPressed: () async {
                // ✅ Abre o BS; retorna true quando o envio foi concluído
                final ok = await showRegisterChampResultBottomSheet(
                  context,
                  championship: champ,
                );
                if (ok == true) {
                  onRegistered(); // atualiza listas (sai de Próximos → entra em Concluídos)
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * scale,
                  vertical: 4 * scale,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Registrar resultado',
                    style: TextStyle(
                      fontFamily: AppFonts.roboto,
                      fontWeight: AppFontWeight.medium,
                      fontSize: 10 * scale,
                      color: AppColors.baseBlue,
                    ),
                  ),
                  SizedBox(width: 4 * scale),
                  Icon(Icons.edit, size: 14 * scale, color: AppColors.baseBlue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de campeonato concluído
class _ConcludedCard extends StatelessWidget {
  final Championship champ;
  const _ConcludedCard({Key? key, required this.champ}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;
    return Container(
      width: 100 * scale,
      padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 6 * scale),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.baseBlue),
        borderRadius: BorderRadius.circular(16 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            champ.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontWeight: AppFontWeight.bold,
              fontSize: 12 * scale,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 4 * scale),
          if (champ.userRanking != null && champ.totalParticipants != null)
            Text(
              'Ranking ${champ.userRanking}/${champ.totalParticipants}',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: AppFontWeight.medium,
                fontSize: 12 * scale,
                color: AppColors.darkText,
              ),
            ),
        ],
      ),
    );
  }
}
