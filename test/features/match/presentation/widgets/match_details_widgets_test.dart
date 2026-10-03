import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/match/domain/entities/lineup.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/match_event.dart';
import 'package:goias_app/features/match/domain/entities/match_stat.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/cubit/match_details_cubit.dart';
import 'package:goias_app/features/match/presentation/pages/match_details_page.dart';
import 'package:goias_app/features/match/presentation/widgets/match_events_timeline.dart';
import 'package:goias_app/features/match/presentation/widgets/match_hero_card.dart';
import 'package:goias_app/features/match/presentation/widgets/match_lineups_section.dart';
import 'package:goias_app/features/match/presentation/widgets/match_stats_section.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/shared/widgets/fan_hub_tab_bar.dart';

import '../../fakes/fake_football_repository.dart';

Team _team(int id, String name) =>
    Team(id: id, name: name, shortName: name, color: const Color(0xFF1F6F4A));

Match _match({
  MatchStatus status = MatchStatus.scheduled,
  int? homeScore,
  int? awayScore,
  String stadium = 'Estádio Governador Plácido Aderaldo Castelo',
  String? city,
  String home = 'Fortaleza',
  String away = 'Náutico',
}) => Match(
  id: 'onef-1',
  competition: 'Brasileirão Série B Superbet',
  round: 'Rodada 31',
  homeTeam: _team(1, home),
  awayTeam: _team(2, away),
  stadium: stadium,
  city: city,
  kickoff: DateTime.utc(2026, 10, 3, 0, 35), // 21:35 em Brasília
  status: status,
  homeScore: homeScore,
  awayScore: awayScore,
);

Widget _host(
  Widget child, {
  double width = 390,
  Locale locale = const Locale('pt'),
  ThemeData? theme,
}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

MatchEvent _event(
  String minute,
  MatchEventType type, {
  String? player,
  String? detail,
  MatchEventSide side = MatchEventSide.home,
}) => MatchEvent(
  minute: minute,
  side: side,
  type: type,
  player: player,
  detail: detail,
);

void main() {
  setUpAll(initializeBrazilTimeZone);

  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  group('MatchHeroCard', () {
    testWidgets('partida futura: horário em destaque, sem AO VIVO nem status', (
      tester,
    ) async {
      await tester.pumpWidget(_host(MatchHeroCard(match: _match())));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('21:35'), findsOneWidget);
      expect(find.text('AO VIVO'), findsNothing);
      expect(find.text('AGENDADA'), findsNothing);
      expect(find.text('1 x 1'), findsNothing);
    });

    testWidgets('ao vivo: placar e badge', (tester) async {
      await tester.pumpWidget(
        _host(
          MatchHeroCard(
            match: _match(status: MatchStatus.live, homeScore: 1, awayScore: 1),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('1 x 1'), findsOneWidget);
      expect(find.text('AO VIVO'), findsOneWidget);
    });

    testWidgets('encerrada: placar final, status e sem AO VIVO', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MatchHeroCard(
            match: _match(
              status: MatchStatus.finished,
              homeScore: 2,
              awayScore: 0,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('2 x 0'), findsOneWidget);
      expect(find.text('AO VIVO'), findsNothing);
      expect(find.text('ENCERRADA'), findsOneWidget);
    });

    testWidgets('estádio enorme quebra em até 2 linhas, sem overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MatchHeroCard(
            match: _match(
              city: 'Fortaleza',
              stadium:
                  'Estádio Governador Plácido Aderaldo Castelo Branco Filho',
            ),
          ),
          width: 300,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem estádio: nenhuma linha de local', (tester) async {
      await tester.pumpWidget(_host(MatchHeroCard(match: _match(stadium: ''))));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Estádio'), findsNothing);
    });

    for (final width in [300.0, 360.0, 600.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          'nomes grandes sem overflow em ${width.toInt()}px (${dark ? 'escuro' : 'claro'})',
          (tester) async {
            await tester.pumpWidget(
              _host(
                MatchHeroCard(
                  match: _match(
                    status: MatchStatus.live,
                    homeScore: 10,
                    awayScore: 12,
                    home: 'Athletico Paranaense Futebol Clube',
                    away: 'Sociedade Esportiva Palmeiras',
                  ),
                ),
                width: width,
                theme: dark ? AppTheme.dark() : AppTheme.light(),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    for (final locale in AppLocalizations.supportedLocales) {
      for (final width in [300.0, 320.0, 390.0, 900.0]) {
        for (final status in [
          MatchStatus.scheduled,
          MatchStatus.live,
          MatchStatus.finished,
          MatchStatus.postponed,
        ]) {
          testWidgets(
            'varredura: ${locale.languageCode} ${width.toInt()}px ${status.name}',
            (tester) async {
              final hasScore =
                  status == MatchStatus.live || status == MatchStatus.finished;
              await tester.pumpWidget(
                _host(
                  MatchHeroCard(
                    match: Match(
                      id: 'x',
                      competition:
                          'Campeonato Brasileiro de Futebol Série B Superbet Edição Especial',
                      round: 'Rodada 31 • Fase Final • Jogo de Volta',
                      homeTeam: _team(1, 'Athletico Paranaense Futebol Clube'),
                      awayTeam: _team(2, 'Sociedade Esportiva Palmeiras'),
                      stadium:
                          'Estádio Governador Plácido Aderaldo Castelo Branco Filho',
                      city: 'Cidade Com Um Nome Bem Grande Do Interior',
                      kickoff: DateTime.utc(2026, 12, 25, 0, 35),
                      status: status,
                      homeScore: hasScore ? 10 : null,
                      awayScore: hasScore ? 12 : null,
                    ),
                  ),
                  width: width,
                  locale: locale,
                ),
              );
              await tester.pump();
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }

    testWidgets('EN e ES traduzem o badge', (tester) async {
      for (final (locale, text) in [
        (const Locale('en'), 'LIVE'),
        (const Locale('es'), 'EN VIVO'),
      ]) {
        await tester.pumpWidget(
          _host(
            MatchHeroCard(
              match: _match(
                status: MatchStatus.live,
                homeScore: 0,
                awayScore: 0,
              ),
            ),
            locale: locale,
          ),
        );
        await tester.pump();
        expect(find.text(text), findsOneWidget, reason: '$locale');
      }
    });
  });

  group('MatchEventsTimeline', () {
    testWidgets('mostra TODOS os eventos, sem botão "ver todos"', (
      tester,
    ) async {
      final events = [
        for (var i = 1; i <= 25; i++)
          _event("$i'", MatchEventType.goal, player: 'Jogador $i'),
      ];
      await tester.pumpWidget(
        _host(MatchEventsTimeline(match: _match(), events: events)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (var i = 1; i <= 25; i++) {
        expect(find.text('Jogador $i'), findsOneWidget);
      }
      expect(find.textContaining('Ver todos'), findsNothing);
      expect(find.byType(Scrollable), findsOneWidget); // só o da página
    });

    testWidgets('preserva a ordem recebida da fonte', (tester) async {
      await tester.pumpWidget(
        _host(
          MatchEventsTimeline(
            match: _match(),
            events: [
              _event("14'", MatchEventType.goal, player: 'Primeiro'),
              _event("90'", MatchEventType.yellowCard, player: 'Último'),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('Primeiro')).dy,
        lessThan(tester.getTopLeft(find.text('Último')).dy),
      );
    });

    testWidgets('detalhe do gol traduzido e time do lance', (tester) async {
      await tester.pumpWidget(
        _host(
          MatchEventsTimeline(
            match: _match(),
            events: [
              _event(
                "10'",
                MatchEventType.goal,
                player: 'Lucero',
                detail: 'Pênalti',
              ),
              _event(
                "20'",
                MatchEventType.goal,
                player: 'Kauan',
                detail: 'Contra',
                side: MatchEventSide.away,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Fortaleza • Pênalti'), findsOneWidget);
      expect(find.text('Náutico • Gol contra'), findsOneWidget);
    });

    testWidgets('sem eventos: estado vazio i18n', (tester) async {
      for (final (locale, text) in [
        (const Locale('pt'), 'Eventos da partida ainda não disponíveis'),
        (const Locale('en'), 'Match events not available yet'),
        (const Locale('es'), 'Eventos del partido aún no disponibles'),
      ]) {
        await tester.pumpWidget(
          _host(
            MatchEventsTimeline(match: _match(), events: const []),
            locale: locale,
          ),
        );
        await tester.pump();
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('minutos de 1, 2, 3 e 6 caracteres mantêm a coluna alinhada', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MatchEventsTimeline(
            match: _match(),
            events: [
              _event("5'", MatchEventType.goal, player: 'A'),
              _event("45'", MatchEventType.goal, player: 'B'),
              _event("90+3'", MatchEventType.goal, player: 'C'),
              _event("120+10'", MatchEventType.goal, player: 'D'),
            ],
          ),
          width: 320,
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final xs = [
        for (final name in ['A', 'B', 'C', 'D'])
          tester.getTopLeft(find.text(name)).dx,
      ];
      expect(xs.toSet(), hasLength(1), reason: '$xs');
    });

    testWidgets('evento de tipo desconhecido tem fallback seguro', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MatchEventsTimeline(
            match: _match(),
            events: [
              _event("33'", MatchEventType.other),
              _event("34'", MatchEventType.goal),
              _event("35'", MatchEventType.yellowCard),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Gol'), findsOneWidget);
      expect(find.text('Cartão'), findsOneWidget);
    });

    testWidgets('um único evento renderiza', (tester) async {
      await tester.pumpWidget(
        _host(
          MatchEventsTimeline(
            match: _match(),
            events: [_event("1'", MatchEventType.goal, player: 'Único')],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Único'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('substituição e cartões renderizam', (tester) async {
      await tester.pumpWidget(
        _host(
          MatchEventsTimeline(
            match: _match(),
            events: [
              _event(
                "46'",
                MatchEventType.substitution,
                player: 'Entra',
                detail: 'Sai',
              ),
              _event("58'", MatchEventType.yellowCard, player: 'Amarelo'),
              _event("70'", MatchEventType.redCard, player: 'Vermelho'),
              _event("80'", MatchEventType.other, detail: 'VAR'),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Entra entra no lugar de Sai'), findsOneWidget);
      expect(find.text('VAR'), findsOneWidget);
    });
  });

  group('MatchStatsSection', () {
    const possession = MatchStat(
      title: 'Posse de bola',
      unit: MatchStatUnit.percent,
      home: 62,
      away: 38,
    );

    testWidgets('mostra as métricas com a ordem de prioridade', (tester) async {
      await tester.pumpWidget(
        _host(
          MatchStatsSection(
            match: _match(),
            stats: const [
              MatchStat(
                title: 'Disputas ganhas',
                unit: MatchStatUnit.percent,
                home: 46,
                away: 54,
              ),
              MatchStat(
                title: 'Chutes ao gol',
                unit: MatchStatUnit.count,
                home: 5,
                away: 2,
              ),
              possession,
              MatchStat(
                title: 'Total de chutes',
                unit: MatchStatUnit.count,
                home: 14,
                away: 6,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y('Posse de bola'), lessThan(y('Finalizações')));
      expect(y('Finalizações'), lessThan(y('Finalizações no gol')));
      expect(y('Finalizações no gol'), lessThan(y('Disputas ganhas')));
      expect(find.text('62%'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
    });

    testWidgets('barra tem altura e divide proporcionalmente (62 x 38)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(MatchStatsSection(match: _match(), stats: const [possession])),
      );
      await tester.pump();
      final fills = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) {
            final size = tester.getSize(find.byWidget(box));
            return size.height == 6 && size.width < 356;
          })
          .map((box) => tester.getSize(find.byWidget(box)).width)
          .toList();
      expect(fills, hasLength(2));
      expect(fills[0] / (fills[0] + fills[1]), closeTo(0.62, 0.01));
    });

    testWidgets('bordas das barras: A>B, B>A, A==B, A=0, B=0, ambos 0', (
      tester,
    ) async {
      const cases = <(num, num)>[
        (70, 30),
        (30, 70),
        (50, 50),
        (0, 10),
        (10, 0),
        (0, 0),
        (1, 99999),
        (2.5, 7.5),
      ];
      for (final (a, b) in cases) {
        await tester.pumpWidget(
          _host(
            MatchStatsSection(
              match: _match(),
              stats: [
                MatchStat(
                  title: 'Escanteios',
                  unit: MatchStatUnit.count,
                  home: a,
                  away: b,
                ),
              ],
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$a x $b');
        for (final box in tester.widgetList<ColoredBox>(
          find.byType(ColoredBox),
        )) {
          final size = tester.getSize(find.byWidget(box));
          expect(size.width.isFinite && !size.width.isNaN, isTrue);
          expect(size.width, greaterThanOrEqualTo(0));
          expect(size.height, greaterThanOrEqualTo(0));
        }
        // 0 vindo da fonte é valor real e aparece.
        expect(find.text(a.round().toString()), findsWidgets);
        expect(find.text(b.round().toString()), findsWidgets);
      }
    });

    testWidgets('lado 0 não desenha a barra daquele lado', (tester) async {
      await tester.pumpWidget(
        _host(
          MatchStatsSection(
            match: _match(),
            stats: const [
              MatchStat(
                title: 'Escanteios',
                unit: MatchStatUnit.count,
                home: 0,
                away: 10,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      // Trilha + só o lado que tem valor (o lado 0 não gera barra).
      final bars = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .where((box) => tester.getSize(find.byWidget(box)).height == 6);
      expect(bars, hasLength(2));
    });

    testWidgets('lado nulo não aparece como zero; tudo nulo vira vazio', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MatchStatsSection(
            match: _match(),
            stats: const [
              MatchStat(
                title: 'Escanteios',
                unit: MatchStatUnit.count,
                home: 3,
              ),
              MatchStat(title: 'Posse de bola', unit: MatchStatUnit.percent),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Estatísticas ainda não disponíveis'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('zero real aparece como 0', (tester) async {
      await tester.pumpWidget(
        _host(
          MatchStatsSection(
            match: _match(),
            stats: const [
              MatchStat(
                title: 'Escanteios',
                unit: MatchStatUnit.count,
                home: 0,
                away: 0,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      expect(find.text('0'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rótulos traduzidos em EN e ES', (tester) async {
      for (final (locale, text) in [
        (const Locale('en'), 'Possession'),
        (const Locale('es'), 'Posesión'),
      ]) {
        await tester.pumpWidget(
          _host(
            MatchStatsSection(match: _match(), stats: const [possession]),
            locale: locale,
          ),
        );
        await tester.pump();
        expect(find.text(text), findsOneWidget);
      }
    });

    testWidgets('sem estatísticas: estado vazio', (tester) async {
      await tester.pumpWidget(
        _host(MatchStatsSection(match: _match(), stats: const [])),
      );
      await tester.pump();
      expect(find.text('Estatísticas ainda não disponíveis'), findsOneWidget);
    });
  });

  group('MatchLineupsSection', () {
    TeamLineup lineup(String name, List<List<LineupPlayer>> rows) =>
        TeamLineup(teamName: name, rows: rows);
    LineupPlayer p(String name, int number) =>
        LineupPlayer(name: name, jerseyNumber: number, photo: '');

    Finder teamTab(String name) => find.descendant(
      of: find.byType(FanHubTabBar),
      matching: find.text(name),
    );

    testWidgets('seletor mostra o nome dos dois times e abre no mandante', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MatchLineupsSection(
            match: _match(),
            lineups: MatchLineups(
              home: lineup('Fortaleza', [
                [p('Lucero', 9)],
                [p('Tinga', 2), p('Brítez', 4)],
                [p('João Ricardo', 1)],
              ]),
              away: lineup('Náutico', [
                [p('Paulo Sérgio', 9)],
                [p('Muriel', 1)],
              ]),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(teamTab('Fortaleza'), findsOneWidget);
      expect(teamTab('Náutico'), findsOneWidget);
      expect(find.text('Titulares'), findsOneWidget);
      // Mandante aberto: só os jogadores dele aparecem.
      expect(find.text('João Ricardo'), findsOneWidget);
      expect(find.text('Muriel'), findsNothing);
      // A fonte não traz reservas/técnico/formação: nada disso aparece.
      expect(find.text('Reservas'), findsNothing);
      expect(find.textContaining('Técnico'), findsNothing);
    });

    testWidgets('tocar no visitante troca o campo', (tester) async {
      await tester.pumpWidget(
        _host(
          MatchLineupsSection(
            match: _match(),
            lineups: MatchLineups(
              home: lineup('Fortaleza', [
                [p('João Ricardo', 1)],
              ]),
              away: lineup('Náutico', [
                [p('Muriel', 1)],
              ]),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(teamTab('Náutico'));
      await tester.pumpAndSettle();
      expect(find.text('Muriel'), findsOneWidget);
      expect(find.text('João Ricardo'), findsNothing);
    });

    testWidgets('as linhas da fonte viram linhas no campo (ataque em cima)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          MatchLineupsSection(
            match: _match(),
            lineups: MatchLineups(
              home: lineup('Fortaleza', [
                [p('Atacante', 9)],
                [p('MeioA', 8), p('MeioB', 10)],
                [p('Goleiro', 1)],
              ]),
              away: lineup('Náutico', [
                [p('Muriel', 1)],
              ]),
            ),
          ),
        ),
      );
      await tester.pump();
      double y(String t) => tester.getCenter(find.text(t)).dy;
      expect(y('Atacante'), lessThan(y('MeioA')));
      expect(y('MeioA'), lessThan(y('Goleiro')));
      expect(y('MeioA'), closeTo(y('MeioB'), 0.5));
    });

    testWidgets(
      'só um time com escalação: abre nele e o outro mostra o aviso',
      (tester) async {
        await tester.pumpWidget(
          _host(
            MatchLineupsSection(
              match: _match(),
              lineups: MatchLineups(
                home: lineup('Fortaleza', const []),
                away: lineup('Náutico', [
                  [p('Muriel', 1)],
                ]),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Muriel'), findsOneWidget);
        await tester.tap(teamTab('Fortaleza'));
        await tester.pumpAndSettle();
        expect(find.text('Escalação ainda não divulgada'), findsOneWidget);
        expect(find.text('Muriel'), findsNothing);
      },
    );

    testWidgets('sem escalação nenhuma: estado vazio i18n, sem seletor', (
      tester,
    ) async {
      for (final (locale, text) in [
        (const Locale('pt'), 'Escalação ainda não divulgada'),
        (const Locale('en'), 'Lineup not announced yet'),
        (const Locale('es'), 'Alineación aún no divulgada'),
      ]) {
        await tester.pumpWidget(
          _host(
            MatchLineupsSection(match: _match(), lineups: null),
            locale: locale,
          ),
        );
        await tester.pump();
        expect(find.text(text), findsOneWidget);
        expect(find.byType(FanHubTabBar), findsNothing);
      }
    });

    testWidgets(
      '11 e 18 jogadores, linhas vazias e camisa 0/100 não estouram',
      (tester) async {
        for (final width in [300.0, 390.0, 900.0]) {
          await tester.pumpWidget(
            _host(
              MatchLineupsSection(
                match: _match(),
                lineups: MatchLineups(
                  home: lineup('Fortaleza', [
                    [],
                    [
                      p('Sem Camisa', 0),
                      p('Jogador Com Um Nome Absurdamente Grande Da Silva', 99),
                      p('Camisa Cem', 100),
                      for (var i = 1; i <= 15; i++) p('Jogador $i', i),
                    ],
                    [],
                  ]),
                  away: lineup('Náutico', [[], []]),
                ),
              ),
              width: width,
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: '$width');
          expect(find.text('Camisa Cem'), findsOneWidget);
        }
      },
    );
  });

  group('MatchDetailsPage', () {
    Future<MatchDetailsCubit> loaded(
      WidgetTester tester, {
      List<MatchEvent> events = const [],
      MatchLineups? lineups,
      List<MatchStat> stats = const [],
    }) async {
      final repo = FakeFootballRepository()
        ..getMatchDetailsCall = () => Success((
          match: _match(
            status: MatchStatus.finished,
            homeScore: 1,
            awayScore: 1,
          ),
          events: events,
          lineups: lineups,
          stats: stats,
        ));
      final cubit = MatchDetailsCubit(repo, 'onef-1');
      await cubit.load();
      return cubit;
    }

    testWidgets('abas EVENTOS / ESTATÍSTICAS / ESCALAÇÕES trocam o conteúdo', (
      tester,
    ) async {
      final cubit = await loaded(
        tester,
        events: [_event("14'", MatchEventType.goal, player: 'Lucero')],
        stats: const [
          MatchStat(
            title: 'Posse de bola',
            unit: MatchStatUnit.percent,
            home: 62,
            away: 38,
          ),
        ],
        lineups: const MatchLineups(
          home: TeamLineup(
            teamName: 'Fortaleza',
            rows: [
              [LineupPlayer(name: 'João Ricardo', jerseyNumber: 1, photo: '')],
            ],
          ),
          away: TeamLineup(teamName: 'Náutico', rows: []),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MatchDetailsPage(fixtureId: 'onef-1', cubit: cubit),
        ),
      );
      await tester.pump();
      expect(find.text('Lucero'), findsOneWidget);
      expect(find.text('INFORMAÇÕES'), findsNothing);

      await tester.tap(find.text('ESTATÍSTICAS'));
      await tester.pumpAndSettle();
      expect(find.text('62%'), findsOneWidget);
      expect(find.text('Lucero'), findsNothing);

      await tester.tap(find.text('ESCALAÇÕES'));
      await tester.pumpAndSettle();
      expect(find.text('João Ricardo'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(FanHubTabBar).last,
          matching: find.text('Náutico'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Escalação ainda não divulgada'), findsOneWidget);

      await tester.tap(find.text('EVENTOS'));
      await tester.pumpAndSettle();
      expect(find.text('Lucero'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await cubit.close();
    });
  });
}
