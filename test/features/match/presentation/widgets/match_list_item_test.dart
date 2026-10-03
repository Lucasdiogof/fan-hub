import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/match_list_item.dart';
import 'package:goias_app/features/match/presentation/widgets/match_team_name.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';
import 'package:goias_app/shared/widgets/club_badge.dart';

Team _team(int id, String name) =>
    Team(id: id, name: name, shortName: name, color: const Color(0xFF1F6F4A));

Match _match(
  String home,
  String away, {
  MatchStatus status = MatchStatus.scheduled,
  int? homeScore,
  int? awayScore,
  DateTime? kickoff,
  String stadium = '',
}) => Match(
  id: '$home-$away',
  competition: 'Série B',
  round: 'Rodada 1',
  homeTeam: _team(10, home),
  awayTeam: _team(20, away),
  stadium: stadium,
  kickoff: kickoff ?? DateTime.utc(2026, 10, 2, 22),
  status: status,
  homeScore: homeScore,
  awayScore: awayScore,
);

Widget _host(
  List<Widget> children, {
  double width = 360,
  ThemeData? theme,
  double textScale = 1,
}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, app) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: app!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              for (final child in children) ...[
                child,
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    ),
  ),
);

List<Widget> _cases() => [
  MatchListItem(
    match: _match(
      'Londrina',
      'Criciúma',
      status: MatchStatus.finished,
      homeScore: 0,
      awayScore: 2,
    ),
  ),
  MatchListItem(
    match: _match(
      'Juventude',
      'Operário',
      status: MatchStatus.finished,
      homeScore: 3,
      awayScore: 0,
    ),
  ),
  MatchListItem(
    match: _match(
      'Fortaleza',
      'Náutico',
      status: MatchStatus.live,
      homeScore: 1,
      awayScore: 1,
    ),
  ),
  MatchListItem(match: _match('Avaí', 'Ceará')),
  MatchListItem(match: _match('Atlético-GO', 'América-MG')),
  MatchListItem(
    match: _match(
      'Athletico Paranaense',
      'Vasco da Gama',
      stadium: 'Estádio Ildefonso',
    ),
  ),
];

void main() {
  setUpAll(initializeBrazilTimeZone);

  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  for (final width in [300.0, 320.0, 360.0, 390.0, 600.0]) {
    for (final dark in [false, true]) {
      testWidgets(
        'sem overflow em ${width.toInt()}px, ${dark ? 'escuro' : 'claro'}',
        (tester) async {
          await tester.pumpWidget(
            _host(
              _cases(),
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

  testWidgets('placar e horário ficam sempre no mesmo eixo central', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_cases()));
    await tester.pump();
    final xs = [
      tester.getCenter(find.text('0 x 2')).dx,
      tester.getCenter(find.text('3 x 0')).dx,
      tester.getCenter(find.text('1 x 1')).dx,
      tester.getCenter(find.text('19:00').first).dx,
    ];
    expect(xs.toSet(), hasLength(1), reason: '$xs');
  });

  testWidgets('largura reservada ao centro é fixa', (tester) async {
    await tester.pumpWidget(_host(_cases()));
    await tester.pump();
    final centers = tester
        .widgetList<SizedBox>(find.byType(SizedBox))
        .where((box) => box.width == MatchListItem.centerWidth);
    expect(centers, isNotEmpty);
  });

  // Obs.: o teste de widget usa a fonte de teste (muito mais larga que a real),
  // então aqui só se verifica a regra de degraus de tamanho, não o encaixe fino.
  testWidgets('nomes usam 13px quando há espaço e nunca descem de 11px', (
    tester,
  ) async {
    Iterable<double> nameSizes(String prefix) => tester
        .widgetList<Text>(find.byType(Text))
        .where(
          (t) =>
              t.style?.fontWeight == FontWeight.w700 &&
              (t.data ?? '').startsWith(prefix),
        )
        .map((t) => t.style!.fontSize!);

    await tester.pumpWidget(_host(_cases(), width: 900));
    await tester.pump();
    expect(nameSizes('Londrina'), [13.0]);

    await tester.pumpWidget(_host(_cases(), width: 300));
    await tester.pump();
    final sizes = nameSizes('Athletico');
    expect(sizes, isNotEmpty);
    expect(sizes.every((size) => size >= 11 && size <= 13), isTrue);
  });

  group('nomes completos em até 2 linhas', () {
    final names = [
      ('Grêmio Novorizontino', 'Goiás'),
      ('Goiás', 'Grêmio Novorizontino'),
      ('Atlético Goianiense', 'América Mineiro'),
      ('Red Bull Bragantino', 'Athletic Club'),
      ('Operário Ferroviário', 'Atlético Mineiro'),
      ('Avaí', 'Ceará'),
    ];

    List<Widget> cards() => [
      for (final (home, away) in names)
        MatchListItem(
          match: _match(
            home,
            away,
            status: MatchStatus.finished,
            homeScore: 3,
            awayScore: 0,
          ),
        ),
    ];

    testWidgets('nenhum nome usa reticências e o texto é o completo', (
      tester,
    ) async {
      for (final width in [300.0, 320.0, 360.0, 390.0, 900.0]) {
        await tester.pumpWidget(_host(cards(), width: width));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '$width');
        final texts = tester.widgetList<Text>(
          find.descendant(
            of: find.byType(MatchTeamName),
            matching: find.byType(Text),
          ),
        );
        expect(texts, hasLength(names.length * 2));
        for (final text in texts) {
          expect(
            text.overflow,
            isNot(TextOverflow.ellipsis),
            reason: '${text.data} @ $width',
          );
          expect(text.softWrap, isTrue);
          expect(text.maxLines == null || text.maxLines == 2, isTrue);
        }
        for (final (home, away) in names) {
          expect(find.text(home), findsWidgets);
          expect(find.text(away), findsWidgets);
        }
      }
    });

    testWidgets('placar no mesmo eixo X e Y em todos os cards (1 e 2 linhas)', (
      tester,
    ) async {
      await tester.pumpWidget(_host(cards(), width: 600));
      await tester.pump();
      final scores = find.text('3 x 0');
      expect(scores, findsNWidgets(names.length));
      final items = find.byType(MatchListItem);
      final xs = <double>{};
      final ys = <double>{};
      for (var i = 0; i < names.length; i++) {
        final center = tester.getCenter(scores.at(i));
        final top = tester.getTopLeft(items.at(i));
        xs.add(center.dx);
        ys.add((center.dy - top.dy).roundToDouble());
      }
      expect(xs, hasLength(1), reason: '$xs');
      expect(ys, hasLength(1), reason: '$ys');
    });

    testWidgets(
      'escudos dos dois lados alinhados na vertical, com 1 ou 2 linhas',
      (tester) async {
        await tester.pumpWidget(_host(cards(), width: 600));
        await tester.pump();
        final badges = find.byType(ClubBadge);
        expect(badges, findsNWidgets(names.length * 2));
        for (var i = 0; i < names.length; i++) {
          final home = tester.getCenter(badges.at(i * 2)).dy;
          final away = tester.getCenter(badges.at(i * 2 + 1)).dy;
          expect(home, closeTo(away, 0.5), reason: 'card $i');
        }
      },
    );

    testWidgets('todo card tem a mesma altura (reserva duas linhas)', (
      tester,
    ) async {
      await tester.pumpWidget(_host(cards(), width: 600));
      await tester.pump();
      final heights = {
        for (var i = 0; i < names.length; i++)
          tester.getSize(find.byType(MatchListItem).at(i)).height,
      };
      expect(heights, hasLength(1), reason: '$heights');
    });
  });

  testWidgets('AO VIVO só aparece no jogo em andamento', (tester) async {
    await tester.pumpWidget(_host(_cases()));
    await tester.pump();
    expect(find.text('AO VIVO'), findsOneWidget);
  });

  testWidgets('jogo futuro mostra horário; finalizado mostra placar', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_cases()));
    await tester.pump();
    expect(find.text('0 x 2'), findsOneWidget);
    expect(find.text('11:00'), findsNothing);
    expect(find.text('19:00'), findsWidgets);
  });

  testWidgets('estádio continua aparecendo quando existe', (tester) async {
    await tester.pumpWidget(_host(_cases()));
    await tester.pump();
    expect(find.text('Estádio Ildefonso'), findsOneWidget);
  });

  testWidgets('toque chama onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _host([
        MatchListItem(
          match: _match('Avaí', 'Ceará'),
          onTap: () => tapped = true,
        ),
      ]),
    );
    await tester.tap(find.byType(MatchListItem));
    expect(tapped, isTrue);
  });

  testWidgets('fonte do sistema grande não estoura', (tester) async {
    await tester.pumpWidget(_host(_cases(), width: 320, textScale: 1.4));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
