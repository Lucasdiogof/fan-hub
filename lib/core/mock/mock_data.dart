import 'package:flutter/material.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team_info.dart';
import 'package:goias_app/features/membership/domain/entities/membership.dart';
import 'package:goias_app/features/membership/domain/entities/membership_plan.dart';
import 'package:goias_app/features/news/domain/entities/news_article.dart';
import 'package:goias_app/features/profile/domain/entities/app_user.dart';
import 'package:goias_app/features/ticket/domain/entities/stadium_sector.dart';

/// Fonte central de dados mockados do app. Os repositórios mock leem daqui
/// em vez de espalhar dados fictícios pela UI — quando integrarmos com a API
/// real, esse arquivo inteiro deixa de ser usado.
class MockData {
  const MockData._();

  static const goias = TeamInfo(
    name: 'Goiás',
    shortName: 'GO',
    color: Color(0xFF0C7C42),
  );

  static const athleticoPr = TeamInfo(
    name: 'Athletico-PR',
    shortName: 'CAP',
    color: Color(0xFFC0392B),
  );

  static const coritiba = TeamInfo(
    name: 'Coritiba',
    shortName: 'CFC',
    color: Color(0xFF1F6F4A),
  );

  static const vilaNova = TeamInfo(
    name: 'Vila Nova',
    shortName: 'VNO',
    color: Color(0xFFB01128),
  );

  static const avai = TeamInfo(
    name: 'Avaí',
    shortName: 'AVA',
    color: Color(0xFF1C4B9C),
  );

  static const botafogoSp = TeamInfo(
    name: 'Botafogo-SP',
    shortName: 'BSP',
    color: Color(0xFF6E6E6E),
  );

  static const novorizontino = TeamInfo(
    name: 'Novorizontino',
    shortName: 'NOV',
    color: Color(0xFFD32F2F),
  );

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
        kickoff: today.add(const Duration(days: 2, hours: 21, minutes: 30)),
        status: MatchStatus.scheduled,
        salesOpen: true,
      ),
      Match(
        id: 'm-next-2',
        competition: 'Brasileirão Série B',
        round: 'Rodada 24',
        homeTeam: coritiba,
        awayTeam: goias,
        stadium: 'Couto Pereira',
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
        kickoff: today.add(const Duration(days: 16, hours: 21, minutes: 30)),
        status: MatchStatus.scheduled,
        salesOpen: true,
      ),
      Match(
        id: 'm-next-4',
        competition: 'Brasileirão Série B',
        round: 'Rodada 26',
        homeTeam: botafogoSp,
        awayTeam: goias,
        stadium: 'Santa Cruz',
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
        kickoff: today.subtract(const Duration(days: 18, hours: 3)),
        status: MatchStatus.finished,
        homeScore: 1,
        awayScore: 1,
      ),
    ];
  }

  static List<NewsArticle> get news {
    final now = _now;
    return [
      NewsArticle(
        id: 'n-1',
        title: 'Goiás se prepara para enfrentar o Athletico-PR na Serrinha',
        category: NewsCategory.futebol,
        summary: 'Equipe esmeraldina treina forte durante a semana visando os três pontos em casa.',
        body:
            'O Goiás realizou mais uma atividade na Serrinha nesta semana, de olho no confronto direto '
            'contra o Athletico-PR pela Série B. O técnico esmeraldino testou variações táticas e deve '
            'definir a escalação apenas na véspera da partida.',
        publishedAt: now.subtract(const Duration(hours: 3)),
        coverColor: const Color(0xFF0C7C42),
      ),
      NewsArticle(
        id: 'n-2',
        title: 'Sócio Esmeralda ultrapassa marca de 30 mil associados',
        category: NewsCategory.clube,
        summary: 'Programa de sócio-torcedor segue em crescimento e amplia benefícios para 2026.',
        body:
            'O programa Sócio Esmeralda atingiu um novo recorde de associados nesta temporada. A diretoria '
            'destacou os investimentos em novos benefícios, incluindo prioridade na compra de ingressos e '
            'descontos exclusivos em parceiros do clube.',
        publishedAt: now.subtract(const Duration(hours: 9)),
        coverColor: const Color(0xFFC79A3D),
      ),
      NewsArticle(
        id: 'n-3',
        title: 'Sub-20 do Goiás avança de fase no Campeonato Brasileiro',
        category: NewsCategory.base,
        summary: 'Categoria de base vence nos pênaltis e segue viva na competição nacional.',
        body:
            'A equipe sub-20 do Goiás garantiu classificação após vitória nos pênaltis. A base esmeraldina '
            'segue como uma das principais referências de formação de jogadores do Centro-Oeste.',
        publishedAt: now.subtract(const Duration(days: 1, hours: 2)),
        coverColor: const Color(0xFF1F6F4A),
      ),
      NewsArticle(
        id: 'n-4',
        title: 'Goiás feminino estreia com vitória no Brasileirão',
        category: NewsCategory.feminino,
        summary: 'Equipe feminina venceu por 3 a 1 na estreia da competição nacional.',
        body:
            'O time feminino do Goiás fez uma boa estreia no Brasileirão, com atuação de gala e três gols '
            'marcados no segundo tempo. A comissão técnica avalia o início de temporada como positivo.',
        publishedAt: now.subtract(const Duration(days: 2, hours: 5)),
        coverColor: const Color(0xFF0C7C42),
      ),
      NewsArticle(
        id: 'n-5',
        title: 'Reforço esmeraldino é apresentado à torcida',
        category: NewsCategory.futebol,
        summary: 'Novo contratado falou sobre expectativas para a sequência da temporada.',
        body:
            'O mais novo reforço do Goiás foi apresentado oficialmente e já treina com o restante do elenco. '
            'Em entrevista, o atleta comentou sobre a expectativa de estrear diante da torcida na Serrinha.',
        publishedAt: now.subtract(const Duration(days: 3, hours: 4)),
        coverColor: const Color(0xFF12161A),
      ),
      NewsArticle(
        id: 'n-6',
        title: 'Clube divulga calendário de jogos em casa para o próximo mês',
        category: NewsCategory.clube,
        summary: 'Confira as datas confirmadas dos próximos confrontos na Serrinha.',
        body:
            'O Goiás divulgou o calendário atualizado com os próximos jogos em casa. A expectativa é de boa '
            'presença de público, especialmente entre os sócios do programa Esmeralda.',
        publishedAt: now.subtract(const Duration(days: 4, hours: 1)),
        coverColor: const Color(0xFF5B6470),
      ),
    ];
  }

  static const sectors = [
    StadiumSector(
      id: 's-toboga',
      name: 'Tobogã',
      description: 'Arquibancada tradicional, a energia da torcida em pé.',
      price: 40,
      availability: 0.62,
    ),
    StadiumSector(
      id: 's-cadeiras',
      name: 'Cadeiras',
      description: 'Assento numerado com ótima visão do gramado.',
      price: 90,
      availability: 0.35,
    ),
    StadiumSector(
      id: 's-familia',
      name: 'Espaço Família',
      description: 'Setor tranquilo, pensado para ir com a família.',
      price: 70,
      availability: 0.48,
    ),
    StadiumSector(
      id: 's-vip',
      name: 'Espaço VIP',
      description: 'Conforto premium com acesso a área exclusiva.',
      price: 220,
      availability: 0.08,
    ),
  ];

  static const plans = [
    MembershipPlan(
      id: 'p-esmeralda',
      name: 'Esmeralda',
      monthlyPrice: 39.9,
      benefits: [
        'Desconto em ingressos',
        'Prioridade na compra de ingressos',
        'Conteúdo exclusivo no app',
      ],
    ),
    MembershipPlan(
      id: 'p-cadeiras',
      name: 'Cadeiras',
      monthlyPrice: 79.9,
      benefits: [
        'Check-in direto no setor Cadeiras',
        'Desconto em ingressos avulsos',
        'Prioridade na compra de ingressos',
        'Loja oficial com desconto',
      ],
      highlight: true,
    ),
    MembershipPlan(
      id: 'p-familia',
      name: 'Família',
      monthlyPrice: 129.9,
      benefits: [
        'Até 4 check-ins por partida',
        'Espaço Família garantido',
        'Loja oficial com desconto',
        'Eventos exclusivos para sócios',
      ],
    ),
  ];

  static Membership get myMembership => Membership(
    plan: plans[1],
    status: MembershipStatus.active,
    memberNumber: '084213',
    holderName: 'Lucas Diogo',
    nextPaymentDate: DateTime(_now.year, _now.month, _now.day).add(const Duration(days: 12)),
  );

  static AppUser get currentUser => AppUser(
    name: 'Lucas Diogo',
    email: 'lucas.diogo@email.com',
    cpf: '000.000.000-00',
    phone: '(62) 90000-0000',
    membership: myMembership,
  );
}
