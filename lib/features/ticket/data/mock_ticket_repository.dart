import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/domain/repositories/football_repository.dart';
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
    this._clubConfig,
  );

  final SupabaseClient _client;
  final FootballRepository _footballRepository;
  final ClubConfig _clubConfig;

  String get _uid => _client.auth.currentUser!.id;
  String get _clubId => _clubConfig.identity.canonicalClubId;

  @override
  Future<Result<TicketEvent?>> getFeaturedEvent() async {
    try {
      final snapshotResult = await _footballRepository.getActiveClubSnapshot();
      final Match? match;
      switch (snapshotResult) {
        case Success(:final data):
          match = data.nextMatch;
        case Error(:final failure):
          return Error(failure);
      }
      if (match == null) return const Success(null);

      final matchId = match.id.toString();
      final info = TicketFixture.infoFor(matchId, match.kickoff);
      final now = DateTime.now();
      // Fora de casa não tem venda de ingresso nem check-in de sócio pra
      // oferecer — só o mandante do jogo controla a bilheteria e o
      // portão do próprio estádio (mesma regra do CTA da Home/aba Jogos).
      final isHomeMatch = match.homeTeam.matchesClub(_clubConfig);

      final TicketSaleStatus saleStatus;
      final CheckInStatus checkInStatus;
      String? confirmedSectorName;
      Ticket? checkInTicket;
      if (!isHomeMatch) {
        saleStatus = TicketSaleStatus.awayGame;
        checkInStatus = CheckInStatus.awayGame;
      } else {
        saleStatus = computeSaleStatus(
          info: info,
          kickoff: match.kickoff,
          now: now,
        );

        final decisionRow = await _client
            .from('ticket_checkin_decisions')
            .select('decision, sector_id')
            .eq('user_id', _uid)
            .eq('club_id', _clubId)
            .eq('match_id', matchId)
            .maybeSingle();

        final windowStatus = computeCheckInWindowStatus(
          info: info,
          kickoff: match.kickoff,
          now: now,
        );
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
              .eq('club_id', _clubId)
              .eq('match_id', matchId)
              .eq('origin', 'membership_check_in')
              .eq('status', 'active')
              .maybeSingle();
          if (ticketRow != null) checkInTicket = _mapTicket(ticketRow);
        }
      }

      final purchasedRows = await _client
          .from('tickets')
          .select('id')
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .eq('match_id', matchId)
          .eq('origin', 'purchase')
          .eq('status', 'active')
          .limit(1);
      final hasTicketForMatch = (purchasedRows as List).isNotEmpty;

      return Success(
        TicketEvent(
          match: match,
          info: info,
          saleStatus: saleStatus,
          checkInStatus: checkInStatus,
          confirmedSectorName: confirmedSectorName,
          checkInTicket: checkInTicket,
          hasTicketForMatch: hasTicketForMatch,
        ),
      );
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
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
      final sector = _findSector(
        TicketFixture.infoFor(matchId, match.kickoff),
        sectorId,
      );
      if (sector == null) {
        return const Error(ServerFailure('Setor não encontrado.'));
      }

      // M3.4: onConflict tenant-aware via bridge tcd_club_user_match_uidx
      // (club_id, user_id, match_id). PK legada (user_id, match_id) intacta.
      await _client.from('ticket_checkin_decisions').upsert({
        'user_id': _uid,
        'club_id': _clubId,
        'match_id': matchId,
        'decision': 'confirmed',
        'sector_id': sectorId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'club_id,user_id,match_id');

      // M3.4: o índice único do check-in de sócio é PARCIAL
      // (club_id, user_id, match_id) WHERE origin='membership_check_in'. O
      // `onConflict:` do PostgREST só expressa colunas, nunca o predicate,
      // então o upsert tenant-aware vai por uma RPC dedicada: deriva o
      // usuário de auth.uid() no servidor e faz o ON CONFLICT com o predicate.
      // Nunca toca em tickets origin='purchase' (compra continua no fluxo
      // próprio de pedido).
      final row = await _client.rpc<Map<String, dynamic>>(
        'upsert_membership_checkin_ticket_for_club',
        params: {
          'p_club_id': _clubId,
          'p_match_id': matchId,
          'p_competition': match.competition,
          'p_round': match.round,
          'p_home_team_id': match.homeTeam.id,
          'p_home_team_name': match.homeTeam.name,
          'p_away_team_id': match.awayTeam.id,
          'p_away_team_name': match.awayTeam.name,
          'p_kickoff': match.kickoff?.toUtc().toIso8601String(),
          'p_stadium': match.stadium,
          'p_sector_id': sector.id,
          'p_sector_name': sector.name,
          'p_venue_label': sector.venueLabel,
          'p_gate': sector.gate,
          'p_holder_name': holderName,
          'p_holder_document': holderDocument,
        },
      );

      return Success(_mapTicket(row));
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> declineCheckIn(String matchId) async {
    try {
      await _client.from('ticket_checkin_decisions').upsert({
        'user_id': _uid,
        'club_id': _clubId,
        'match_id': matchId,
        'decision': 'declined',
        'sector_id': null,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'club_id,user_id,match_id');
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> clearCheckInDecision(String matchId) async {
    try {
      await _client
          .from('ticket_checkin_decisions')
          .delete()
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .eq('match_id', matchId);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
    }
  }

  @override
  Future<Result<void>> undoCheckIn(String matchId) async {
    try {
      // update/delete precisam do MESMO filtro de tenant que os selects —
      // nunca deixar um update de conta+clube alcançar a linha de outro
      // clube da mesma conta (regra 6 do pedido da M3.2).
      await _client
          .from('tickets')
          .update({'status': 'cancelled'})
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .eq('match_id', matchId)
          .eq('origin', 'membership_check_in')
          .eq('status', 'active');
      await _client
          .from('ticket_checkin_decisions')
          .delete()
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .eq('match_id', matchId);
      return const Success(null);
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
    }
  }

  @override
  Future<Result<TicketOrder>> purchase({
    required String matchId,
    required List<TicketOrderItem> items,
    required List<TicketHolder> holders,
  }) async {
    try {
      final match = await _requireMatch(matchId);
      if (match == null) {
        return const Error(ServerFailure('Partida não encontrada.'));
      }
      final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
      final number = _generateOrderNumber();
      // O pedido guarda o titular do primeiro ingresso como referência —
      // quem de fato usa cada ingresso é o `holder_name`/`holder_document`
      // da própria linha em `tickets`, não este aqui.
      final primaryHolder = holders.first;

      final orderRow = await _client
          .from('ticket_orders')
          .insert({
            'user_id': _uid,
            'club_id': _clubId,
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
            'holder_name': primaryHolder.name,
            'holder_document': primaryHolder.document,
            'total': total,
            'status': 'confirmed',
          })
          .select()
          .single();

      final orderId = orderRow['id'] as String;
      final ticketRows = <Map<String, dynamic>>[];
      var holderIndex = 0;
      for (final item in items) {
        for (var i = 0; i < item.quantity; i++) {
          final holder = holders[holderIndex];
          holderIndex++;
          ticketRows.add({
            'user_id': _uid,
            'club_id': _clubId,
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
            'holder_name': holder.name,
            'holder_document': holder.document,
            'status': 'active',
            'origin': 'purchase',
            'order_id': orderId,
            'price': item.unitPrice,
            if (holder.halfPriceType != null)
              'half_price_type': holder.halfPriceType!.name,
            if (holder.halfPriceProofPath != null)
              'half_price_proof_path': holder.halfPriceProofPath,
          });
        }
      }
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
          holderName: primaryHolder.name,
          holderDocument: primaryHolder.document,
          status: TicketOrderStatus.confirmed,
          createdAt: DateTime.parse(orderRow['created_at'] as String).toLocal(),
        ),
      );
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
    }
  }

  @override
  Future<Result<String>> uploadHalfPriceProof(
    Uint8List bytes,
    String fileExtension,
  ) async {
    try {
      final ext = fileExtension.toLowerCase() == 'jpg'
          ? 'jpeg'
          : fileExtension.toLowerCase();
      final unique =
          '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}';
      final path = '$_uid/$unique.$ext';
      await _client.storage
          .from('half_price_proofs')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _contentTypeFor(ext)),
          );
      return Success(path);
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
    }
  }

  String _contentTypeFor(String ext) =>
      ext == 'pdf' ? 'application/pdf' : 'image/$ext';

  @override
  Future<Result<List<Ticket>>> getMyTickets() async {
    try {
      final rows = await _client
          .from('tickets')
          .select()
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .order('created_at', ascending: false);
      return Success(rows.map(_mapTicket).toList());
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
    }
  }

  @override
  Future<Result<List<TicketOrder>>> getMyOrders() async {
    try {
      final rows = await _client
          .from('ticket_orders')
          .select()
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .order('created_at', ascending: false);
      return Success(rows.map(_mapOrder).toList());
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
    }
  }

  @override
  Future<Result<Ticket>> requestRefund(String ticketId) async {
    try {
      // O `eq('status', 'active')` faz a checagem de "já reembolsado" e a
      // proteção contra pedido duplicado/concorrente na própria query — um
      // segundo pedido (ou dois quase simultâneos) sempre acha 0 linhas
      // pra atualizar na segunda vez, nunca reembolsa duas vezes. RLS
      // (`update own tickets`, ver supabase/tickets.sql) já garante que só
      // o dono (auth.uid() = user_id) consegue atualizar a linha, mesmo que
      // o app mande um ticketId de outra conta.
      final rows = await _client
          .from('tickets')
          .update({
            'status': 'refunded',
            'refunded_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', ticketId)
          .eq('user_id', _uid)
          .eq('club_id', _clubId)
          .eq('origin', 'purchase')
          .eq('status', 'active')
          .select();
      if (rows.isEmpty) {
        return const Error(
          ServerFailure('Este ingresso não pode ser reembolsado.'),
        );
      }
      return Success(_mapTicket(rows.first));
    } catch (error, stackTrace) {
      return Error(mapTicketError(error, stackTrace));
    }
  }

  /// O mock só conhece a partida que `FootballRepository` devolve como
  /// próxima do Goiás agora — não há "buscar partida por id" na API real
  /// disponível hoje. Se o [matchId] guardado não bater mais com o próximo
  /// jogo atual (ex.: já aconteceu e outro entrou no lugar), trata como não
  /// encontrada em vez de devolver dado errado.
  Future<Match?> _requireMatch(String matchId) async {
    final result = await _footballRepository.getActiveClubSnapshot();
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
    refundedAt: row['refunded_at'] == null
        ? null
        : DateTime.parse(row['refunded_at'] as String).toLocal(),
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
    'refunded' => TicketStatus.refunded,
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
