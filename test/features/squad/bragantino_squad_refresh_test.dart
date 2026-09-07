// Valida o refresh de 2026-09-07 (supabase/bragantino_squad_members_2026_09
// _refresh.sql): Wallace Yan entra como novo atleta ativo; Pedro Henrique é
// marcado inativo (saída pro Al Ettifaq), NUNCA removido/apagado do SQL.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';

void main() {
  final sql = File(
    'supabase/bragantino_squad_members_2026_09_refresh.sql',
  ).readAsStringSync();
  final clubId = bragantinoClubConfig.identity.canonicalClubId;

  test('insere Wallace Yan com o club_id do Bragantino', () {
    expect(sql, contains("'wallace-yan', '$clubId'"));
  });

  test(
    'marca Pedro Henrique inativo — nunca um delete/remove da linha dele',
    () {
      expect(sql, contains("where id = 'pedro-henrique'"));
      expect(sql, contains('active = false'));
      expect(sql, contains("departed_to = 'Al Ettifaq'"));
      expect(sql.toLowerCase(), isNot(contains('delete')));
    },
  );

  test('depende das colunas de ciclo de vida existirem antes', () {
    final lifecycleSql = File(
      'supabase/squad_members_add_lifecycle_columns.sql',
    ).readAsStringSync();
    expect(lifecycleSql, contains('add column if not exists active'));
    expect(lifecycleSql, contains('add column if not exists departed_at'));
    expect(lifecycleSql, contains('add column if not exists departed_to'));
  });
}
