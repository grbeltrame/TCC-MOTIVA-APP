import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_app/shared/widgets/carousels/alerts_carousel.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/shared/models/cycle_models.dart';

/// Service do Ciclo (Mensal) conectado ao Firestore.
class CycleService {
  /// Busca o bundle completo do detalhe do ciclo a partir do backend gerado por IA
  static Future<CycleDetailBundle> fetchCycleDetail({
    required String boxId,
    required int year,
    required int month, // 1-12
  }) async {
    try {
      // 1. Monta o ID do documento (ex: "02-2026")
      final String docId = '${month.toString().padLeft(2, '0')}-$year';

      // 2. Busca o documento na coleção 'cycles'
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('cycles')
              .doc(docId)
              .get();

      // Se o documento não existir, retornamos um bundle vazio (Zero State)
      if (!docSnapshot.exists || docSnapshot.data() == null) {
        return _emptyBundle();
      }

      final data = docSnapshot.data()!;

      // --- PARSING OVERVIEW ---
      final overviewStats =
          data['overview_stats'] as Map<String, dynamic>? ?? {};
      final updatedAtStr = overviewStats['updatedAt'] as String?;
      final updatedAt =
          updatedAtStr != null
              ? DateTime.tryParse(updatedAtStr) ?? DateTime.now()
              : DateTime.now();

      final overview = CycleOverview(
        updatedAt: updatedAt,
        trainingsCount: overviewStats['trainingsCount'] as int? ?? 0,
        registrosCount: overviewStats['registrosCount'] as int? ?? 0, // WIP
        activeStudentsPct:
            overviewStats['activeStudentsPct'] as int? ?? 0, // WIP
      );

      // --- PARSING TRAINING TYPES ---
      final rawTypes = data['trainingTypes'] as List<dynamic>? ?? [];
      final trainingTypes =
          rawTypes.map((e) {
            final map = e as Map<String, dynamic>;
            return CycleTrainingTypeCount(
              typeLabel: map['typeLabel'] as String? ?? 'Desconhecido',
              typeKey: map['typeKey'] as String? ?? 'unknown',
              count: map['count'] as int? ?? 0,
            );
          }).toList();

      // --- PARSING ALERTS (Criados pelo Gemini - quick_alerts) ---
      final rawAlerts = data['quick_alerts'] as List<dynamic>? ?? [];
      final alerts =
          rawAlerts.map((e) {
            return AlertModel(
              type: 'cycle', // Mantém o tipo que seu carrossel espera
              message: e.toString(),
            );
          }).toList();

      // Se a IA não gerou alertas curtos por algum motivo, colocamos um padrão
      if (alerts.isEmpty) {
        alerts.add(
          AlertModel(
            type: 'cycle',
            message: 'Nenhum alerta crítico para este ciclo.',
          ),
        );
      }

      // --- PARSING STIMULUS (Gráfico de Pizza) ---
      final rawStimulus = data['stimulus'] as List<dynamic>? ?? [];
      final stimulus =
          rawStimulus.map((e) {
            final map = e as Map<String, dynamic>;
            return CycleStimulusSlice(
              stimulus: map['stimulus'] as String? ?? 'N/A',
              count: map['count'] as int? ?? 0,
            );
          }).toList();

      // --- MONTANDO A FRASE DE DESTAQUE ---
      // Pegamos o nome do maior estímulo salvo pelo Python
      final biggestName =
          data['biggestStimulusLabel'] as String? ?? 'Equilibrado';

      // Encontramos a contagem desse estímulo específico na lista
      final biggestItem = stimulus.firstWhere(
        (s) => s.stimulus == biggestName,
        orElse: () => CycleStimulusSlice(stimulus: biggestName, count: 0),
      );

      final biggestLabel =
          '${biggestItem.stimulus} foi o maior estimulo - ${biggestItem.count}\n'
          'dos ${overview.trainingsCount} treinos';

      // 3. Retorna o Bundle pronto pra tela!
      return CycleDetailBundle(
        overview: overview,
        trainingTypes: trainingTypes,
        alerts: alerts,
        stimulus: stimulus,
        biggestStimulusLabel: biggestLabel,
      );
    } catch (e) {
      print("Erro ao buscar detalhes do ciclo: $e");
      return _emptyBundle();
    }
  }

  /// Retorna um estado zerado caso dê erro ou não tenha dados (evita a tela quebrar)
  static CycleDetailBundle _emptyBundle() {
    return CycleDetailBundle(
      overview: CycleOverview(
        updatedAt: DateTime.now(),
        trainingsCount: 0,
        registrosCount: 0,
        activeStudentsPct: 0,
      ),
      trainingTypes: [],
      alerts: [AlertModel(type: 'cycle', message: 'Sem dados do ciclo ainda.')],
      stimulus: [CycleStimulusSlice(stimulus: '—', count: 0)],
      biggestStimulusLabel: 'Nenhum treino registrado neste ciclo.',
    );
  }

  static String monthTitlePtBR(int month) {
    // month 1-12
    final d = DateTime(2026, month, 1);
    final m = DateFormat('MMMM', 'pt_BR').format(d);
    return m[0].toUpperCase() + m.substring(1);
  }
}
