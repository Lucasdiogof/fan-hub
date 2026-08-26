import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/match_ticket_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';

/// Fonte única do conteúdo de venda/check-in enquanto não existe API real
/// de ingressos — setores, preços, janelas de venda e o texto estruturado
/// da tela "Informações da partida". Nunca lido direto por uma Widget:
/// sempre através de `MatchTicketInfo`/`MatchSalesInfo` (ver
/// `infoFor`/`salesInfoFor`), que são o formato que a API real preencheria
/// depois. Não fica preso a um `matchId` fixo — é aplicado à partida real
/// que `FootballRepository` devolver como próximo jogo do Goiás (ver
/// `MockTicketRepository.getFeaturedEvent`), então trocar o próximo
/// adversário na fonte de dados esportivos é suficiente pra essa tela toda
/// se adaptar, sem tocar em nada aqui.
class TicketFixture {
  const TicketFixture._();

  static const _cadeiras = TicketSector(
    id: 'cadeiras',
    name: 'Cadeiras',
    venueLabel: 'Goiás E.C.',
    gate: 'Portão 6',
    availableForCheckIn: true,
    categories: [
      TicketPriceCategory(id: 'inteira', label: 'Inteira', price: 80),
      TicketPriceCategory(id: 'meia', label: 'Meia', price: 40),
      TicketPriceCategory(id: 'menor18', label: 'Menores 18 anos', price: 40),
    ],
  );

  static const _espacoFamilia = TicketSector(
    id: 'espaco-familia',
    name: 'Espaço Família',
    venueLabel: 'Goiás E.C.',
    gate: 'Portão 9B',
    availableForCheckIn: true,
    categories: [
      TicketPriceCategory(id: 'inteira', label: 'Inteira', price: 40),
      TicketPriceCategory(id: 'meia', label: 'Meia', price: 20),
      TicketPriceCategory(id: 'menor18', label: 'Menores 18 anos', price: 20),
    ],
  );

  static const _toboganForca = TicketSector(
    id: 'tobogan-forca',
    name: 'Tobogã Força',
    venueLabel: 'Goiás E.C.',
    gate: 'Portão 9',
    availableForCheckIn: true,
    categories: [
      TicketPriceCategory(id: 'inteira', label: 'Inteira', price: 40),
      TicketPriceCategory(id: 'meia', label: 'Meia', price: 20),
      TicketPriceCategory(id: 'menor18', label: 'Menores 18 anos', price: 20),
    ],
  );

  /// As categorias pagas do setor visitante estão esgotadas no fixture
  /// original — só criança/gratuidade seguem disponíveis.
  static const _visitante = TicketSector(
    id: 'visitante',
    name: 'Setor Visitante',
    venueLabel: 'São Bernardo F.C.',
    gate: 'Portão 3',
    isVisitorSector: true,
    categories: [
      TicketPriceCategory(id: 'crianca', label: 'Criança', price: 0),
      TicketPriceCategory(id: 'gratuidade', label: 'Gratuidade', price: 0),
      TicketPriceCategory(
        id: 'inteira',
        label: 'Inteira',
        price: 80,
        soldOut: true,
      ),
      TicketPriceCategory(id: 'meia', label: 'Meia', price: 40, soldOut: true),
      TicketPriceCategory(
        id: 'menor18',
        label: 'Menores 18 anos',
        price: 40,
        soldOut: true,
      ),
    ],
  );

  static const sectors = [_cadeiras, _espacoFamilia, _toboganForca, _visitante];

  static MatchTicketInfo infoFor(String matchId) => MatchTicketInfo(
    matchId: matchId,
    saleOpensAt: DateTime(2026, 8, 25, 9),
    checkInOpensAt: DateTime(2026, 8, 25, 9),
    canCancelCheckIn: true,
    sectors: sectors,
  );

  static MatchSalesInfo salesInfoFor(String matchId) => MatchSalesInfo(
    matchId: matchId,
    sections: const [
      MatchInfoSection(
        title: 'Antes de comprar',
        items: [
          'Ingressos nominais e intransferíveis — o nome impresso é o único autorizado a entrar.',
          'Cadastro no sistema de ingressos é obrigatório antes da compra.',
        ],
      ),
      MatchInfoSection(
        title: 'Reconhecimento facial',
        items: [
          'O acesso ao estádio é feito por reconhecimento facial.',
          'Foto de cadastro com fundo branco, rosto centralizado e boa iluminação.',
          'Pode ser em pé ou sentado, sem boné, gorro, chapéu, óculos de grau ou óculos escuros.',
        ],
      ),
      MatchInfoSection(
        title: 'Venda de ingressos',
        items: [
          'Venda geral: a partir de 25/08 às 09h.',
          'Venda para a torcida visitante: a partir de 25/08 às 09h.',
        ],
      ),
      MatchInfoSection(
        title: 'Bilheterias',
        items: [
          'Bilheteria física: 26/08, das 09h às 17h.',
          'Sem atendimento em bilheteria física em 27/08.',
          'Sem atendimento em bilheteria física no dia da partida, 28/08.',
        ],
      ),
      MatchInfoSection(
        title: 'Crianças e gratuidades',
        items: [
          'Crianças de 0 a 5 anos não precisam de ingresso.',
          'Crianças de 6 a 12 anos têm gratuidade mediante as regras do evento.',
          'Gratuidades são limitadas, sujeitas à disponibilidade.',
        ],
      ),
      MatchInfoSection(
        title: 'Valores',
        items: [
          'Preços por setor e categoria na tela de seleção de ingressos.',
          'Meia-entrada conforme a Lei Federal 12.933/2013.',
        ],
      ),
      MatchInfoSection(
        title: 'Considerações importantes',
        items: [
          'Ingresso pessoal e intransferível — nenhum ingresso dá direito a acompanhante.',
          'A torcida visitante segue regras específicas de setor.',
          'Fraude no cadastro ou uso do ingresso pode resultar em suspensão do torcedor.',
        ],
      ),
      MatchInfoSection(
        title: 'Cancelamentos e reembolsos',
        items: [
          'Cancelamento pode ser solicitado em até 7 dias corridos após a compra, respeitando o limite de 24 horas antes do evento.',
          'Taxas de serviço podem não ser reembolsáveis.',
          'Prazo e forma do reembolso dependem do método de pagamento utilizado.',
        ],
      ),
      MatchInfoSection(
        title: 'Acesso ao estádio',
        items: [
          'Acesso ao evento encerrado 30 minutos após o início da partida, salvo determinação em contrário.',
        ],
      ),
    ],
  );
}
