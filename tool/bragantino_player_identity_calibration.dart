// Tooling de DESENVOLVIMENTO — nunca roda dentro do app, nunca altera
// perguntas/pesos/dataset automaticamente. Mesmo relatório de
// `player_identity_calibration.dart`, só que sobre o dataset do
// BRAGANTINO — os dois ficam em arquivos separados pelo mesmo motivo dos
// datasets ficarem em arquivos separados (cada clube é uma fonte de
// evidência diferente, nunca compartilhada).
//
// Uso:
//   dart run tool/bragantino_player_identity_calibration.dart [amostra]
//
// `amostra` (opcional): avalia 1 a cada N combinações das 4^10 = 1.048.576
// possíveis (padrão: 7, ~150k combinações — rápido e representativo).
import 'dart:io';

import 'package:goias_app/features/arena/games/player_identity/domain/bragantino_player_identity_references.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_archetype_descriptions.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_engine.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_models.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_questions.dart';

const _references = bragantinoPlayerIdentityReferences;
final _engine = PlayerIdentityEngine(_references);

void main(List<String> args) {
  final sampleEvery = args.isNotEmpty ? int.parse(args.first) : 7;
  const questions = playerIdentityQuestions;
  final optionCounts = questions.map((q) => q.options.length).toList();
  final total = optionCounts.fold<int>(1, (a, b) => a * b);

  stdout.writeln(
    'Que Craque É Você? (Bragantino) — calibração ($total combinações, '
    'amostrando 1 a cada $sampleEvery)',
  );

  final archetypeCounts = <PlayerIdentityArchetype, int>{
    for (final a in PlayerIdentityArchetype.values) a: 0,
  };
  final top1Counts = <String, int>{for (final p in _references) p.id: 0};
  final top3Counts = <String, int>{for (final p in _references) p.id: 0};
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
    if (combo % sampleEvery != 0) return;
    final answers = [
      for (var i = 0; i < questions.length; i++)
        questions[i].options[indices[i]],
    ];
    final result = _engine.computeResult(answers);
    evaluated++;
    archetypeCounts[result.archetype] = archetypeCounts[result.archetype]! + 1;
    final closest = result.closestReferences;
    top1Counts[closest[0].reference.id] = top1Counts[closest[0].reference.id]! + 1;
    for (final a in closest) {
      top3Counts[a.reference.id] = top3Counts[a.reference.id]! + 1;
    }
    final a1 = closest[0].affinity;
    final a2 = closest[1].affinity;
    final a3 = closest[2].affinity;
    top1Aff.add(a1);
    top2Aff.add(a2);
    top3Aff.add(a3);
    if (a1.round() == a2.round() && a2.round() == a3.round()) tieVisual++;
    if ((a1 - a2).abs() <= 1) top1Top2Within1++;
    if ((a1 - a3).abs() <= 3) allWithin3++;
  }

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

  double mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;

  stdout.writeln('Combinações avaliadas: $evaluated');
  stdout.writeln();

  stdout.writeln('1) Distribuição de arquétipos:');
  final archetypeEntries = archetypeCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in archetypeEntries) {
    final pct = (entry.value / evaluated * 100).toStringAsFixed(2);
    stdout.writeln('   ${entry.key.displayName.padRight(16)} $pct%  (${entry.value})');
  }
  stdout.writeln();

  stdout.writeln('2) Frequência de cada jogador como #1:');
  final top1Entries = top1Counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in top1Entries) {
    final p = _references.firstWhere((p) => p.id == entry.key);
    final pct = (entry.value / evaluated * 100).toStringAsFixed(2);
    stdout.writeln('   ${p.name.padRight(28)} $pct%  (${entry.value})');
  }
  stdout.writeln();

  stdout.writeln('3) Frequência de cada jogador no Top 3:');
  final top3Entries = top3Counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final entry in top3Entries) {
    final p = _references.firstWhere((p) => p.id == entry.key);
    final pct = (entry.value / evaluated * 100).toStringAsFixed(2);
    stdout.writeln('   ${p.name.padRight(28)} $pct%  (${entry.value})');
  }
  stdout.writeln();

  stdout.writeln('4) Afinidade média Top1/Top2/Top3 e gaps:');
  stdout.writeln('   Top1 médio: ${mean(top1Aff).toStringAsFixed(2)}%');
  stdout.writeln('   Top2 médio: ${mean(top2Aff).toStringAsFixed(2)}%');
  stdout.writeln('   Top3 médio: ${mean(top3Aff).toStringAsFixed(2)}%');
  stdout.writeln('   Gap médio Top1→Top2: ${(mean(top1Aff) - mean(top2Aff)).toStringAsFixed(2)} pontos');
  stdout.writeln('   Gap médio Top2→Top3: ${(mean(top2Aff) - mean(top3Aff)).toStringAsFixed(2)} pontos');
  stdout.writeln();

  stdout.writeln('5) Empates/compressão:');
  stdout.writeln('   Empate visual (Top1==Top2==Top3 arredondado): ${(tieVisual / evaluated * 100).toStringAsFixed(2)}%');
  stdout.writeln('   Top1/Top2 a <=1 ponto: ${(top1Top2Within1 / evaluated * 100).toStringAsFixed(2)}%');
  stdout.writeln('   Top1/Top2/Top3 todos dentro de 3 pontos: ${(allWithin3 / evaluated * 100).toStringAsFixed(2)}%');
  stdout.writeln();

  final neverTop1 = top1Entries.where((e) => e.value == 0).toList();
  stdout.writeln('6) Jogadores que NUNCA aparecem como #1:');
  stdout.writeln(
    neverTop1.isEmpty
        ? '   (nenhum)'
        : neverTop1.map((e) => '   ${_references.firstWhere((p) => p.id == e.key).name}').join('\n'),
  );
  stdout.writeln();

  final dominant = top1Entries.where((e) => e.value / evaluated > 0.20).toList();
  stdout.writeln('7) Jogadores excessivamente dominantes como #1 (>20%):');
  stdout.writeln(
    dominant.isEmpty
        ? '   (nenhum)'
        : dominant
              .map(
                (e) =>
                    '   ${_references.firstWhere((p) => p.id == e.key).name} — '
                    '${(e.value / evaluated * 100).toStringAsFixed(1)}%',
              )
              .join('\n'),
  );
}
