import 'package:flutter/material.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/theme/app_assets.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

/// Fonte central de dados mockados do app. Os repositórios mock leem daqui
/// em vez de espalhar dados fictícios pela UI — quando integrarmos com a API
/// real, esse arquivo inteiro deixa de ser usado.
class MockData {
  const MockData._();

  // Id real do Goiás no OneFootball — vem de `goiasClubConfig.integrations.
  // oneFootballTeamId` (M1), nunca mais um literal duplicado aqui.
  static final goias = Team(
    id: goiasClubConfig.integrations.oneFootballTeamId,
    name: 'Goiás',
    shortName: 'GO',
    color: const Color(0xFF004C1B),
    crestAsset: AppAssets.goiasCrest,
  );

  static const athleticoPr = Team(
    id: 2,
    name: 'Athletico-PR',
    shortName: 'CAP',
    color: Color(0xFFC0392B),
  );

  static const coritiba = Team(
    id: 3,
    name: 'Coritiba',
    shortName: 'CFC',
    color: Color(0xFF1F6F4A),
  );

  static const vilaNova = Team(
    id: 4,
    name: 'Vila Nova',
    shortName: 'VNO',
    color: Color(0xFFB01128),
  );

  static const avai = Team(
    id: 5,
    name: 'Avaí',
    shortName: 'AVA',
    color: Color(0xFF1C4B9C),
  );

  static const botafogoSp = Team(
    id: 6,
    name: 'Botafogo-SP',
    shortName: 'BSP',
    color: Color(0xFF6E6E6E),
  );

  static const novorizontino = Team(
    id: 7,
    name: 'Novorizontino',
    shortName: 'NOV',
    color: Color(0xFFD32F2F),
  );

  /// IDs mockados de partidas com "venda aberta" — usado só pela Home
  /// (ticket ainda não tem integração real; ver [[project_goias_app_architecture]]).
  static const ticketsOpenMatchIds = {'m-next-1', 'm-next-3'};

  static final DateTime _now = DateTime.now();

  static List<Match> get matches {
    final today = DateTime(_now.year, _now.month, _now.day);
    return [
      Match(
        id: 'm-past-1',
        competition: 'Brasileirão Série B',
        round: 'Rodada 22',
        homeTeam: vilaNova,
        awayTeam: goias,
        stadium: 'Estádio Onésio Brasil Alvarenga',
        city: 'Goiânia',
        kickoff: today.subtract(const Duration(days: 4, hours: 3)),
        status: MatchStatus.finished,
        homeScore: 1,
        awayScore: 2,
      ),
      Match(
        id: 'm-next-1',
        competition: 'Brasileirão Série B',
        round: 'Rodada 23',
        homeTeam: goias,
        awayTeam: athleticoPr,
        stadium: 'Serrinha',
        city: 'Goiânia',
        kickoff: today.add(const Duration(days: 2, hours: 21, minutes: 30)),
        status: MatchStatus.scheduled,
      ),
      Match(
        id: 'm-next-2',
        competition: 'Brasileirão Série B',
        round: 'Rodada 24',
        homeTeam: coritiba,
        awayTeam: goias,
        stadium: 'Couto Pereira',
        city: 'Curitiba',
        kickoff: today.add(const Duration(days: 9, hours: 20)),
        status: MatchStatus.scheduled,
      ),
      Match(
        id: 'm-next-3',
        competition: 'Brasileirão Série B',
        round: 'Rodada 25',
        homeTeam: goias,
        awayTeam: avai,
        stadium: 'Serrinha',
        city: 'Goiânia',
        kickoff: today.add(const Duration(days: 16, hours: 21, minutes: 30)),
        status: MatchStatus.scheduled,
      ),
      Match(
        id: 'm-next-4',
        competition: 'Brasileirão Série B',
        round: 'Rodada 26',
        homeTeam: botafogoSp,
        awayTeam: goias,
        stadium: 'Santa Cruz',
        city: 'Ribeirão Preto',
        kickoff: today.add(const Duration(days: 23, hours: 20)),
        status: MatchStatus.scheduled,
      ),
      Match(
        id: 'm-next-5',
        competition: 'Brasileirão Série B',
        round: 'Rodada 27',
        homeTeam: goias,
        awayTeam: novorizontino,
        stadium: 'Serrinha',
        city: 'Goiânia',
        kickoff: today.add(const Duration(days: 30, hours: 21, minutes: 30)),
        status: MatchStatus.scheduled,
      ),
      Match(
        id: 'm-past-2',
        competition: 'Brasileirão Série B',
        round: 'Rodada 21',
        homeTeam: goias,
        awayTeam: novorizontino,
        stadium: 'Serrinha',
        city: 'Goiânia',
        kickoff: today.subtract(const Duration(days: 11, hours: 3)),
        status: MatchStatus.finished,
        homeScore: 2,
        awayScore: 0,
      ),
      Match(
        id: 'm-past-3',
        competition: 'Brasileirão Série B',
        round: 'Rodada 20',
        homeTeam: avai,
        awayTeam: goias,
        stadium: 'Ressacada',
        city: 'Florianópolis',
        kickoff: today.subtract(const Duration(days: 18, hours: 3)),
        status: MatchStatus.finished,
        homeScore: 1,
        awayScore: 1,
      ),
    ];
  }
}
