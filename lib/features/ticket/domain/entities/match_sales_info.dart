import 'package:equatable/equatable.dart';

/// Uma seção da tela "Informações da partida" (ex.: "Reconhecimento
/// facial", "Cancelamentos e reembolsos"). [items] são parágrafos/bullets —
/// a tela decide como renderizar, o dado nunca carrega formatação.
class MatchInfoSection extends Equatable {
  const MatchInfoSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  List<Object?> get props => [title, items];
}

/// Conteúdo estruturado da tela cheia "Informações da partida" — nunca
/// texto solto dependente de uma partida específica dentro de uma Widget.
/// Trocar o fixture (ver `TicketFixture`) é suficiente pra essa tela toda
/// se adaptar a outro adversário.
class MatchSalesInfo extends Equatable {
  const MatchSalesInfo({required this.matchId, required this.sections});

  final String matchId;
  final List<MatchInfoSection> sections;

  @override
  List<Object?> get props => [matchId, sections];
}
