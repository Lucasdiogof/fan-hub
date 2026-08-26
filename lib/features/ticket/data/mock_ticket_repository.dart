import 'package:flutter/material.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
import 'package:goias_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:goias_app/features/ticket/data/mock_ticket_fixture.dart';
import 'package:goias_app/features/ticket/data/ticket_error_mapper.dart';
import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/match_ticket_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_enums.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_event.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_order.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';
import 'package:goias_app/features/ticket/domain/repositories/ticket_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Implementação mock (sem API/pagamento reais) do módulo de Ingressos —
/// setores/preços/janelas vêm de `TicketFixture`, aplicados à partida REAL
/// devolvida por `FootballRepository` (nunca um "Goiás x São Bernardo"
/// hardcoded aqui). O que é do usuário (check-in, ingressos, pedidos) é
/// persistido no Supabase, no mesmo padrão de `SupabaseLineupStorage` —
/// troca futura por uma implementação com API real de ingressos não deve
/// exigir mudança nas telas, só nesta classe.
class MockTicketRepository implements TicketRepository {
  MockTicketRepository(
    this._client,
    this._footballRepository,
    this._profileRepository,
  );

  final SupabaseClient _client;
  final FootballRepository _footballRepository;
  final ProfileRepository _profileRepository;

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<Result<TicketEvent?>> getFeaturedEvent() async {
    try {
      final snapshotResult = await _footballRepository.getGoiasSnapshot();
      final Match? match;
      switch (snapshotResult) {
        case Success(:final data):
          match = data.nextMatch;
        case Error(:final failure):
          return Error(failure);
      }
      if (match == null) return const Success(null);

      final matchId = match.id.toString();
      final info = TicketFixture.infoFor(matchId);
      final now = DateTime.now();
      final saleStatus = computeSaleStatus(
        info: info,
        kickoff: match.kickoff,
        now: now,
      );

      final decisionRow = await _client
          .from('ticket_checkin_decisions')
          .select('decision, sector_id')
          .eq('user_id', _uid)
          .eq('match_id', matchId)
          .maybeSingle();

      final windowStatus = computeCheckInWindowStatus(
        info: info,
        kickoff: match.kickoff,
        now: now,
      );
      final CheckInStatus checkInStatus;
      String? confirmedSectorName;
      Ticket? checkInTicket;
      if (windowStatus == CheckInStatus.closed ||
          windowStatus == CheckInStatus.unavailable) {
        checkInStatus = windowStatus;
      } else if (decisionRow == null) {
        checkInStatus = CheckInStatus.available;
      } else if (decisionRow['decision'] == 'declined') {
        checkInStatus = CheckInStatus.declined;
      } else {
        checkInStatus = CheckInStatus.confirmed;
        final sectorId = decisionRow['sector_id'] as String?;
        confirmedSectorName = _findSector(info, sectorId)?.name;
        final ticketRow = await _client
            .from('tickets')
            .select()
            .eq('user_id', _uid)
            .eq('match_id', matchId)
            .eq('origin', 'membership_check_in')
            .eq('status', 'active')
            .maybeSingle();
        if (ticketRow != null) checkInTicket = _mapTicket(ticketRow);
      }

      final profileResult = await _profileRepository.getProfile();
      Ticket? myTicketForSelf;
      if (profileResult case Success(:final data)) {
        final cpf = data.cpf;
        if (cpf != null && cpf.isNotEmpty) {
          final ticketRow = await _client
              .from('tickets')
              .select()
              .eq('user_id', _uid)
              .eq('match_id', matchId)
              .eq('origin', 'purchase')
              .eq('status', 'active')
              .eq('holder_document', cpf)
              .maybeSingle();
          if (ticketRow != null) myTicketForSelf = _mapTicket(ticketRow);
        }
      }

      return Success(
        TicketEvent(
          match: match,
          info: info,
          saleStatus: saleStatus,
          checkInStatus: checkInStatus,
          confirmedSectorName: confirmedSectorName,
          checkInTicket: checkInTicket,
          myTicketForSelf: myTicketForSelf,
        ),
      );
    } catch (error) {
      return Error(mapTicketError(error));
    }
  }

  @override
  Future<Result<MatchSalesInfo?>> getMatchSalesInfo(String matchId) async {
    return Success(TicketFixture.salesInfoFor(matchId));
  }

  @override
  Future<Result<Ticket>> checkIn({
    required String matchId,
    required String sectorId,
    required String holderName,
    required String holderDocument,
  }) async {
    try {
      final match = await _requireMatch(matchId);
      if (match == null) {
        return const Error(ServerFailure('Partida não encontrada.'));
      }
      final sector = _findSector(TicketFixture.infoFor(matchId), sectorId);
      if (sector == null) {
        return const Error(ServerFailure('Setor não encontrado.'));
      }

      await _client.from('ticket_checkin_decisions').upsert({
        'user_id': _uid,
        'match_id': matchId,
        'decision': 'confirmed',
        'sector_id': sectorId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,match_id');

      final row = await _client
          .from('tickets')
          .upsert({
            'user_id': _uid,
            'match_id': matchId,
            'competition': match.competition,
            'round': match.round,
            'home_team_id': match.homeTeam.id,
            'home_team_name': match.homeTeam.name,
            'away_team_id': match.awayTeam.id,
            'away_team_name': match.awayTeam.name,
            'kickoff': match.kickoff?.toUtc().toIso8601String(),
            'stadium': match.stadium,
            'sector_id': sector.id,
            'sector_name': sector.name,
            'venue_label': sector.venueLabel,
            'gate': sector.gate,
            'category_label': null,
            'holder_name': holderName,
            'holder_document': holderDocument,
            'status': 'active',
            'origin': 'membership_check_in',
            'order_id': null,
            'price': null,
          }, onConflict: 'user_id,match_id')
          .select()
          .single();

      return Success(_mapTicket(row));
    } catch (error) {
      return Error(mapTicketError(error));
    }
  }

  @override
  Future<Result<void>> declineCheckIn(String matchId) async {
    try {
      await _client.from('ticket_checkin_decisions').upsert({
        'user_id': _uid,
        'match_id': matchId,
        'decision': 'declined',
        'sector_id': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'user_id,match_id');
      return const Success(null);
    } catch (error) {
      return Error(mapTicketError(error));
    }
  }

  @override
  Future<Result<void>> clearCheckInDecision(String matchId) async {
    try {
      await _client
          .from('ticket_checkin_decisions')
          .delete()
          .eq('user_id', _uid)
          .eq('match_id', matchId);
      return const Success(null);
    } catch (error) {
      return Error(mapTicketError(error));
    }
  }

  @override
  Future<Result<void>> undoCheckIn(String matchId) async {
    try {
      await _client
          .from('tickets')
          .update({'status': 'cancelled'})
          .eq('user_id', _uid)
          .eq('match_id', matchId)
          .eq('origin', 'membership_check_in')
          .eq('status', 'active');
      await _client
          .from('ticket_checkin_decisions')
          .delete()
          .eq('user_id', _uid)
          .eq('match_id', matchId);
      return const Success(null);
    } catch (error) {
      return Error(mapTicketError(error));
    }
  }

  @override
  Future<Result<TicketOrder>> purchase({
    required String matchId,
    required List<TicketOrderItem> items,
    required String holderName,
    required String holderDocument,
  }) async {
    try {
      final match = await _requireMatch(matchId);
      if (match == null) {
        return const Error(ServerFailure('Partida não encontrada.'));
      }
      final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
      final number = _generateOrderNumber();

      final orderRow = await _client
          .from('ticket_orders')
          .insert({
            'user_id': _uid,
            'number': number,
            'match_id': matchId,
            'competition': match.competition,
            'round': match.round,
            'home_team_id': match.homeTeam.id,
            'home_team_name': match.homeTeam.name,
            'away_team_id': match.awayTeam.id,
            'away_team_name': match.awayTeam.name,
            'kickoff': match.kickoff?.toUtc().toIso8601String(),
            'stadium': match.stadium,
            'items': items.map((item) => item.toJson()).toList(),
            'holder_name': holderName,
            'holder_document': holderDocument,
            'total': total,
            'status': 'confirmed',
          })
          .select()
          .single();

      final orderId = orderRow['id'] as String;
      final ticketRows = <Map<String, dynamic>>[
        for (final item in items)
          for (var i = 0; i < item.quantity; i++)
            {
              'user_id': _uid,
              'match_id': matchId,
              'competition': match.competition,
              'round': match.round,
              'home_team_id': match.homeTeam.id,
              'home_team_name': match.homeTeam.name,
              'away_team_id': match.awayTeam.id,
              'away_team_name': match.awayTeam.name,
              'kickoff': match.kickoff?.toUtc().toIso8601String(),
              'stadium': match.stadium,
              'sector_id': item.sectorId,
              'sector_name': item.sectorName,
              'venue_label': item.venueLabel,
              'gate': item.gate,
              'category_label': item.categoryLabel,
              'holder_name': holderName,
              'holder_document': holderDocument,
              'status': 'active',
              'origin': 'purchase',
              'order_id': orderId,
              'price': item.unitPrice,
            },
      ];
      if (ticketRows.isNotEmpty) {
        await _client.from('tickets').insert(ticketRows);
      }

      return Success(
        TicketOrder(
          id: orderId,
          number: number,
          matchId: matchId,
          competition: match.competition,
          round: match.round,
          homeTeam: match.homeTeam,
          awayTeam: match.awayTeam,
          kickoff: match.kickoff,
          stadium: match.stadium,
          items: items,
          holderName: holderName,
          holderDocument: holderDocument,
          status: TicketOrderStatus.confirmed,
          createdAt: DateTime.parse(orderRow['created_at'] as String).toLocal(),
        ),
      );
    } catch (error) {
      return Error(mapTicketError(error));
    }
  }

  @override
  Future<Result<List<Ticket>>> getMyTickets() async {
    try {
      final rows = await _client
          .from('tickets')
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: false);
      return Success(rows.map(_mapTicket).toList());
    } catch (error) {
      return Error(mapTicketError(error));
    }
  }

  @override
  Future<Result<List<TicketOrder>>> getMyOrders() async {
    try {
      final rows = await _client
          .from('ticket_orders')
          .select()
          .eq('user_id', _uid)
          .order('created_at', ascending: false);
      return Success(rows.map(_mapOrder).toList());
    } catch (error) {
      return Error(mapTicketError(error));
    }
  }

  /// O mock só conhece a partida que `FootballRepository` devolve como
  /// próxima do Goiás agora — não há "buscar partida por id" na API real
  /// disponível hoje. Se o [matchId] guardado não bater mais com o próximo
  /// jogo atual (ex.: já aconteceu e outro entrou no lugar), trata como não
  /// encontrada em vez de devolver dado errado.
  Future<Match?> _requireMatch(String matchId) async {
    final result = await _footballRepository.getGoiasSnapshot();
    if (result case Success(:final data)) {
      final match = data.nextMatch;
      if (match != null && match.id.toString() == matchId) return match;
    }
    return null;
  }

  TicketSector? _findSector(MatchTicketInfo info, String? sectorId) {
    for (final sector in info.sectors) {
      if (sector.id == sectorId) return sector;
    }
    return null;
  }

  Ticket _mapTicket(Map<String, dynamic> row) => Ticket(
    id: row['id'] as String,
    matchId: row['match_id'] as String,
    competition: row['competition'] as String,
    round: row['round'] as String,
    homeTeam: _teamFrom(
      row['home_team_id'] as int,
      row['home_team_name'] as String,
    ),
    awayTeam: _teamFrom(
      row['away_team_id'] as int,
      row['away_team_name'] as String,
    ),
    kickoff: row['kickoff'] == null
        ? null
        : DateTime.parse(row['kickoff'] as String).toLocal(),
    stadium: row['stadium'] as String,
    sectorName: row['sector_name'] as String,
    venueLabel: row['venue_label'] as String,
    gate: row['gate'] as String,
    holderName: row['holder_name'] as String,
    holderDocument: row['holder_document'] as String,
    status: _ticketStatusFrom(row['status'] as String),
    origin: row['origin'] == 'purchase'
        ? TicketOrigin.purchase
        : TicketOrigin.membershipCheckIn,
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    categoryLabel: row['category_label'] as String?,
    orderId: row['order_id'] as String?,
    price: (row['price'] as num?)?.toDouble(),
  );

  TicketOrder _mapOrder(Map<String, dynamic> row) {
    final itemsJson = row['items'] as List;
    return TicketOrder(
      id: row['id'] as String,
      number: row['number'] as String,
      matchId: row['match_id'] as String,
      competition: row['competition'] as String,
      round: row['round'] as String,
      homeTeam: _teamFrom(
        row['home_team_id'] as int,
        row['home_team_name'] as String,
      ),
      awayTeam: _teamFrom(
        row['away_team_id'] as int,
        row['away_team_name'] as String,
      ),
      kickoff: row['kickoff'] == null
          ? null
          : DateTime.parse(row['kickoff'] as String).toLocal(),
      stadium: row['stadium'] as String,
      items: itemsJson
          .map((e) => TicketOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      holderName: row['holder_name'] as String,
      holderDocument: row['holder_document'] as String,
      status: _orderStatusFrom(row['status'] as String),
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  Team _teamFrom(int id, String name) =>
      Team(id: id, name: name, shortName: name, color: Colors.grey);

  TicketStatus _ticketStatusFrom(String value) => switch (value) {
    'cancelled' => TicketStatus.cancelled,
    'used' => TicketStatus.used,
    'expired' => TicketStatus.expired,
    _ => TicketStatus.active,
  };

  TicketOrderStatus _orderStatusFrom(String value) => switch (value) {
    'pending' => TicketOrderStatus.pending,
    'cancelled' => TicketOrderStatus.cancelled,
    'refunded' => TicketOrderStatus.refunded,
    _ => TicketOrderStatus.confirmed,
  };

  String _generateOrderNumber() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}'.substring(3);
  }
}
