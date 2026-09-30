import 'package:goias_app/features/ticket/domain/entities/club_tickets_content.dart';
import 'package:goias_app/features/ticket/domain/entities/match_sales_info.dart';
import 'package:goias_app/features/ticket/domain/entities/ticket_sector.dart';

/// Ingressos do Vila Nova no OBA — pesquisa real, não fixture.
///
/// Fonte: notícias oficiais "VENDA DE INGRESSOS" de vilanovafc.com.br
/// (Série B 2026: x Sport, x Ceará, x Goiás, x América-MG e x Londrina,
/// lidas em 2026-09-30). Setores e preços se repetem IGUAIS em todas; pontos
/// de venda e regras (meia, gratuidade, crianças) são idênticos nas 3 mais
/// recentes. Nada aqui é específico de um jogo (sem data nem adversário).
///
/// Diferenças deliberadas em relação ao Goiás:
///   * `gate` vazio: o clube não publica portão por setor (nem nas notícias
///     nem em /estrutura) — as telas omitem o portão (`withGate`), nunca um
///     portão inventado;
///   * sem categoria "Menores 18 anos": não existe no OBA. Criança até 12
///     anos entra sem ingresso (vai no texto, não vira categoria);
///   * check-in de sócio só nos Setores A e B — "RUBI, OURO E PRATA têm
///     acesso gratuito garantido no seu respectivo setor" (Prata = B; Ouro e
///     Rubi = A ou B, ver `vilanova_membership_plans_catalog.dart`).
///     Camarote e visitante ficam de fora do check-in.
class VilaNovaTicketContent {
  const VilaNovaTicketContent._();

  static const _home = 'Vila Nova F.C.';

  static const _setorA = TicketSector(
    id: 'setor-a',
    name: 'Setor A',
    venueLabel: _home,
    gate: '',
    availableForCheckIn: true,
    categories: [
      TicketPriceCategory(id: 'inteira', label: 'Inteira', price: 120),
      TicketPriceCategory(
        id: 'meia',
        label: 'Meia',
        price: 60,
        isHalfPrice: true,
      ),
    ],
  );

  static const _setorB = TicketSector(
    id: 'setor-b',
    name: 'Setor B',
    venueLabel: _home,
    gate: '',
    availableForCheckIn: true,
    categories: [
      TicketPriceCategory(id: 'inteira', label: 'Inteira', price: 60),
      TicketPriceCategory(
        id: 'meia',
        label: 'Meia',
        price: 30,
        isHalfPrice: true,
      ),
    ],
  );

  /// Valor único nas notícias ("CAMAROTE: 120,00"), sem meia-entrada.
  static const _camarote = TicketSector(
    id: 'camarote',
    name: 'Camarote',
    venueLabel: _home,
    gate: '',
    categories: [
      TicketPriceCategory(id: 'inteira', label: 'Inteira', price: 120),
    ],
  );

  static const _setorC = TicketSector(
    id: 'setor-c',
    name: 'Setor C',
    venueLabel: 'Torcida visitante',
    gate: '',
    isVisitorSector: true,
    categories: [
      TicketPriceCategory(id: 'inteira', label: 'Inteira', price: 120),
      TicketPriceCategory(
        id: 'meia',
        label: 'Meia',
        price: 60,
        isHalfPrice: true,
      ),
    ],
  );

  static const content = ClubTicketsContent(
    sectors: [_setorA, _setorB, _camarote, _setorC],
    salesInfoSections: [
      MatchInfoSection(
        title: 'Onde comprar',
        items: [
          'Online, pela Ingresso SA (ingressosa.com) — o link de cada jogo sai na notícia de venda do site oficial.',
          'Loja Nação Colorada (OBA): Rua 256, nº 120, Setor Universitário, Goiânia.',
          'Loja Nação Colorada (Buriti Shopping): Av. Rio Verde, Qd. 102/104, Piso 2, Vila São Tomaz, Aparecida de Goiânia.',
          'Loja Nação Colorada (CT): Av. Ubirajara Berocan Leite, s/n, Setor Rasmussem, Goiânia.',
          'Empório das Bebidas: Av. T-9, nº 3900, Jardim Vila Bela, Goiânia.',
          'Tio Bák Noroeste (Shopping Perimetral Open Mall) e Tio Bák Eldorado (Res. Celina Park), em Goiânia.',
          'Nos pontos físicos, a venda segue o horário de funcionamento de cada estabelecimento.',
        ],
      ),
      MatchInfoSection(
        title: 'Sócio Tigrão',
        items: [
          'Planos Rubi, Ouro e Prata têm acesso gratuito garantido no seu respectivo setor.',
        ],
      ),
      MatchInfoSection(
        title: 'Meia-entrada',
        items: [
          'Setores A e B: meia garantida com a camisa do Vila Nova ou a Carteira ID Jovem.',
          'Setor C (visitante): meia com a camisa do time visitante ou a Carteira ID Jovem.',
          'Estudantes, com a Carteira de Identificação Estudantil (CIE) e documento com CPF (Lei 12.933/2013).',
          'Idosos de 60 a 65 anos, com documento com foto e CPF (Lei 10.741/2003).',
          'Doadores regulares de sangue, com o documento da Secretaria Estadual de Saúde e identidade com CPF.',
        ],
      ),
      MatchInfoSection(
        title: 'Gratuidades',
        items: [
          'Retiradas antecipadamente, só na loja Nação Colorada do OBA, em quantidade limitada, pelo próprio beneficiário.',
          'Têm direito: pessoas acima de 65 anos, policiais militares, civis e federais, indígenas, pessoas com deficiência e autoridades, com documento comprobatório e CPF.',
          'Jovens de 15 a 29 anos de famílias de baixa renda, com a Carteira ID Jovem e documento com CPF.',
          'Pessoa com deficiência e acompanhante, com o cartão do BPC ou o documento do INSS.',
        ],
      ),
      MatchInfoSection(
        title: 'Crianças',
        items: [
          'Até 12 anos completos não precisam de ingresso: o acesso é direto na catraca.',
          'A criança precisa estar com documento de identificação e acompanhada dos pais ou responsáveis (Portaria 039/2015 do Juizado da Infância e Juventude).',
        ],
      ),
      MatchInfoSection(
        title: 'Valores',
        items: [
          'Os valores são referentes à entrada; bebidas e alimentos são vendidos no estádio.',
          'O Setor C (visitante) nem sempre é vendido — no clássico contra o Goiás em 2026, por exemplo, não houve venda para ele.',
        ],
      ),
    ],
  );
}
