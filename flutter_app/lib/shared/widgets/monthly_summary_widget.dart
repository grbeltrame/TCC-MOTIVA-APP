// lib/shared/widgets/monthly_summary_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/core/services/mini_card_service.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import 'mini_card_widget.dart';

/// Widget principal de Resumo Mensal.
/// Carrega timestamp e exibe três MiniCards (PRs, Frequência, Esforço).
class MonthlySummaryWidget extends StatefulWidget {
  const MonthlySummaryWidget({Key? key}) : super(key: key);

  @override
  _MonthlySummaryWidgetState createState() => _MonthlySummaryWidgetState();
}

class _MonthlySummaryWidgetState extends State<MonthlySummaryWidget> {
  late String _lastUpdate; // ex: "21/07/2025 às 14:58"
  late String _currentMonth; // ex: "Julho"

  @override
  void initState() {
    super.initState();
    _refreshTimestamp();
  }

  void _refreshTimestamp() {
    final now = DateTime.now();
    _lastUpdate = DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(now);
    _currentMonth = _capitalize(DateFormat.MMMM('pt_BR').format(now));
  }

  @override
  Widget build(BuildContext context) {
    // calculamos a escala aqui, dentro de build, para não depender de late fields
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- Cabeçalho de atualização ---
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 20 * scale,
              color: AppColors.darkText,
            ),
            SizedBox(width: 6 * scale),
            Text(
              'Última atualização: $_lastUpdate',
              style: TextStyle(
                fontFamily: AppFonts.roboto,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
        SizedBox(height: 4 * scale),

        // --- Subtítulo com mês dinâmico ---
        Text(
          'Análise gerada com base nos seus treinos do mês de $_currentMonth.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppFonts.roboto,
            fontWeight: AppFontWeight.medium,
            fontSize: 12 * scale,
            color: AppColors.darkText,
          ),
        ),
        SizedBox(height: 16 * scale),

        // --- Linha de MiniCards ---
        Row(
          children: [
            Expanded(
              child: MiniCardWidget(
                iconWidget: SvgPicture.asset(
                  'assets/icons/exercise.svg',
                  width: 16,
                  height: 16,
                  color: AppColors.darkText, // se você quiser aplicar color
                ),
                title: 'PR batidos',
                tipo: CardInfoType.prsMes,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
              ),
            ),
            SizedBox(width: 6 * scale),
            Expanded(
              child: MiniCardWidget(
                iconWidget: Icon(
                  Icons.calendar_month_outlined,
                  size: 16,
                  color: AppColors.darkText,
                ),
                title: 'Frequência',
                tipo: CardInfoType.frequenciaMes,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
              ),
            ),
            SizedBox(width: 6 * scale),
            Expanded(
              child: MiniCardWidget(
                iconWidget: SvgPicture.asset(
                  'assets/icons/relax.svg',
                  width: 16,
                  height: 16,
                  color: AppColors.darkText, // se você quiser aplicar color
                ),
                title: 'Esforço',
                tipo: CardInfoType.esforcoMes,
                backgroundColor: AppColors.lightBlue,
                iconColor: AppColors.darkText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
