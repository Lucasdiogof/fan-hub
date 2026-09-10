import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/match/domain/entities/knockout_round.dart';
import 'package:goias_app/features/match/domain/entities/knockout_tie.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/stage_status.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/knockout_stage_view.dart';
import 'package:goias_app/l10n/app_localizations.dart';

// Fixture explicitamente Goiás (TEST_FIXTURE_ALLOWED) — mesmo id de
// `goiasClubConfig.integrations.oneFootballTeamId`, usado pra testar o
// destaque do clube do flavor de forma genérica (spec item 10/12).
const _goiasTeamId = 1863;
const _goias = Team(
  id: _goiasTeamId,
  name: 'Goiás',
  shortName: 'GOI',
  color: Color(0xFF004C1B),
);
const _rival = Team(
  id: 2,
  name: 'Vila Nova',
  shortName: 'VNO',
  color: Color(0xFF1F6F4A),
);

Widget _wrap(Widget child, {double width = 360}) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SizedBox(
      width: width,
      child: SingleChildScrollView(child: child),
    ),
  ),
);

/// O escudo de um time sem `logoUrl` cai no fallback com as iniciais do
/// time (`ClubBadge`/`_ShieldBadge`) — o MESMO texto do nome curto que o
/// `_TeamRow` também mostra ao lado. Pra não confundir esse fallback com o
/// rótulo de verdade do confronto, filtra pelo tamanho de fonte real do
/// rótulo (13) — o do badge sai bem menor (proporcional ao tamanho do
/// escudo).
Finder _teamLabel(String label) => find.byWidgetPredicate(
  (w) => w is Text && w.data == label && w.style?.fontSize == 13,
);

KnockoutRound _roundOf(
  String name,
  List<KnockoutTie> ties, {
  bool isCurrent = true,
}) => KnockoutRound(
  id: name,
  name: name,
  order: 0,
  status: StageStatus.active,
  isCurrent: isCurrent,
  ties: ties,
);

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  testWidgets(
    'ida e volta: mostra as DUAS pernas lado a lado, mais o agregado',
    (tester) async {
      // Placares escolhidos pra nunca colidir entre si (ida/volta/agregado
      // sempre distintos) — só pra o teste conseguir apontar exatamente qual
      // número está em qual coluna, sem sugerir que jogos de verdade tenham
      // esses placares.
      const tie = KnockoutTie(
        homeTeam: _goias,
        awayTeam: _rival,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.first,
            status: MatchStatus.finished,
            homeScore: 6,
            awayScore: 1,
          ),
          KnockoutLeg(
            legType: KnockoutLegType.second,
            status: MatchStatus.finished,
            homeScore: 2,
            awayScore: 4,
          ),
        ],
        aggregateHome: 8,
        aggregateAway: 5,
      );
      await tester.pumpWidget(
        _wrap(
          KnockoutStageView(
            rounds: [
              _roundOf('Semifinais', [tie]),
            ],
          ),
        ),
      );

      expect(find.text('6'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      // Ida/Volta/Placar como cabeçalho de coluna.
      expect(find.text('Ida'), findsOneWidget);
      expect(find.text('Volta'), findsOneWidget);
    },
  );

  testWidgets('jogo único: NÃO cria coluna "Volta" artificial nem cabeçalho', (
    tester,
  ) async {
    const tie = KnockoutTie(
      homeTeam: _goias,
      awayTeam: _rival,
      legs: [
        KnockoutLeg(
          legType: KnockoutLegType.single,
          status: MatchStatus.finished,
          homeScore: 2,
          awayScore: 1,
        ),
      ],
      aggregateHome: 2,
      aggregateAway: 1,
    );
    await tester.pumpWidget(
      _wrap(
        KnockoutStageView(
          rounds: [
            _roundOf('Final', [tie]),
          ],
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Ida'), findsNothing);
    expect(find.text('Volta'), findsNothing);
  });

  testWidgets('pênaltis: aparecem compactos junto do agregado, nunca somados', (
    tester,
  ) async {
    const tie = KnockoutTie(
      homeTeam: _goias,
      awayTeam: _rival,
      legs: [
        KnockoutLeg(
          legType: KnockoutLegType.first,
          status: MatchStatus.finished,
          homeScore: 1,
          awayScore: 0,
        ),
        KnockoutLeg(
          legType: KnockoutLegType.second,
          status: MatchStatus.finished,
          homeScore: 0,
          awayScore: 1,
        ),
      ],
      aggregateHome: 1,
      aggregateAway: 1,
      penaltyHome: 8,
      penaltyAway: 7,
    );
    await tester.pumpWidget(
      _wrap(
        KnockoutStageView(
          rounds: [
            _roundOf('Final', [tie]),
          ],
        ),
      ),
    );

    expect(find.text('1 (8)'), findsOneWidget);
    expect(find.text('1 (7)'), findsOneWidget);
    // Nunca "9-8" ou qualquer soma dos pênaltis com o agregado.
    expect(find.textContaining('9'), findsNothing);
  });

  testWidgets(
    'confronto futuro sem placar nenhum: mostra "-" nas duas pernas, nunca esconde o card',
    (tester) async {
      const tie = KnockoutTie(
        homeTeam: _goias,
        awayTeam: _rival,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.first,
            status: MatchStatus.scheduled,
          ),
          KnockoutLeg(
            legType: KnockoutLegType.second,
            status: MatchStatus.scheduled,
          ),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          KnockoutStageView(
            rounds: [
              _roundOf('Quartas', [tie]),
            ],
          ),
        ),
      );

      expect(_teamLabel('Goiás'), findsOneWidget);
      expect(_teamLabel('Vila Nova'), findsOneWidget);
      expect(find.text('-'), findsNWidgets(4)); // ida+volta × 2 times
    },
  );

  testWidgets(
    'só a ida foi disputada: ida mostra placar real, volta fica pendente',
    (tester) async {
      const tie = KnockoutTie(
        homeTeam: _goias,
        awayTeam: _rival,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.first,
            status: MatchStatus.finished,
            homeScore: 2,
            awayScore: 0,
          ),
          KnockoutLeg(
            legType: KnockoutLegType.second,
            status: MatchStatus.scheduled,
          ),
        ],
      );
      await tester.pumpWidget(
        _wrap(
          KnockoutStageView(
            rounds: [
              _roundOf('Quartas', [tie]),
            ],
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('-'), findsNWidgets(2)); // volta pendente × 2 times
    },
  );

  testWidgets(
    'destaque do clube do flavor: aplicado genericamente via ClubConfig, nunca hardcoded',
    (tester) async {
      const tie = KnockoutTie(
        homeTeam: _goias,
        awayTeam: _rival,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.single,
            status: MatchStatus.finished,
            homeScore: 1,
            awayScore: 0,
          ),
        ],
        aggregateHome: 1,
        aggregateAway: 0,
      );
      await tester.pumpWidget(
        _wrap(
          KnockoutStageView(
            rounds: [
              _roundOf('Final', [tie]),
            ],
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      final highlighted = containers.where((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      });
      expect(
        highlighted,
        isNotEmpty,
        reason:
            'a linha do Goiás (clube ativo) precisa ter uma borda de destaque',
      );
    },
  );

  testWidgets(
    'ausência de escudo: cai no placeholder padrão sem quebrar o layout',
    (tester) async {
      const noBadgeTeam = Team(
        id: 999,
        name: 'Time Sem Escudo',
        shortName: 'TSE',
        color: Color(0xFF333333),
      );
      const tie = KnockoutTie(
        homeTeam: noBadgeTeam,
        awayTeam: _rival,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.single,
            status: MatchStatus.finished,
            homeScore: 1,
            awayScore: 1,
          ),
        ],
        aggregateHome: 1,
        aggregateAway: 1,
      );
      await tester.pumpWidget(
        _wrap(
          KnockoutStageView(
            rounds: [
              _roundOf('Final', [tie]),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_teamLabel('Time Sem Escudo'), findsOneWidget);
    },
  );

  testWidgets(
    'fases fora da ordem alfabética: seletor respeita a ordem em que as rounds chegam',
    (tester) async {
      const tie = KnockoutTie(
        homeTeam: _goias,
        awayTeam: _rival,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.single,
            status: MatchStatus.finished,
            homeScore: 1,
            awayScore: 0,
          ),
        ],
        aggregateHome: 1,
        aggregateAway: 0,
      );
      // "Playoffs" cronologicamente antes de "Oitavas" — ordem NÃO alfabética
      // (Oitavas < Playoffs em ordem alfabética), mas é a ordem que o Worker
      // já entrega (cronológica real).
      await tester.pumpWidget(
        _wrap(
          KnockoutStageView(
            rounds: [
              _roundOf('Playoffs', [tie], isCurrent: false),
              _roundOf('Oitavas', [tie]),
            ],
          ),
        ),
      );

      final chipFinder = find.byType(Row).first;
      expect(chipFinder, findsOneWidget);
      expect(find.text('Playoffs'), findsOneWidget);
      expect(find.text('Oitavas'), findsOneWidget);
    },
  );

  testWidgets(
    'uma única rodada: seletor de fase some sozinho (nada pra escolher)',
    (tester) async {
      const tie = KnockoutTie(
        homeTeam: _goias,
        awayTeam: _rival,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.single,
            status: MatchStatus.finished,
            homeScore: 1,
            awayScore: 0,
          ),
        ],
        aggregateHome: 1,
        aggregateAway: 0,
      );
      await tester.pumpWidget(
        _wrap(
          KnockoutStageView(
            rounds: [
              _roundOf('Final', [tie]),
            ],
          ),
        ),
      );

      // "Final" aparece só uma vez — como resultado do card, não como chip
      // de seletor duplicado (o seletor não é renderizado com 1 item só).
      expect(find.text('Final'), findsNothing);
    },
  );

  testWidgets('nomes longos: truncam com ellipsis, nunca sobre os números', (
    tester,
  ) async {
    const longNameTeam = Team(
      id: 500,
      name: 'Associação Atlética Muito Extensa Futebol Clube',
      shortName: 'Associação Atlética Muito Extensa Futebol Clube',
      color: Color(0xFF444444),
    );
    const tie = KnockoutTie(
      homeTeam: longNameTeam,
      awayTeam: _rival,
      legs: [
        KnockoutLeg(
          legType: KnockoutLegType.single,
          status: MatchStatus.finished,
          homeScore: 3,
          awayScore: 1,
        ),
      ],
      aggregateHome: 3,
      aggregateAway: 1,
    );
    // Largura estreita de propósito (Android pequeno) — o teste falha com
    // overflow se o nome não truncar.
    await tester.pumpWidget(
      _wrap(
        KnockoutStageView(
          rounds: [
            _roundOf('Final', [tie]),
          ],
        ),
        width: 300,
      ),
    );

    expect(tester.takeException(), isNull);
    final text = tester.widget<Text>(_teamLabel(longNameTeam.shortName));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.maxLines, 1);
    // O placar continua visível mesmo com o nome gigante.
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets(
    'sem scroll horizontal nos cards de confronto (só o seletor de fase pode ter)',
    (tester) async {
      const tie = KnockoutTie(
        homeTeam: _goias,
        awayTeam: _rival,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.first,
            status: MatchStatus.finished,
            homeScore: 1,
            awayScore: 0,
          ),
          KnockoutLeg(
            legType: KnockoutLegType.second,
            status: MatchStatus.finished,
            homeScore: 0,
            awayScore: 0,
          ),
        ],
        aggregateHome: 1,
        aggregateAway: 0,
      );
      await tester.pumpWidget(
        _wrap(
          KnockoutStageView(
            rounds: [
              _roundOf('Oitavas', [tie], isCurrent: false),
              _roundOf('Quartas', [tie]),
            ],
          ),
          width: 320,
        ),
      );

      expect(tester.takeException(), isNull);
      // O único scroll horizontal permitido é o seletor de fase — os cards
      // ficam numa Column vertical comum, nunca dentro de um
      // SingleChildScrollView/ListView horizontal.
      final horizontalScrollables = tester
          .widgetList<Scrollable>(find.byType(Scrollable))
          .where(
            (s) =>
                s.axisDirection == AxisDirection.right ||
                s.axisDirection == AxisDirection.left,
          );
      expect(horizontalScrollables.length, 1);
    },
  );

  testWidgets(
    'múltiplos confrontos na mesma rodada: cada um é um card vertical independente',
    (tester) async {
      const tieA = KnockoutTie(
        homeTeam: _goias,
        awayTeam: _rival,
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.single,
            status: MatchStatus.finished,
            homeScore: 2,
            awayScore: 1,
          ),
        ],
        aggregateHome: 2,
        aggregateAway: 1,
      );
      const tieB = KnockoutTie(
        homeTeam: Team(
          id: 3,
          name: 'C',
          shortName: 'C',
          color: Color(0xFF000000),
        ),
        awayTeam: Team(
          id: 4,
          name: 'D',
          shortName: 'D',
          color: Color(0xFF000000),
        ),
        legs: [
          KnockoutLeg(
            legType: KnockoutLegType.single,
            status: MatchStatus.finished,
            homeScore: 0,
            awayScore: 0,
          ),
        ],
        aggregateHome: 0,
        aggregateAway: 0,
      );
      await tester.pumpWidget(
        _wrap(
          KnockoutStageView(
            rounds: [
              _roundOf('Quartas', [tieA, tieB]),
            ],
          ),
        ),
      );

      expect(_teamLabel('Goiás'), findsOneWidget);
      expect(_teamLabel('C'), findsOneWidget);
      expect(_teamLabel('D'), findsOneWidget);
    },
  );
}
