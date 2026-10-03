import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';
import 'package:goias_app/features/match/presentation/widgets/match_list_item.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/shared/utils/brazil_time.dart';

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
