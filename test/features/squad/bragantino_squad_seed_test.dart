// Valida o seed do elenco do Bragantino (supabase/bragantino_squad_members
// .sql) ANTES de qualquer nova aplicação no banco — o arquivo é a fonte
// versionada do que está em produção no projeto Supabase do clube.
// Cobre o que o app assume em runtime: posição dentro do catálogo canônico
// (nunca nomenclatura paralela), camisa única, e club_id do Bragantino em
// toda linha (jamais o do Goiás).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/features/squad/domain/position_groups.dart';

/// Uma linha do `values (...)` do seed, já com as aspas resolvidas.
class _SeedRow {
  _SeedRow(this.fields);
  final List<String> fields;

  String get id => fields[0];
  String get clubId => fields[1];
  String get name => fields[2];
  String get shirt => fields[4];
  String get position => fields[5];
  String get positionGroup => fields[6];
}

List<_SeedRow> _parseSeed(String sql) {
  final body = sql.split('values').last.split('on conflict').first;
  final rows = <String>[];
  var depth = 0;
  var inString = false;
  var current = StringBuffer();
  for (var i = 0; i < body.length; i++) {
    final ch = body[i];
    if (inString) {
      if (ch == "'" && i + 1 < body.length && body[i + 1] == "'") {
        current.write("''");
        i++;
        continue;
      }
      if (ch == "'") inString = false;
      current.write(ch);
      continue;
    }
    if (ch == "'") {
      inString = true;
      current.write(ch);
    } else if (ch == '(') {
      depth++;
      if (depth == 1) {
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    } else if (ch == ')') {
      depth--;
      if (depth == 0) {
        rows.add(current.toString());
      } else {
        current.write(ch);
      }
    } else if (depth > 0) {
      current.write(ch);
    }
  }
  return rows.map((row) => _SeedRow(_splitFields(row))).toList();
}

List<String> _splitFields(String row) {
  final out = <String>[];
  final current = StringBuffer();
  var inString = false;
  for (var i = 0; i < row.length; i++) {
    final ch = row[i];
    if (inString) {
      if (ch == "'" && i + 1 < row.length && row[i + 1] == "'") {
        current.write("'");
        i++;
        continue;
      }
      if (ch == "'") {
        inString = false;
      } else {
        current.write(ch);
      }
      continue;
    }
    if (ch == "'") {
      inString = true;
    } else if (ch == ',') {
      out.add(current.toString().trim());
      current.clear();
    } else {
      current.write(ch);
    }
  }
  out.add(current.toString().trim());
  return out;
}

void main() {
  final sql = File('supabase/bragantino_squad_members.sql').readAsStringSync();
  final rows = _parseSeed(sql);

  test('o seed tem o elenco completo (30 atletas)', () {
    expect(rows, hasLength(30));
  });

  test('toda linha usa o club_id do Bragantino, nunca o do Goiás', () {
    for (final row in rows) {
      expect(
        row.clubId,
        bragantinoClubConfig.identity.canonicalClubId,
        reason: row.name,
      );
      expect(row.clubId, isNot(goiasClubConfig.identity.canonicalClubId));
    }
  });

  test('todo position_group está no catálogo canônico do projeto', () {
    for (final row in rows) {
      expect(
        positionGroupOrder,
        contains(row.positionGroup),
        reason: '${row.name}: "${row.positionGroup}" fora do catálogo',
      );
    }
  });

  test('toda linha tem posição granular preenchida', () {
    for (final row in rows) {
      expect(row.position, isNotEmpty, reason: row.name);
      expect(row.position, isNot('null'), reason: row.name);
    }
  });

  test('camisas preenchidas e sem duplicata', () {
    final shirts = rows.map((row) => row.shirt).toList();
    expect(shirts.where((s) => s == 'null'), isEmpty);
    expect(shirts.toSet(), hasLength(rows.length));
  });

  test('ids únicos e sem colisão com as chaves de foto do Goiás', () {
    final ids = rows.map((row) => row.id).toSet();
    expect(ids, hasLength(rows.length));
    final goiasPhotoKeys = goiasClubConfig.assets.squadPhotos.keys.toSet();
    expect(
      ids.intersection(goiasPhotoKeys),
      isEmpty,
      reason: 'um id em comum faria o card exibir a foto de um atleta do Goiás',
    );
  });
}
