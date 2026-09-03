import 'dart:convert';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/arena/games/career_path/career_models.dart';
import 'package:goias_app/features/arena/games/career_path/data/supabase_career_path_storage.dart';
import 'package:goias_app/features/arena/games/lineup/data/supabase_lineup_storage.dart';
import 'package:goias_app/features/arena/games/lineup/lineup_models.dart';
import 'package:goias_app/features/arena/games/player_identity/data/supabase_player_identity_repository.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_engine.dart';
import 'package:goias_app/features/arena/games/player_identity/domain/player_identity_questions.dart';
import 'package:goias_app/features/arena/games/quiz/data/quiz_progress_repository.dart';
import 'package:goias_app/features/arena/games/quiz/quiz_models.dart';
import 'package:goias_app/features/arena/games/tactical_identity/data/supabase_tactical_identity_repository.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_engine.dart';
import 'package:goias_app/features/arena/games/tactical_identity/domain/tactical_identity_questions.dart';
import 'package:goias_app/features/arena/ranking/data/supabase_arena_ranking_repository.dart';
import 'package:goias_app/features/arena/ranking/domain/ranking_entities.dart';
import 'package:goias_app/features/crowd_lineup/data/supabase_crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/domain/lineup_vote.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/standing.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/membership/data/membership_plans_catalog.dart';
import 'package:goias_app/features/membership/data/supabase_membership_repository.dart';
import 'package:goias_app/features/membership/domain/entities/membership_registration_data.dart';
import 'package:goias_app/features/notifications/data/supabase_notification_repository.dart';
import 'package:goias_app/features/store/data/supabase_store_orders_repository.dart';
import 'package:goias_app/features/store/domain/entities/customer.dart';
import 'package:goias_app/features/store/domain/entities/shipping.dart';
import 'package:goias_app/features/store/domain/repositories/store_orders_repository.dart';
import 'package:goias_app/features/ticket/data/mock_ticket_repository.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'capturing_http_client.dart';
import 'synthetic_club_config.dart';

/// M3.2 — mesma técnica de prova real da M3.1 (`CapturingHttpClient`, um
/// `http.Client` de verdade injetado no `SupabaseClient` real via `httpClient:`,
/// nunca um framework de mock): captura a URL/corpo que o `postgrest`
/// monta de verdade a partir de `.eq()`/`.insert()`/`.upsert()`/`.update()`/
/// `.rpc()`, provando que `club_id`/`p_club_id` chega na query/payload —
/// nunca só "o método não lançou".
///
/// `_authedClient` faz o `SupabaseClient.auth` "logar" sem tocar rede:
/// `recoverSession` só faz uma chamada de rede se a sessão estiver expirada
/// (`Session.isExpired`), e um `access_token` que não é um JWT de verdade
/// faz `expiresAt` cair pra `null` (decode falha, capturado em try/catch no
/// próprio pacote) — `isExpired` então é `false` e a sessão é só salva em
/// memória (`_saveSession`, puro estado local, 0 I/O).
Future<SupabaseClient> _authedClient(
  http.Client httpClient, {
  String uid = 'u1',
}) async {
  final client = SupabaseClient(
    'https://example.supabase.co',
    'anon-key',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: httpClient,
  );
  await client.auth.recoverSession(
    jsonEncode({
      'access_token': 'not-a-real-jwt',
      'token_type': 'bearer',
      'refresh_token': 'not-a-real-refresh-token',
      'user': {
        'id': uid,
        'aud': 'authenticated',
        'created_at': '2024-01-01T00:00:00Z',
      },
    }),
  );
  return client;
}

/// Lê o corpo capturado como o primeiro objeto de linha — RPC manda um
/// objeto puro; insert/upsert em lote manda uma lista de objetos.
Map<String, dynamic> _firstRow(dynamic bodyJson) {
  if (bodyJson is List) return bodyJson.first as Map<String, dynamic>;
  return bodyJson as Map<String, dynamic>;
}

class _FakeFootballRepository implements FootballRepository {
  _FakeFootballRepository(this.match);
  final Match match;

  @override
  Future<Result<({Match? nextMatch, List<Match> recentResults})>>
  getActiveClubSnapshot() async =>
      Success((nextMatch: match, recentResults: const []));

  @override
  Future<Result<List<Standing>>> getStandings() async => const Success([]);

  @override
  Future<
    Result<
      ({List<Match> matches, String? roundLabel, bool hasPrevious, bool hasNext})
    >
  >
  getCurrentRound({int offset = 0}) => throw UnimplementedError();

  @override
  Future<Result<List<Match>>> getSeasonFixtures() => throw UnimplementedError();

  @override
  Future<
    Result<
      ({
        Match match,
        List<MatchEvent> events,
        MatchLineups? lineups,
        List<MatchStat> stats,
      })
    >
  >
  getMatchDetails(String fixtureId) => throw UnimplementedError();
}

const _fakeMatch = Match(
  id: 'm1',
  competition: 'Brasileirão Série B',
  round: '10',
  homeTeam: Team(id: 1, name: 'Goiás', shortName: 'GOI', color: Colors.green),
  awayTeam: Team(id: 2, name: 'Adversário', shortName: 'ADV', color: Colors.blue),
  stadium: 'Serra Dourada',
  status: MatchStatus.scheduled,
);

void main() {
  late CapturingHttpClient httpClient;

  setUp(() {
    httpClient = CapturingHttpClient();
  });

  group('Arena ranking — RPCs tenant-aware carregam p_club_id no payload real', () {
    for (final (label, config) in [
      ('Goiás', goiasClubConfig),
      ('club-b (sintético)', syntheticClubBConfig),
    ]) {
      test('recordScore ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseArenaRankingRepository(client, config);
        await repo.recordScore(
          gameId: 'quiz',
          itemId: 'q1',
          eventType: 'first_try_correct',
        );
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['p_club_id'],
          config.identity.canonicalClubId,
        );
        expect(httpClient.lastRequestUrl.toString(), contains('arena_record_score_for_club'));
      });

      test('getRanking ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseArenaRankingRepository(client, config);
        await repo.getRanking(RankingPeriod.allTime);
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['p_club_id'],
          config.identity.canonicalClubId,
        );
        expect(httpClient.lastRequestUrl.toString(), contains('arena_ranking_for_club'));
      });

      test('getMyRank ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseArenaRankingRepository(client, config);
        await repo.getMyRank(RankingPeriod.allTime);
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['p_club_id'],
          config.identity.canonicalClubId,
        );
        expect(httpClient.lastRequestUrl.toString(), contains('arena_my_rank_for_club'));
      });

      test('getUserDetail ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseArenaRankingRepository(client, config);
        await repo.getUserDetail(
          const RankingEntry(
            rank: 1,
            userId: 'other-user',
            name: 'X',
            avatarUrl: null,
            isMember: false,
            totalScore: 10,
            isMe: false,
          ),
        );
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['p_club_id'],
          config.identity.canonicalClubId,
        );
        expect(httpClient.lastRequestUrl.toString(), contains('arena_user_detail_for_club'));
      });
    }

    test('club-b nunca manda o UUID do Goiás em nenhuma das 4 RPCs', () async {
      final client = await _authedClient(httpClient);
      final repo = SupabaseArenaRankingRepository(client, syntheticClubBConfig);
      await repo.getRanking(RankingPeriod.allTime);
      final sent = _firstRow(httpClient.lastRequestBodyJson)['p_club_id'] as String;
      expect(sent, syntheticClubBConfig.identity.canonicalClubId);
      expect(sent, isNot(goiasClubConfig.identity.canonicalClubId));
    });
  });

  group('Membership — RPCs tenant-aware', () {
    for (final (label, config) in [
      ('Goiás', goiasClubConfig),
      ('club-b (sintético)', syntheticClubBConfig),
    ]) {
      test('getMyMembership ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseMembershipRepository(client, config);
        await repo.getMyMembership();
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['p_club_id'],
          config.identity.canonicalClubId,
        );
        expect(httpClient.lastRequestUrl.toString(), contains('get_my_membership_for_club'));
      });

      test('submitRegistration/subscribe_to_plan_for_club ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseMembershipRepository(client, config);
        final plan = MembershipPlansCatalog.plans.first;
        await repo.submitRegistration(
          plan: plan,
          price: plan.defaultPrice,
          data: const MembershipRegistrationData(),
          regulationVersion: 'v1',
          regulationAcceptedAt: DateTime.now(),
        );
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['p_club_id'],
          config.identity.canonicalClubId,
        );
        expect(httpClient.lastRequestUrl.toString(), contains('subscribe_to_plan_for_club'));
      });
    }
  });

  group('Crowd Lineup — write direto + RPC tenant-aware', () {
    for (final (label, config) in [
      ('Goiás', goiasClubConfig),
      ('club-b (sintético)', syntheticClubBConfig),
    ]) {
      test('submitVote grava club_id no upsert real ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseCrowdLineupRepository(client, config);
        await repo.submitVote(
          'm1',
          const LineupVote(formationId: '4-3-3', playerIdBySlot: {0: 'p1'}),
        );
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['club_id'],
          config.identity.canonicalClubId,
        );
      });

      test('getCrowdLineup chama crowd_lineup_for_club com p_club_id ($label)', () async {
        httpClient = CapturingHttpClient(responseBody: '{}');
        final client = await _authedClient(httpClient);
        final repo = SupabaseCrowdLineupRepository(client, config);
        await repo.getCrowdLineup('m1');
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['p_club_id'],
          config.identity.canonicalClubId,
        );
        expect(httpClient.lastRequestUrl.toString(), contains('crowd_lineup_for_club'));
      });
    }
  });

  group('Store — RPC tenant-aware + reads filtrados', () {
    for (final (label, config) in [
      ('Goiás', goiasClubConfig),
      ('club-b (sintético)', syntheticClubBConfig),
    ]) {
      test('createOrder chama create_store_order_for_club com p_club_id ($label)', () async {
        httpClient = CapturingHttpClient(responseBody: '{}');
        final client = await _authedClient(httpClient);
        final repo = SupabaseStoreOrdersRepository(client, config);
        await repo.createOrder(
          items: const [],
          identification: const CustomerIdentification(
            fullName: 'Lucas',
            cpf: '11144477735',
            email: 'lucas@example.com',
            phone: '62999998888',
          ),
          fulfillmentMethod: FulfillmentMethod.pickup,
          payment: const PaymentSimulationInput(method: PaymentMethod.pix),
          subtotal: 10,
          discountAmount: 0,
        );
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['p_club_id'],
          config.identity.canonicalClubId,
        );
        expect(httpClient.lastRequestUrl.toString(), contains('create_store_order_for_club'));
      });
    }

    test('getOrders filtra club_id na query real', () async {
      final client = await _authedClient(httpClient);
      final repo = SupabaseStoreOrdersRepository(client, goiasClubConfig);
      await repo.getOrders();
      expect(
        httpClient.lastRequestUrl.toString(),
        contains('club_id=eq.${goiasClubConfig.identity.canonicalClubId}'),
      );
    });
  });

  group('Notificações — preferences por usuário+clube (ROW_SCOPE pronto, KEY_SCOPE bloqueado)', () {
    for (final (label, config) in [
      ('Goiás', goiasClubConfig),
      ('club-b (sintético)', syntheticClubBConfig),
    ]) {
      test('updatePreferences grava club_id no upsert real ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseNotificationRepository(client, config);
        await repo.updatePreferences(matchesEnabled: false);
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['club_id'],
          config.identity.canonicalClubId,
        );
      });
    }

    test('getPreferences filtra club_id na query real', () async {
      final client = await _authedClient(httpClient);
      final repo = SupabaseNotificationRepository(client, goiasClubConfig);
      await repo.getPreferences();
      expect(
        httpClient.lastRequestUrl.toString(),
        contains('club_id=eq.${goiasClubConfig.identity.canonicalClubId}'),
      );
    });
  });

  group('Ingressos — check-in/compra gravam club_id nas 3 tabelas', () {
    for (final (label, config) in [
      ('Goiás', goiasClubConfig),
      ('club-b (sintético)', syntheticClubBConfig),
    ]) {
      test('checkIn grava club_id em ticket_checkin_decisions e tickets ($label)', () async {
        httpClient = CapturingHttpClient(responseBody: '{"id":"t1"}');
        final client = await _authedClient(httpClient);
        final repo = MockTicketRepository(client, _FakeFootballRepository(_fakeMatch), config);
        await repo.checkIn(
          matchId: 'm1',
          sectorId: 'cadeiras',
          holderName: 'Lucas',
          holderDocument: '11144477735',
        );
        // 2 writes acontecem (ticket_checkin_decisions upsert, tickets
        // upsert) — os 2 corpos capturados precisam ambos ter club_id.
        final bodies = httpClient.requestBodies
            .where((b) => b != null && b.isNotEmpty)
            .map((b) => _firstRow(jsonDecode(b!)))
            .toList();
        expect(bodies, isNotEmpty);
        for (final row in bodies) {
          if (row.containsKey('user_id')) {
            expect(row['club_id'], config.identity.canonicalClubId, reason: '$row');
          }
        }
      });

      test('purchase grava club_id em ticket_orders e tickets ($label)', () async {
        httpClient = CapturingHttpClient(responseBody: '{"id":"o1","created_at":"2026-01-01T00:00:00Z"}');
        final client = await _authedClient(httpClient);
        final repo = MockTicketRepository(client, _FakeFootballRepository(_fakeMatch), config);
        await repo.purchase(
          matchId: 'm1',
          items: const [
            TicketOrderItem(
              sectorId: 'cadeiras',
              sectorName: 'Cadeiras',
              venueLabel: 'Superior',
              gate: 'A',
              categoryId: 'inteira',
              categoryLabel: 'Inteira',
              quantity: 1,
              unitPrice: 80,
            ),
          ],
          holders: const [TicketHolder(name: 'Lucas', document: '11144477735')],
        );
        final bodies = httpClient.requestBodies
            .where((b) => b != null && b.isNotEmpty)
            .map((b) => _firstRow(jsonDecode(b!)))
            .toList();
        expect(bodies, isNotEmpty);
        for (final row in bodies) {
          if (row.containsKey('user_id')) {
            expect(row['club_id'], config.identity.canonicalClubId, reason: '$row');
          }
        }
      });
    }
  });

  group('Progresso de conteúdo (Quiz/Escalação/Adivinhe/Selecionado) — club_id no write real', () {
    for (final (label, config) in [
      ('Goiás', goiasClubConfig),
      ('club-b (sintético)', syntheticClubBConfig),
    ]) {
      test('QuizProgressRepository.recordAnswer ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = QuizProgressRepository(client, config);
        await repo.recordAnswer(
          questionId: 'q1',
          difficulty: QuizDifficulty.torcedor,
          wasCorrect: true,
        );
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['club_id'],
          config.identity.canonicalClubId,
        );
      });

      test('SupabaseCareerPathStorage.save ($label)', () async {
        final client = await _authedClient(httpClient);
        final storage = SupabaseCareerPathStorage(client, config);
        await storage.save(
          CareerRoundState(playerId: 'p1', startedAt: DateTime.now()),
        );
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['club_id'],
          config.identity.canonicalClubId,
        );
      });

      test('SupabaseCareerPathStorage.saveSelectedPlayerId ($label)', () async {
        final client = await _authedClient(httpClient);
        final storage = SupabaseCareerPathStorage(client, config);
        await storage.saveSelectedPlayerId('p1');
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['club_id'],
          config.identity.canonicalClubId,
        );
      });

      test('SupabaseLineupStorage.save ($label)', () async {
        final client = await _authedClient(httpClient);
        final storage = SupabaseLineupStorage(client, config);
        await storage.save(
          LineupGameState(matchId: 'm1', startedAt: DateTime.now()),
        );
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['club_id'],
          config.identity.canonicalClubId,
        );
      });

      test('SupabaseLineupStorage.saveSelectedMatchId ($label)', () async {
        final client = await _authedClient(httpClient);
        final storage = SupabaseLineupStorage(client, config);
        await storage.saveSelectedMatchId('m1');
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['club_id'],
          config.identity.canonicalClubId,
        );
      });
    }
  });

  group('Identidades (Craque/Técnico) — club_id no write real', () {
    for (final (label, config) in [
      ('Goiás', goiasClubConfig),
      ('club-b (sintético)', syntheticClubBConfig),
    ]) {
      test('SupabasePlayerIdentityRepository.saveResult ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabasePlayerIdentityRepository(client, config);
        final options = [
          for (final q in playerIdentityQuestions) q.options.first,
        ];
        final result = const PlayerIdentityEngine().computeResult(options);
        await repo.saveResult(result);
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['club_id'],
          config.identity.canonicalClubId,
        );
      });

      test('SupabaseTacticalIdentityRepository.saveResult ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseTacticalIdentityRepository(client, config);
        final options = [
          for (final q in tacticalIdentityQuestions) q.options.first,
        ];
        final result = const TacticalIdentityEngine().computeResult(options);
        await repo.saveResult(result);
        expect(
          _firstRow(httpClient.lastRequestBodyJson)['club_id'],
          config.identity.canonicalClubId,
        );
      });
    }
  });

  // M3.4: prova que o `on_conflict=` da query REAL passou a ser tenant-aware
  // (inclui club_id, batendo com as bridges da M2.2B-A) — não só que o
  // payload tem club_id. E que o check-in de sócio (índice PARCIAL) foi por
  // uma RPC dedicada com p_club_id e sem p_user_id.
  group('M3.4 — conflict targets tenant-aware (on_conflict com club_id)', () {
    final goiasUuid = goiasClubConfig.identity.canonicalClubId;
    Uri urlWith(String needle) => httpClient.requestUrls.firstWhere(
          (u) => u.toString().contains(needle),
          orElse: () => Uri.parse('about:blank'),
        );

    for (final (label, config) in [
      ('Goiás', goiasClubConfig),
      ('club-b (sintético)', syntheticClubBConfig),
    ]) {
      test('match_lineup_votes: on_conflict club_id,match_id,user_id + valor de club_id difere por clube ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseCrowdLineupRepository(client, config);
        await repo.submitVote(
          'm1',
          const LineupVote(formationId: '4-3-3', playerIdBySlot: {0: 'p1'}),
        );
        expect(Uri.decodeFull(urlWith('on_conflict').toString()),
            contains('on_conflict=club_id,match_id,user_id'));
        final clubId = _firstRow(httpClient.lastRequestBodyJson)['club_id'];
        expect(clubId, config.identity.canonicalClubId);
        if (config == syntheticClubBConfig) expect(clubId, isNot(goiasUuid));
      });

      test('user_notification_preferences: on_conflict user_id,club_id ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabaseNotificationRepository(client, config);
        await repo.updatePreferences(matchesEnabled: false);
        expect(Uri.decodeFull(urlWith('on_conflict').toString()),
            contains('on_conflict=user_id,club_id'));
      });

      test('player_identity_results: on_conflict user_id,club_id ($label)', () async {
        final client = await _authedClient(httpClient);
        final repo = SupabasePlayerIdentityRepository(client, config);
        final options = [
          for (final q in playerIdentityQuestions) q.options.first,
        ];
        await repo.saveResult(const PlayerIdentityEngine().computeResult(options));
        expect(Uri.decodeFull(urlWith('on_conflict').toString()),
            contains('on_conflict=user_id,club_id'));
      });

      test('check-in de sócio: tcd on_conflict tenant + RPC dedicada com p_club_id e SEM p_user_id ($label)', () async {
        httpClient = CapturingHttpClient(responseBody: '{"id":"t1"}');
        final client = await _authedClient(httpClient);
        final repo = MockTicketRepository(
          client,
          _FakeFootballRepository(_fakeMatch),
          config,
        );
        await repo.checkIn(
          matchId: 'm1',
          sectorId: 'cadeiras',
          holderName: 'Lucas',
          holderDocument: '11144477735',
        );
        // ticket_checkin_decisions: upsert direto tenant-aware
        final tcdUrl = httpClient.requestUrls
            .firstWhere((u) => u.toString().contains('ticket_checkin_decisions'));
        expect(Uri.decodeFull(tcdUrl.toString()),
            contains('on_conflict=club_id,user_id,match_id'));
        // check-in de sócio vai pela RPC dedicada (índice parcial, sem
        // onConflict direto)
        final rpcBodies = httpClient.requestBodies
            .where((b) => b != null && b.contains('p_club_id'))
            .cast<String>()
            .toList();
        expect(rpcBodies, isNotEmpty,
            reason: 'esperava a RPC upsert_membership_checkin_ticket_for_club');
        expect(
          httpClient.requestUrls.any((u) =>
              u.toString().contains('upsert_membership_checkin_ticket_for_club')),
          isTrue,
        );
        final decoded = jsonDecode(rpcBodies.first) as Map<String, dynamic>;
        expect(decoded['p_club_id'], config.identity.canonicalClubId);
        expect(decoded.containsKey('p_user_id'), isFalse);
      });
    }
  });
}
