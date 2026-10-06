import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_institutional_content.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/club/data/bragantino_idols_data.dart';
import 'package:goias_app/features/club/data/goias_idols_data.dart';
import 'package:goias_app/features/club/data/vilanova_idols_data.dart';
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
import 'package:goias_app/features/club/presentation/pages/club_idol_detail_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_idols_page.dart';
import 'package:goias_app/l10n/app_localizations.dart';

import '../../../../core/club/synthetic_club_config.dart';

/// Nomes REAIS do dataset do Bragantino, separados por tier — se o dataset
/// mudar de classificação, estes testes falham de propósito (é exatamente
/// a regra editorial que precisa continuar valendo).
const _tier1Names = [
  'Mauro Silva',
  'Lincom',
  'Léo Jaime',
  'Cleiton',
  'Gil Baiano',
  // 'Marcelo' REMOVIDO em 2026-09-09 — a foto entregue pra ele era do
  // técnico Marcelo Veiga (2018), mesma pessoa confirmada pelo usuário,
  // o que contradiz a descrição do ídolo (jogador da geração 1990-91).
  'Mazinho',
  'Luís Müller',
  // Promovidos de tier 2 em 2026-09-07 (docs/bragantino_data) — conquistas
  // concretas encontradas, não mais "revisão pendente".
  'Biro-Biro',
  'Ivair',
  // Adicionados na auditoria de elenco de 2026-09-30 (pesquisa dedicada,
  // fonte + período confirmados — ver bragantino_idols_data.dart).
  'Marcelo Martelotte',
  'Alberto Félix',
  'Wilsinho Acedo',
  'Hélio Burini',
  'Nivaldo "Queixo-de-mula"',
  'Ytalo',
  'Claudinho',
  'Artur',
  'Léo Ortiz',
  'Aderlan',
];
const _tier2Names = [
  'Tiba',
  'Júnior',
  'Nei',
  'Jadsom',
  'Lucas Evangelista',
  'Nardinho',
];
const _tier3Names = ['Adãozinho', 'Somália', 'Davi', 'Matheus Peixoto'];

ClubConfig _withIdols(ClubConfig base, List<ClubIdol> idols) => ClubConfig(
  identity: base.identity,
  branding: base.branding,
  assets: base.assets,
  integrations: base.integrations,
  capabilities: base.capabilities,
  productNames: base.productNames,
  passportContent: base.passportContent,
  membershipProgram: base.membershipProgram,
  institutionalContent: ClubInstitutionalContent(idols: idols),
);

void main() {
  Future<void> register(ClubConfig config) async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(config);
  }

  tearDown(sl.reset);

  Widget wrap({bool dark = false, double textScale = 1}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const ClubIdolsPage()),
        GoRoute(
          path: '/clube/idolos/detalhe',
          builder: (context, state) =>
              ClubIdolDetailPage(idol: state.extra! as ClubIdol),
        ),
      ],
    );
    return MaterialApp.router(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      locale: const Locale('pt'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  void useTallSurface(WidgetTester tester) {
    addTearDown(tester.view.reset);
    // Altura generosa o bastante pra caber todo o pool tier-1 do Bragantino
    // sem scroll (cresceu de 13 pra 20 nomes na auditoria de 2026-09-30).
    tester.view.physicalSize = const Size(800, 4200);
    tester.view.devicePixelRatio = 1.0;
  }

  group('publishedIdols — separação entre publicável e candidato/revisão', () {
    test('só tier 1 é publicável; tier 2 e 3 ficam fora', () {
      const content = ClubInstitutionalContent(
        idols: BragantinoIdolsData.idols,
      );
      final published = content.publishedIdols;

      expect(published, isNotEmpty);
      expect(published.every((idol) => idol.tier == 1), isTrue);
      expect(
        published.length,
        lessThan(BragantinoIdolsData.idols.length),
        reason: 'o pool bruto tem candidatos que não podem ir pro torcedor',
      );
      for (final idol in BragantinoIdolsData.idols.where((i) => i.tier > 1)) {
        expect(idol.isPublishable, isFalse, reason: idol.name);
      }
    });

    test('clube sem ídolo nenhum devolve lista vazia, nunca a de outro', () {
      const empty = ClubInstitutionalContent();
      expect(empty.publishedIdols, isEmpty);
      // 3º clube (sintético) prova que o vazio não é um caso especial do
      // Goiás — nenhum clube herda a lista de outro por omissão.
      expect(syntheticClubBConfig.institutionalContent.publishedIdols, isEmpty);
    });

    test('nenhum nome do Bragantino existe no conteúdo de outro clube', () {
      final bragantinoNames = BragantinoIdolsData.idols
          .map((idol) => idol.name)
          .toSet();
      for (final config in [goiasClubConfig, syntheticClubBConfig]) {
        final names = config.institutionalContent.idols
            .map((idol) => idol.name)
            .toSet();
        expect(names.intersection(bragantinoNames), isEmpty);
      }
    });
  });

  testWidgets('Bragantino lista os ídolos publicáveis do clube ativo', (
    tester,
  ) async {
    useTallSurface(tester);
    await register(bragantinoClubConfig);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    for (final name in _tier1Names) {
      expect(
        find.text(name, skipOffstage: false),
        findsOneWidget,
        reason: '$name é tier 1, deveria aparecer',
      );
    }
  });

  testWidgets('registros em revisão (tier 2/3) nunca aparecem pro torcedor', (
    tester,
  ) async {
    useTallSurface(tester);
    await register(bragantinoClubConfig);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    for (final name in [..._tier2Names, ..._tier3Names]) {
      expect(
        find.text(name, skipOffstage: false),
        findsNothing,
        reason: '$name ainda está em revisão editorial',
      );
    }
    // Nem o texto que denuncia o estado editorial pode vazar.
    expect(find.textContaining('revisão', skipOffstage: false), findsNothing);
    expect(find.textContaining('pendente', skipOffstage: false), findsNothing);
  });

  testWidgets('nenhum rótulo interno de tier/evidência vai pra tela', (
    tester,
  ) async {
    useTallSurface(tester);
    await register(bragantinoClubConfig);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    for (final internal in [
      'Tier 1',
      'Tier 2',
      'Tier 3',
      'tier',
      'REVIEW',
      'CANDIDATE',
      'High confidence',
    ]) {
      expect(
        find.textContaining(internal, skipOffstage: false),
        findsNothing,
        reason: '"$internal" é metadado interno',
      );
    }
  });

  testWidgets('Goiás (dataset próprio) não recebe os ídolos do Bragantino', (
    tester,
  ) async {
    useTallSurface(tester);
    await register(goiasClubConfig);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    for (final name in _tier1Names) {
      expect(
        find.text(name, skipOffstage: false),
        findsNothing,
        reason: 'nenhum fallback cross-club: $name é do Bragantino',
      );
    }
  });

  testWidgets('a página resolve o clube ativo a cada abertura', (tester) async {
    useTallSurface(tester);

    await register(bragantinoClubConfig);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('Mauro Silva', skipOffstage: false), findsOneWidget);

    await register(goiasClubConfig);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('Mauro Silva', skipOffstage: false), findsNothing);
  });

  testWidgets('ídolo sem foto renderiza card com iniciais, sem quebrar', (
    tester,
  ) async {
    useTallSurface(tester);
    await register(
      _withIdols(bragantinoClubConfig, const [
        ClubIdol(
          name: 'Nome Sem Foto',
          tier: 1,
          evidenceExplicitIdol: true,
          description: 'Descrição de teste.',
        ),
      ]),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Nome Sem Foto'), findsOneWidget);
    // Primeira + última palavra do nome, mesma regra do avatar da Diretoria.
    expect(find.text('NF'), findsOneWidget, reason: 'iniciais do nome');
    // O avatar (ClipOval) não pode conter imagem nenhuma — o escudo do
    // clube no cabeçalho é outra coisa e continua ali de propósito.
    expect(
      find.descendant(of: find.byType(ClipOval), matching: find.byType(Image)),
      findsNothing,
      reason: 'nunca uma foto genérica fingindo ser o jogador',
    );
  });

  testWidgets('posição/período só aparecem quando existem de verdade', (
    tester,
  ) async {
    useTallSurface(tester);
    await register(
      _withIdols(bragantinoClubConfig, const [
        ClubIdol(
          name: 'Com Dados',
          tier: 1,
          evidenceExplicitIdol: true,
          description: 'Descrição.',
          position: 'Volante',
          period: '1988-1991',
        ),
        ClubIdol(
          name: 'Sem Dados',
          tier: 1,
          evidenceExplicitIdol: true,
          description: 'Descrição.',
        ),
      ]),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Volante · 1988-1991'), findsOneWidget);
    // O card sem posição/período não inventa um traço solto nem placeholder.
    expect(find.textContaining('·'), findsOneWidget);
  });

  testWidgets('asset de foto inexistente cai nas iniciais sem quebrar a tela', (
    tester,
  ) async {
    useTallSurface(tester);
    await register(
      _withIdols(bragantinoClubConfig, const [
        ClubIdol(
          name: 'Foto Quebrada',
          tier: 1,
          evidenceExplicitIdol: true,
          description: 'Descrição.',
          photoAsset: 'test/assets/nao_existe.png',
        ),
      ]),
    );
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Foto Quebrada'), findsOneWidget);
    expect(find.text('FQ'), findsOneWidget);
  });

  testWidgets('clube sem ídolos publicáveis mostra estado vazio, não erro', (
    tester,
  ) async {
    useTallSurface(tester);
    await register(
      _withIdols(bragantinoClubConfig, const [
        ClubIdol(
          name: 'Só Candidato',
          tier: 3,
          evidenceExplicitIdol: false,
          description: 'Ainda em revisão.',
        ),
      ]),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Só Candidato', skipOffstage: false), findsNothing);
    expect(find.text('Ídolos'), findsWidgets);
  });

  group('Goiás — 37 ídolos', () {
    for (final dark in [false, true]) {
      testWidgets('lista todos os 37 no tema ${dark ? 'escuro' : 'claro'}', (
        tester,
      ) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(800, 9000);
        tester.view.devicePixelRatio = 1.0;
        await register(goiasClubConfig);
        await tester.pumpWidget(wrap(dark: dark));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        for (final idol in GoiasIdolsData.idols) {
          expect(
            find.text(idol.name, skipOffstage: false),
            findsOneWidget,
            reason: idol.name,
          );
        }
        expect(find.text('37 ÍDOLOS', skipOffstage: false), findsOneWidget);
      });
    }

    testWidgets(
      'tela estreita + texto grande: nenhum overflow em nenhum card',
      (tester) async {
        addTearDown(tester.view.reset);
        tester.view.physicalSize = const Size(320, 30000);
        tester.view.devicePixelRatio = 1.0;
        await register(goiasClubConfig);
        await tester.pumpWidget(wrap(textScale: 1.6));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Harlei', skipOffstage: false), findsOneWidget);
      },
    );

    testWidgets('rola até o fim da lista (Tadeu é o último, cronológico)', (
      tester,
    ) async {
      await register(goiasClubConfig);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Tadeu'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Tadeu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('dados opcionais: quem não tem fonte fica sem o campo, nunca com '
        'palpite', () {
      final byName = {for (final i in GoiasIdolsData.idols) i.name: i};
      // Marquinhos (identidade fechada em 2026-10-03): sem total de jogos/gols.
      expect(byName['Marquinhos']!.matches, isNull);
      expect(byName['Marquinhos']!.goals, isNull);
      // Dill: sem total de jogos (o do ogol era recorte parcial).
      expect(byName['Dill']!.matches, isNull);
      // Ernando: sem gols até haver fonte explícita pelo Goiás.
      expect(byName['Ernando']!.goals, isNull);
      // Período divergente entre fontes — fica de fora.
      expect(byName['Amauri']!.period, isNull);
      expect(byName['Edson Mug']!.period, '1983-1984');
      // Estatística de quem segue em atividade sempre com data.
      expect(byName['Tadeu']!.description, contains('28/08/2026'));
    });
  });

  group('Detalhe do ídolo', () {
    test('Bragantino e Vila Nova não usam os campos de detalhe — os cards '
        'deles continuam estáticos, como sempre foram', () {
      expect(BragantinoIdolsData.idols.where((i) => i.hasDetail), isEmpty);
      expect(VilaNovaIdolsData.idols.where((i) => i.hasDetail), isEmpty);
    });

    testWidgets('card do Bragantino não tem seta nem abre nada', (
      tester,
    ) async {
      useTallSurface(tester);
      await register(bragantinoClubConfig);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
      await tester.tap(find.text('Mauro Silva'));
      await tester.pumpAndSettle();
      expect(find.byType(ClubIdolDetailPage), findsNothing);
    });

    testWidgets('Goiás: tocar no Harlei abre o detalhe com números e títulos', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(800, 9000);
      tester.view.devicePixelRatio = 1.0;
      await register(goiasClubConfig);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Harlei'));
      await tester.pumpAndSettle();

      expect(find.byType(ClubIdolDetailPage), findsOneWidget);
      expect(find.text('Harlei de Menezes Silva'), findsOneWidget);
      expect(find.text('831'), findsOneWidget);
      expect(find.text('JOGOS'), findsOneWidget);
      // Sem gols confirmados → sem a caixa de gols (nunca um "0" inventado).
      expect(find.text('GOLS'), findsNothing);
      expect(find.text('TÍTULOS'), findsOneWidget);
      expect(find.text('Campeonato Brasileiro Série B 2012'), findsOneWidget);
      expect(find.text('CAMPANHAS E MOMENTOS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    Future<void> openDetail(
      WidgetTester tester,
      ClubIdol idol, {
      bool dark = false,
      double width = 800,
      double textScale = 1,
    }) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = Size(width, 2400);
      tester.view.devicePixelRatio = 1.0;
      await register(goiasClubConfig);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => ClubIdolDetailPage(idol: idol),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();
    }

    ClubIdol goias(String name) =>
        GoiasIdolsData.idols.firstWhere((i) => i.name == name);

    testWidgets(
      'jogador em atividade mostra a data de referência dos números',
      (tester) async {
        await openDetail(tester, goias('Tadeu'));
        expect(find.text('406'), findsOneWidget);
        expect(find.text('Números até 01/10/2026'), findsOneWidget);
      },
    );

    testWidgets('números parciais dizem a que se referem', (tester) async {
      await openDetail(tester, goias('Walter'));
      expect(find.text('48'), findsOneWidget);
      expect(
        find.text('Somando as duas passagens (2012-2013 e 2016-2017)'),
        findsOneWidget,
      );
    });

    testWidgets('ídolo sem números/títulos não mostra essas seções', (
      tester,
    ) async {
      await openDetail(
        tester,
        const ClubIdol(
          name: 'Fulano',
          tier: 1,
          evidenceExplicitIdol: false,
          description: 'Sem dados além do nome.',
          fullName: 'Fulano de Tal',
        ),
      );
      expect(find.text('Fulano de Tal'), findsOneWidget);
      expect(find.text('JOGOS'), findsNothing);
      expect(find.text('TÍTULOS'), findsNothing);
      expect(find.text('CAMPANHAS E MOMENTOS'), findsNothing);
      expect(find.text('HISTÓRIA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detalhe em tela estreita, texto grande e tema escuro: '
        'sem overflow em nenhum ídolo do Goiás', (tester) async {
      for (final idol in GoiasIdolsData.idols.where((i) => i.hasDetail)) {
        await openDetail(tester, idol, dark: true, width: 320, textScale: 1.6);
        expect(tester.takeException(), isNull, reason: idol.name);
      }
    });
  });
}
