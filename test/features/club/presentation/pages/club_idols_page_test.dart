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
import 'package:goias_app/features/club/domain/entities/club_idol.dart';
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

    testWidgets('tela estreita + texto grande: nenhum overflow em nenhum card', (
      tester,
    ) async {
      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(320, 30000);
      tester.view.devicePixelRatio = 1.0;
      await register(goiasClubConfig);
      await tester.pumpWidget(wrap(textScale: 1.6));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Harlei', skipOffstage: false), findsOneWidget);
    });

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
      // Identidade ainda não definida — só o nome.
      expect(byName['Marquinhos']!.description, isEmpty);
      expect(byName['Marquinhos']!.position, isNull);
      expect(byName['Marquinhos']!.period, isNull);
      // Período divergente entre fontes — fica de fora.
      expect(byName['Amauri']!.period, isNull);
      expect(byName['Edson Mug']!.period, isNull);
      // Estatística de quem segue em atividade sempre com data.
      expect(byName['Tadeu']!.description, contains('28/08/2026'));
    });
  });
}
