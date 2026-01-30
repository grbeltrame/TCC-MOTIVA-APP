import 'package:flutter/material.dart';
import 'package:flutter_app/shared/models/training.dart';
import 'package:flutter_app/core/services/workout/training_service.dart'; // Importe seu service
import 'package:flutter_app/shared/widgets/sections/coach/coach_training_insights_overview_section.dart';
import 'package:flutter_app/shared/widgets/utils/top_navbar.dart';
import 'package:flutter_app/shared/widgets/utils/bottom_navbar.dart';

class CoachInsightsScreen extends StatefulWidget {
  static const routeName = '/coach_insights';
  const CoachInsightsScreen({Key? key}) : super(key: key);

  @override
  State<CoachInsightsScreen> createState() => _CoachInsightsScreenState();
}

class _CoachInsightsScreenState extends State<CoachInsightsScreen> {
  Training? _training;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Tenta recuperar o treino passado pelos argumentos (Se vier de outra tela)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args.containsKey('training')) {
      setState(() {
        _training = args['training'] as Training;
        _isLoading = false;
      });
      return;
    }

    // 2. Se não veio argumento (clique no BottomNavBar), busca o treino de HOJE
    // Evita buscar novamente se já tiver carregado
    if (_training != null) return;

    try {
      // Busca os treinos da data de hoje
      // Ajuste o 'boxId' conforme sua lógica de usuário logado
      final todayList = await TrainingService.fetchTrainingsListForDate(
        boxId: '1',
        date: DateTime.now(),
      );

      if (todayList.isNotEmpty) {
        setState(() {
          // Pega o primeiro treino do dia para mostrar os insights
          _training = todayList.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Não há treinos cadastrados para hoje.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erro ao carregar insights: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 375.0;

    return Scaffold(
      appBar: const TopNavbar(),
      bottomNavigationBar: const BottomNavBar(), // Sua barra inferior
      body: _buildBody(scale),
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
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14 * scale, color: Colors.grey),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        vertical: 8 * scale,
        horizontal: 12 * scale,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Passamos o treino carregado (seja por argumento ou busca automática)
          CoachTrainingInsightsOverviewSection(training: _training),
        ],
      ),
    );
  }
}
