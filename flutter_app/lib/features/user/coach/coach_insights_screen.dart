import 'package:flutter/material.dart';
import 'package:flutter_app/core/constants/app_colors.dart';
import 'package:flutter_app/core/constants/app_fonts.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/core/services/workout/training_service.dart';
import 'package:flutter_app/shared/widgets/sections/coach/coach_training_insights_overview_section.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';
// Importe seu DateSelector existente (verifique o caminho correto no seu projeto)
import 'package:flutter_app/shared/widgets/utils/date_selector.dart';

class CoachInsightsScreen extends StatefulWidget {
  static const routeName = '/coach_insights';
  const CoachInsightsScreen({Key? key}) : super(key: key);

  @override
  State<CoachInsightsScreen> createState() => _CoachInsightsScreenState();
}

class _CoachInsightsScreenState extends State<CoachInsightsScreen> {
  // Estado da tela
  DateTime _selectedDate = DateTime.now();
  List<Training> _dayTrainings = [];
  Training? _selectedTraining;

  bool _isLoading = true;
  String? _errorMessage;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialSetup();
      _initialized = true;
    }
  }

  Future<void> _initialSetup() async {
    // 1. Verifica se veio um treino específico de outra tela (ex: clique no botão "Insights IA")
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('training')) {
      final t = args['training'] as Training;
      // Se veio um treino, setamos a data dele e o selecionamos diretamente
      setState(() {
        _selectedDate = t.date;
        _selectedTraining = t;
        // Mesmo vindo um treino específico, buscamos a lista do dia para permitir troca
        _fetchTrainingsForDate(_selectedDate, preserveSelected: true);
      });
    } else if (args != null &&
        (args.containsKey('trainingId') || args.containsKey('dateIso'))) {
      final preferredTrainingId = args['trainingId'] as String?;
      final date = _dateFromArgs(args) ?? DateTime.now();
      _selectedDate = date;
      await _fetchTrainingsForDate(
        date,
        preferredTrainingId: preferredTrainingId,
      );
    } else {
      // Se veio do menu (sem argumentos), carrega o dia de hoje
      _fetchTrainingsForDate(DateTime.now());
    }
  }

  // Função chamada quando muda a data no calendário
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchTrainingsForDate(date);
  }

  Future<void> _fetchTrainingsForDate(
    DateTime date, {
    bool preserveSelected = false,
    String? preferredTrainingId,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (!preserveSelected) _selectedTraining = null;
    });

    try {
      // Busca a lista de treinos daquele dia (Lógica que arrumamos no passo anterior)
      // Ajuste o boxId conforme sua lógica de usuário
      final list = await TrainingService.fetchTrainingsListForDate(
        boxId: '1',
        date: date,
      );

      if (mounted) {
        setState(() {
          _dayTrainings = list;
          _isLoading = false;

          if (list.isNotEmpty) {
            // Se não estamos preservando um treino específico, pega o primeiro
            if (_selectedTraining == null || !preserveSelected) {
              _selectedTraining = _selectTraining(list, preferredTrainingId);
            }
          } else {
            _selectedTraining = null;
            _errorMessage = "Nenhum treino encontrado nesta data.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro ao carregar: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),
      bottomNavigationBar: const BottomNavBar(),
      body: Column(
        children: [
          // 1. SELETOR DE DATA (Igual ao da tela de treinos)
          Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 10 * scale),
            child: DateSelector(
              initialDate: _selectedDate,
              onDateChanged: _onDateSelected,
            ),
          ),

          // 2. CONTEÚDO
          Expanded(child: _buildBody(scale)),
        ],
      ),
    );
  }

  Widget _buildBody(double scale) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(20.0 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                size: 40 * scale,
                color: AppColors.mediumGray,
              ),
              SizedBox(height: 10 * scale),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: AppColors.mediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedTraining == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        vertical: 8 * scale,
        horizontal: 12 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 3. SELETOR DE TREINO (Só aparece se tiver + de 1 treino no dia)
          if (_dayTrainings.length > 1) ...[
            _buildWorkoutSwitcher(scale),
            SizedBox(height: 16 * scale),
          ],

          // 4. A VISÃO GERAL (O componente que já criamos)
          CoachTrainingInsightsOverviewSection(training: _selectedTraining),
        ],
      ),
    );
  }

  // Widget Dropdown para trocar entre WOD e LPO, etc.
  Widget _buildWorkoutSwitcher(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 4 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Text(
            "Analisando: ",
            style: TextStyle(
              fontFamily: AppFonts.roboto,
              fontSize: 12 * scale,
              color: AppColors.mediumGray,
            ),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Training>(
                value: _selectedTraining,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: 20 * scale,
                  color: AppColors.baseBlue,
                ),
                items:
                    _dayTrainings.map((training) {
                      return DropdownMenuItem<Training>(
                        value: training,
                        child: Text(
                          _getTrainingTitle(
                            training,
                          ), // Função auxiliar para nomear
                          style: TextStyle(
                            fontFamily: AppFonts.montserrat,
                            fontWeight: FontWeight.w600,
                            fontSize: 13 * scale,
                            color: AppColors.darkText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                onChanged: (Training? newTraining) {
                  if (newTraining != null) {
                    setState(() {
                      _selectedTraining = newTraining;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mesma lógica de nomes que usamos na lista, mas simplificada para o Dropdown
  String _getTrainingTitle(Training training) {
    // Tenta pegar o nome do WOD
    if (training.partes.containsKey('WOD')) {
      final dynamic wod = training.partes['WOD'];
      String? nomeWod;
      if (wod is Map) nomeWod = wod['nomeWod'];
      // Adicione tratamento de objeto se necessário

      if (nomeWod != null && nomeWod.isNotEmpty) {
        return "WOD - $nomeWod";
      }
      return "WOD do Dia";
    }
    if (training.partes.containsKey('LPO')) return "Aula de LPO";
    if (training.partes.containsKey('GINASTICA')) return "Ginástica / Skill";

    return "Treino Geral";
  }

  DateTime? _dateFromArgs(Map<String, dynamic> args) {
    final rawDate = args['date'];
    if (rawDate is DateTime) return rawDate;

    final rawDateIso = args['dateIso'] ?? args['dataTreinoIso'];
    if (rawDateIso is String && rawDateIso.isNotEmpty) {
      return DateTime.tryParse(rawDateIso);
    }

    return null;
  }

  Training _selectTraining(List<Training> list, String? preferredTrainingId) {
    if (preferredTrainingId != null && preferredTrainingId.isNotEmpty) {
      for (final training in list) {
        if (training.id == preferredTrainingId) return training;
      }
    }
    return list.first;
  }
}
