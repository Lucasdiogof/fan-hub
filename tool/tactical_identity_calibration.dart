// Tooling de DESENVOLVIMENTO — nunca roda dentro do app, nunca altera
// perguntas/pesos/coordenadas automaticamente (ver spec). Só gera um
// relatório pra avaliarmos manualmente se o dataset de técnicos/perguntas
// precisa de recalibração.
//
// Uso:
//   dart run tool/tactical_identity_calibration.dart
//
// Enumera as 4^10 = 1.048.576 combinações possíveis de respostas (4
// alternativas × 10 perguntas) e reporta:
//   1. distribuição de arquétipos;
//   2. frequência de cada técnico como referência #1;
//   3. frequência de cada técnico aparecendo no Top 3;
//   4. afinidade média Top1/Top2/Top3 e gaps (afinidade completa, com as 4
//      dimensões ocultas — não é mais só a distância 2D do mapa);
//   5. empates/compressão de afinidade;
//   6. densidade do mapa tático por região (grade 5×5);
//   7. técnicos que nunca aparecem no Top 3;
//   8. técnicos excessivamente dominantes (>20% das combinações como #1);
//   9. regiões da grade nunca alcançadas por nenhum resultado.
import 'dart:io';

import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_coach_references.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_engine.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_questions.dart';

final _engine = TacticalIdentityEngine(tacticalCoachReferences);
const _gridSize = 5;

void main(List<String> args) {
  final sampleEvery = args.isNotEmpty ? int.parse(args.first) : 1;
  const questions = tacticalIdentityQuestions;
  final optionCounts = questions.map((q) => q.options.length).toList();
  final total = optionCounts.fold<int>(1, (a, b) => a * b);

  stdout.writeln(
    'Identidade Futebolística — calibração ($total combinações'
    '${sampleEvery > 1 ? ', amostrando 1 a cada $sampleEvery' : ', enumeração completa'})',
  );

  final archetypeCounts = <TacticalArchetype, int>{
    for (final a in TacticalArchetype.values) a: 0,
  };
  final top1Counts = <String, int>{
    for (final c in tacticalCoachReferences) c.id: 0,
  };
  final top3Counts = <String, int>{
    for (final c in tacticalCoachReferences) c.id: 0,
  };
  final gridCounts = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));
  final top1Aff = <double>[];
  final top2Aff = <double>[];
  final top3Aff = <double>[];
  var tieVisual = 0;
  var top1Top2Within1 = 0;
  var allWithin3 = 0;

  final indices = List.filled(questions.length, 0);
  var evaluated = 0;
  var combo = 0;

  void evaluate() {
    combo++;
    if (sampleEvery > 1 && combo % sampleEvery != 0) return;
    final answers = [
      for (var i = 0; i < questions.length; i++)
        questions[i].options[indices[i]],
    ];
    final result = _engine.computeResult(answers);
    evaluated++;
    archetypeCounts[result.archetype] = archetypeCounts[result.archetype]! + 1;
    final top1 = result.closestCoaches.first.coach.id;
    top1Counts[top1] = top1Counts[top1]! + 1;
    for (final affinity in result.closestCoaches) {
      final id = affinity.coach.id;
      top3Counts[id] = top3Counts[id]! + 1;
    }
    final a1 = result.closestCoaches[0].affinity;
    final a2 = result.closestCoaches[1].affinity;
    final a3 = result.closestCoaches[2].affinity;
    top1Aff.add(a1);
    top2Aff.add(a2);
    top3Aff.add(a3);
    if (a1.round() == a2.round() && a2.round() == a3.round()) tieVisual++;
    if ((a1 - a2).abs() <= 1) top1Top2Within1++;
    if ((a1 - a3).abs() <= 3) allWithin3++;
    final gx = (((result.x + 100) / 200) * _gridSize).floor().clamp(
      0,
      _gridSize - 1,
    );
    final gy = (((100 - result.y) / 200) * _gridSize).floor().clamp(
      0,
      _gridSize - 1,
    );
    gridCounts[gy][gx]++;
  }

  // Contador de dígitos base-4 (10 dígitos) — enumera todas as combinações
  // sem recursão e sem alocar 1M listas na memória de uma vez.
  while (true) {
    evaluate();
    var i = indices.length - 1;
    while (i >= 0) {
      indices[i]++;
      if (indices[i] < optionCounts[i]) break;
      indices[i] = 0;
      i--;
    }
    if (i < 0) break;
  }

  stdout.writeln('Combinações avaliadas: $evaluated');
  stdout.writeln();

  stdout.writeln('1) Distribuição de arquétipos:');
  final archetypeEntries = archetypeCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in archetypeEntries) {
    final pct = (entry.value / evaluated * 100).toStringAsFixed(2);
    stdout.writeln(
      '   ${entry.key.displayName.padRight(22)} $pct%  (${entry.value})',
    );
  }
  stdout.writeln();

  stdout.writeln(
    '2) Frequência de cada técnico como #1 (principal referência):',
  );
  final top1Entries = top1Counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in top1Entries) {
    final coach = tacticalCoachReferences.firstWhere((c) => c.id == entry.key);
    final pct = (entry.value / evaluated * 100).toStringAsFixed(2);
    stdout.writeln('   ${coach.coach.padRight(22)} $pct%  (${entry.value})');
  }
  stdout.writeln();

  stdout.writeln('3) Frequência de cada técnico aparecendo no Top 3:');
  final top3Entries = top3Counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in top3Entries) {
    final coach = tacticalCoachReferences.firstWhere((c) => c.id == entry.key);
    final pct = (entry.value / evaluated * 100).toStringAsFixed(2);
    stdout.writeln('   ${coach.coach.padRight(22)} $pct%  (${entry.value})');
  }
  stdout.writeln();

  double mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;

  stdout.writeln('4) Afinidade média Top1/Top2/Top3 e gaps:');
  stdout.writeln('   Top1 médio: ${mean(top1Aff).toStringAsFixed(2)}%');
  stdout.writeln('   Top2 médio: ${mean(top2Aff).toStringAsFixed(2)}%');
  stdout.writeln('   Top3 médio: ${mean(top3Aff).toStringAsFixed(2)}%');
  stdout.writeln(
    '   Gap médio Top1→Top2: ${(mean(top1Aff) - mean(top2Aff)).toStringAsFixed(2)} pontos',
  );
  stdout.writeln(
    '   Gap médio Top2→Top3: ${(mean(top2Aff) - mean(top3Aff)).toStringAsFixed(2)} pontos',
  );
  stdout.writeln();

  stdout.writeln('5) Empates/compressão:');
  stdout.writeln(
    '   Empate visual (Top1==Top2==Top3 arredondado): ${(tieVisual / evaluated * 100).toStringAsFixed(2)}%',
  );
  stdout.writeln(
    '   Top1/Top2 a <=1 ponto: ${(top1Top2Within1 / evaluated * 100).toStringAsFixed(2)}%',
  );
  stdout.writeln(
    '   Top1/Top2/Top3 todos dentro de 3 pontos: ${(allWithin3 / evaluated * 100).toStringAsFixed(2)}%',
  );
  stdout.writeln();

  stdout.writeln(
    '6) Densidade do mapa tático (grade ${_gridSize}x$_gridSize, linha 0 = '
    'topo/PRAGMÁTICO, coluna 0 = esquerda/POSSE):',
  );
  for (final row in gridCounts) {
    stdout.writeln(
      '   ${row.map((c) => (c / evaluated * 100).toStringAsFixed(1).padLeft(6)).join('  ')}',
    );
  }
  stdout.writeln();

  final neverTop3 = top3Entries.where((e) => e.value == 0).toList();
  stdout.writeln('7) Técnicos que NUNCA aparecem no Top 3:');
  stdout.writeln(
    neverTop3.isEmpty
        ? '   (nenhum)'
        : neverTop3
              .map(
                (e) =>
                    '   '
                    '${tacticalCoachReferences.firstWhere((c) => c.id == e.key).coach}',
              )
              .join('\n'),
  );
  stdout.writeln();

  final dominant = top1Entries
      .where((e) => e.value / evaluated > 0.20)
      .toList();
  stdout.writeln('8) Técnicos excessivamente dominantes como #1 (>20%):');
  stdout.writeln(
    dominant.isEmpty
        ? '   (nenhum)'
        : dominant
              .map(
                (e) =>
                    '   '
                    '${tacticalCoachReferences.firstWhere((c) => c.id == e.key).coach} — '
                    '${(e.value / evaluated * 100).toStringAsFixed(1)}%',
              )
              .join('\n'),
  );
  stdout.writeln();

  final unreachable = <String>[];
  for (var row = 0; row < _gridSize; row++) {
    for (var col = 0; col < _gridSize; col++) {
      if (gridCounts[row][col] == 0) unreachable.add('linha $row, coluna $col');
    }
  }
  stdout.writeln('9) Regiões da grade nunca alcançadas:');
  stdout.writeln(
    unreachable.isEmpty
        ? '   (nenhuma)'
        : unreachable.map((s) => '   $s').join('\n'),
  );
}
