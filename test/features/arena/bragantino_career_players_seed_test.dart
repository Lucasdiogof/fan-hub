// Valida supabase/bragantino_career_players.sql (Adivinhe o Jogador) antes
// de qualquer aplicação no Supabase: club_id correto, sem colisão de id
// com o Goiás, período obrigatório em toda passagem, e nenhum ano
// inventado (o próprio conteúdo já vem marcado READY/PARTIAL — este teste
// só trava a mecânica do arquivo, não a pesquisa em si).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

List<Map<String, dynamic>> _extractClubCareers(String sql) {
  final re = RegExp(r"'(\[\{.*?\}\])'::jsonb, \d+\)");
  return re
      .allMatches(sql)
      .map((m) => m.group(1)!.replaceAll("''", "'"))
      .map((raw) => {'club_career': jsonDecode(raw) as List})
      .toList();
}

void main() {
  final sql = File('supabase/bragantino_career_players.sql').readAsStringSync();
  final clubId = bragantinoClubConfig.identity.canonicalClubId;

  test('27 jogadores no arquivo (20 READY + 7 PARTIAL de 30 pesquisados)', () {
    final matches = RegExp("\\('([a-z_0-9]+)', '$clubId'").allMatches(sql);
    expect(matches.length, 27);
  });

  test('toda linha usa o club_id do Bragantino, nunca o do Goiás', () {
    expect(sql, isNot(contains(goiasClubConfig.identity.canonicalClubId)));
  });

  test('toda passagem de carreira tem period e team preenchidos', () {
    for (final row in _extractClubCareers(sql)) {
      for (final entry in row['club_career'] as List) {
        final map = entry as Map<String, dynamic>;
        expect(map['period'], isNotEmpty);
        expect(map['team'], isNotEmpty);
      }
    }
  });

  test(
    'toda linha tem pelo menos 1 passagem marcada is_goias:true (destaque do Bragantino)',
    () {
      for (final row in _extractClubCareers(sql)) {
        final hasHighlight = (row['club_career'] as List)
            .cast<Map<String, dynamic>>()
            .any((e) => e['is_goias'] == true);
        expect(hasHighlight, isTrue, reason: jsonEncode(row));
      }
    },
  );

  test('nenhum id colide com o seed do Goiás', () {
    final goiasSql = File('supabase/career_players.sql').readAsStringSync();
    final goiasIds = RegExp(
      r"\('([a-z_0-9]+)',",
    ).allMatches(goiasSql).map((m) => m.group(1)).toSet();
    final bragaIds = RegExp(
      "\\('([a-z_0-9]+)', '$clubId'",
    ).allMatches(sql).map((m) => m.group(1)).toSet();
    expect(
      bragaIds,
      hasLength(27),
      reason: 'sanity: a regex tem que achar as 27 linhas',
    );
    expect(bragaIds.intersection(goiasIds), isEmpty);
  });
}
