// Valida supabase/bragantino_guess_players.sql (Quem Vestiu o Manto?)
// antes de qualquer aplicação no Supabase: club_id correto, sem colisão de
// id com o Goiás, e a regra central desta rodada — nenhum jogador vira
// `data_status='verified'` sem academy_club E club_debut_year E foto
// resolvida (ver GuessPlayer.eligibleAsSecret).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';

void main() {
  final sql = File('supabase/bragantino_guess_players.sql').readAsStringSync();
  final clubId = bragantinoClubConfig.identity.canonicalClubId;

  test('50 cards no arquivo, todos com o club_id do Bragantino', () {
    final matches = RegExp(
      "\\('(braga_manto_\\d+)', '$clubId'",
    ).allMatches(sql);
    expect(matches.length, 50);
  });

  test('nenhuma linha usa o club_id do Goiás', () {
    expect(sql, isNot(contains(goiasClubConfig.identity.canonicalClubId)));
  });

  test('só "verified" quando academy_club, club_debut_year e photo_key das 10 '
      'atuais estão todos presentes — nunca inventado pra fechar o card', () {
    final escapedClubId = RegExp.escape(clubId);
    final rowRe = RegExp(
      "\\('(braga_manto_\\d+)', '$escapedClubId', '[^']*', '[^']*', "
      "'\\[[^\\]]*\\]'::jsonb, (?:'[a-z]+'|null), (\\d+), ('[^']*'|null), "
      "(\\d+|null), '([a-z_-]+)', '(verified|incomplete)', \\d+\\)",
    );
    final currentPhotoKeys = bragantinoClubConfig.assets.guessPlayerPhotos.keys
        .toSet();
    var verifiedCount = 0;
    for (final m in rowRe.allMatches(sql)) {
      final academyClub = m.group(3);
      final debutYear = m.group(4);
      final photoKey = m.group(5)!;
      final status = m.group(6);
      if (status == 'verified') {
        verifiedCount++;
        expect(academyClub, isNot('null'), reason: m.group(1));
        expect(debutYear, isNot('null'), reason: m.group(1));
        expect(
          currentPhotoKeys,
          contains(photoKey),
          reason: '${m.group(1)}: foto tem que resolver de verdade',
        );
      }
    }
    expect(
      verifiedCount,
      1,
      reason: 'hoje só o Tiago Volpi deveria bater nas 4 dicas + foto',
    );
  });

  test('nenhum id colide com o seed do Goiás', () {
    final goiasSql = File('supabase/guess_players.sql').readAsStringSync();
    final goiasIds = RegExp(
      r"\('([a-z_0-9]+)',",
    ).allMatches(goiasSql).map((m) => m.group(1)).toSet();
    final bragaIds = RegExp(
      "\\('(braga_manto_\\d+)', '$clubId'",
    ).allMatches(sql).map((m) => m.group(1)).toSet();
    expect(
      bragaIds,
      hasLength(50),
      reason: 'sanity: a regex tem que achar as 50 linhas',
    );
    expect(bragaIds.intersection(goiasIds), isEmpty);
  });
}
