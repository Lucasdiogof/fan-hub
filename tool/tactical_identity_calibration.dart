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
//   4. densidade do mapa tático por região (grade 5×5);
//   5. técnicos que nunca aparecem no Top 3;
//   6. técnicos excessivamente dominantes (>20% das combinações como #1);
//   7. regiões da grade nunca alcançadas por nenhum resultado.
import 'dart:io';

import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_coach_references.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_engine.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_models.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_questions.dart';

const _engine = TacticalIdentityEngine();
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
    stdout.writeln('   ${entry.key.displayName.padRight(22)} $pct%  (${entry.value})');
  }
  stdout.writeln();

  stdout.writeln('2) Frequência de cada técnico como #1 (principal referência):');
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

  stdout.writeln(
    '4) Densidade do mapa tático (grade ${_gridSize}x$_gridSize, linha 0 = '
    'topo/PRAGMÁTICO, coluna 0 = esquerda/POSSE):',
  );
  for (final row in gridCounts) {
    stdout.writeln(
      '   ${row.map((c) => (c / evaluated * 100).toStringAsFixed(1).padLeft(6)).join('  ')}',
    );
  }
  stdout.writeln();

  final neverTop3 = top3Entries.where((e) => e.value == 0).toList();
  stdout.writeln('5) Técnicos que NUNCA aparecem no Top 3:');
  stdout.writeln(
    neverTop3.isEmpty
        ? '   (nenhum)'
        : neverTop3
              .map(
                (e) => '   '
                '${tacticalCoachReferences.firstWhere((c) => c.id == e.key).coach}',
              )
              .join('\n'),
  );
  stdout.writeln();

  final dominant = top1Entries.where((e) => e.value / evaluated > 0.20).toList();
  stdout.writeln('6) Técnicos excessivamente dominantes como #1 (>20%):');
  stdout.writeln(
    dominant.isEmpty
        ? '   (nenhum)'
        : dominant
              .map(
                (e) => '   '
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
  stdout.writeln('7) Regiões da grade nunca alcançadas:');
  stdout.writeln(unreachable.isEmpty ? '   (nenhuma)' : unreachable.map((s) => '   $s').join('\n'));
}
