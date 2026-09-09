import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_assets.dart';
import 'package:goias_app/core/club/club_branding.dart';
import 'package:goias_app/core/club/club_capabilities.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/club_identity.dart';
import 'package:goias_app/core/club/club_integrations.dart';
import 'package:goias_app/core/club/club_product_naming.dart';
import 'package:goias_app/core/club/commerce_mode.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_colors.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/club/data/bragantino_history_data.dart';
import 'package:goias_app/features/club/data/bragantino_songs_data.dart';
import 'package:goias_app/features/club/data/bragantino_timeline_data.dart';
import 'package:goias_app/features/club/data/bragantino_titles_data.dart';
import 'package:goias_app/features/club/data/club_history_data.dart';
import 'package:goias_app/features/club/data/club_songs_data.dart';
import 'package:goias_app/features/club/data/club_timeline_data.dart';
import 'package:goias_app/features/club/data/club_titles_data.dart';
import 'package:goias_app/features/club/domain/entities/club_song.dart';
import 'package:goias_app/features/club/presentation/pages/club_history_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_songs_page.dart';
import 'package:goias_app/features/club/presentation/pages/club_titles_page.dart';
import 'package:goias_app/features/partners/data/bragantino_partners_data.dart';
import 'package:goias_app/features/partners/data/partners_data.dart';
import 'package:goias_app/features/partners/presentation/pages/partners_page.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'synthetic_passport_content.dart';

/// Clube sintético sem NENHUM `institutionalContent` — usa o default de
/// `ClubConfig` (`const ClubInstitutionalContent()`, tudo vazio). Existe só
/// pra provar que "sem conteúdo" nunca herda o do Goiás por omissão, sem
/// depender de nenhum dos clubes reais do registry.
const _emptyContentConfig = ClubConfig(
  identity: ClubIdentity(
    code: 'synthetic-empty',
    slug: 'synthetic-empty',
    displayName: 'Clube Sintético Vazio',
    shortName: 'Sintético',
    fanDemonym: 'Sintético',
    canonicalClubId: '00000000-0000-0000-0000-000000000000',
  ),
  branding: ClubBranding(light: AppColors.light, dark: AppColors.dark),
  assets: ClubAssets(
    crest: 'lib/assets/branding/goias_crest.svg',
    crestBadge: 'lib/assets/branding/goias_crest_badge.png',
    crest3d: 'lib/assets/branding/goias_crest_3d.jpg',
    loginBackground: 'lib/assets/branding/background_login.png',
    stadium: 'lib/assets/branding/stadium.jpg',
    matchHero: 'lib/assets/branding/match_hero.jpg',
    tacticsBoardIllustration: 'lib/assets/branding/tactics_board.png',
    arenaStadiumIcon: 'lib/assets/branding/arena_stadium_icon.svg',
    arenaStadiumPhoto: 'lib/assets/branding/arena_stadium_photo.jpg',
    storeBanner: 'lib/assets/branding/store_banner.jpg',
  ),
  integrations: ClubIntegrations(
    oneFootballTeamId: 0,
    oneFootballSlug: 'synthetic',
    oneFootballCompetitionSlug: 'synthetic',
    workerBaseUrl: null,
    supabaseUrl: 'https://synthetic.supabase.co',
    supabasePublishableKey: 'synthetic',
    supabaseRedirectUrl: 'https://synthetic.invalid',
    orderPrefix: 'SYN',
    pickupAddress: ClubPickupAddress(
      storeName: '—',
      street: '—',
      neighborhood: '—',
      city: '—',
      state: '—',
      zipCode: '—',
    ),
    contactWhatsappNumber: null,
    contactWhatsappUrl: null,
    socialInstagramUrl: null,
    socialYoutubeUrl: null,
    socialTiktokUrl: null,
    socialFacebookUrl: null,
    socialXUrl: null,
    officialSiteUrl: null,
  ),
  capabilities: ClubCapabilities(
    hasMembership: false,
    hasStore: false,
    hasTickets: false,
    hasCrowdLineup: false,
    hasPassport: false,
    hasNews: false,
    hasSocial: false,
    hasClubContent: true,
    hasPartners: true,
    hasMatches: false,
    enabledArenaGames: {},
    storeCommerceMode: CommerceMode.demo,
    ticketCommerceMode: CommerceMode.demo,
    membershipCommerceMode: CommerceMode.demo,
  ),
  productNames: ClubProductNaming(
    arenaName: 'Arena',
    passportName: 'Passaporte',
    storeName: 'Loja',
    membershipProgramName: 'Sócio',
  ),
  passportContent: syntheticPassportContent,
  // Nenhum `institutionalContent:` passado — usa o default vazio de
  // `ClubConfig`, de propósito.
);

void main() {
  group('Cada clube resolve o PRÓPRIO institutionalContent', () {
    test('Goiás: aponta pras classes estáticas reais do Goiás', () {
      final content = goiasClubConfig.institutionalContent;
      expect(content.history, same(ClubHistoryData.sections));
      expect(content.timeline, same(ClubTimelineData.events));
      expect(content.titles, same(ClubTitlesData.groups));
      expect(
        content.historicalCampaigns,
        same(ClubTitlesData.historicalCampaigns),
      );
      expect(content.songs, same(ClubSongsData.songs));
      expect(content.partners, same(PartnersData.all));
    });

    test('Bragantino: aponta pras classes estáticas reais do Bragantino', () {
      final content = bragantinoClubConfig.institutionalContent;
      expect(content.history, same(BragantinoHistoryData.sections));
      expect(content.timeline, same(BragantinoTimelineData.events));
      expect(content.titles, same(BragantinoTitlesData.groups));
      expect(
        content.historicalCampaigns,
        same(BragantinoTitlesData.historicalCampaigns),
      );
      expect(content.songs, same(BragantinoSongsData.songs));
      expect(content.partners, same(BragantinoPartnersData.all));
    });

    test(
      'conteúdo do Bragantino é genuinamente diferente do Goiás, nunca o mesmo dado',
      () {
        expect(
          bragantinoClubConfig.institutionalContent.history,
          isNot(same(goiasClubConfig.institutionalContent.history)),
        );
        expect(
          bragantinoClubConfig.institutionalContent.titles,
          isNot(equals(goiasClubConfig.institutionalContent.titles)),
        );
        expect(
          bragantinoClubConfig.institutionalContent.partners,
          isNot(equals(goiasClubConfig.institutionalContent.partners)),
        );
      },
    );

    test(
      'clube sem institutionalContent configurado fica com TUDO vazio — '
      'nunca herda o conteúdo do Goiás por omissão (default de ClubConfig)',
      () {
        final content = _emptyContentConfig.institutionalContent;
        expect(content.history, isEmpty);
        expect(content.timeline, isEmpty);
        expect(content.titles, isEmpty);
        expect(content.historicalCampaigns, isEmpty);
        expect(content.songs, isEmpty);
        expect(content.partners, isEmpty);
      },
    );
  });

  group('Títulos sem imagem funcionam — o modelo nunca exige foto', () {
    test(
      'todo título do Bragantino tem images vazio, e count continua > 0',
      () {
        for (final group in BragantinoTitlesData.groups) {
          expect(
            group.images,
            isEmpty,
            reason: '${group.competitionName} não deveria ter imagem ainda',
          );
          expect(group.count, greaterThan(0));
        }
      },
    );

    testWidgets(
      'ClubTitlesPage do Bragantino renderiza título sem quebrar, sem carrossel',
      (tester) async {
        await sl.reset();
        sl.registerSingleton<ClubConfig>(bragantinoClubConfig);
        addTearDown(sl.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ClubTitlesPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('CAMPEONATO BRASILEIRO SÉRIE B'), findsOneWidget);
        // Nenhum carrossel de imagem — nenhum `PageView`/`Image` de título
        // renderizado (a página só desenha o card de texto).
        expect(find.byType(PageView), findsNothing);
      },
    );
  });

  test(
    'campanhas históricas (vice/estreia) NUNCA contam como título — '
    'nenhum ano de 1991/2021/2022 aparece em BragantinoTitlesData.groups',
    () {
      final titleYears = BragantinoTitlesData.groups.expand((g) => g.years);
      for (final campaign in BragantinoTitlesData.historicalCampaigns) {
        expect(
          titleYears,
          isNot(contains(campaign.year)),
          reason:
              '${campaign.title} (${campaign.year}) é campanha histórica, '
              'não título — não pode aparecer em nenhum ClubTitleGroup',
        );
      }
      final totalTitles = BragantinoTitlesData.groups.fold<int>(
        0,
        (sum, g) => sum + g.count,
      );
      // 2 (Série B) + 1 (Série C) + 1 (Paulista) + 2 (Paulista A2) + 1
      // (Segunda Divisão) + 1 (Paulista do Interior) = 8 — bate exatamente
      // com groups, nunca soma as 3 campanhas históricas junto.
      expect(totalTitles, 8);
    },
  );

  group('Páginas institucionais usam o clube ATIVO (via sl<ClubConfig>)', () {
    setUp(() async {
      await sl.reset();
    });
    tearDown(() => sl.reset());

    testWidgets('ClubHistoryPage do Bragantino mostra história do Bragantino', (
      tester,
    ) async {
      sl.registerSingleton<ClubConfig>(bragantinoClubConfig);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ClubHistoryPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Clube Atlético Bragantino'), findsWidgets);
      expect(find.textContaining('Goiás'), findsNothing);
    });

    testWidgets('ClubSongsPage do Bragantino mostra o hino do Bragantino', (
      tester,
    ) async {
      sl.registerSingleton<ClubConfig>(bragantinoClubConfig);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ClubSongsPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Massa Bruta Campeão'), findsOneWidget);
      expect(find.textContaining('Goiás'), findsNothing);
    });

    testWidgets(
      'PartnersPage do Bragantino mostra os parceiros do Bragantino',
      (tester) async {
        sl.registerSingleton<ClubConfig>(bragantinoClubConfig);
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PartnersPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Puma'), findsOneWidget);
        expect(find.text('Asaas'), findsOneWidget);
        // "Unimed" é uma marca nacional com unidades regionais
        // independentes — o Bragantino tem a sua PRÓPRIA (Os
        // Bandeirantes, Bragança Paulista), sem nenhuma relação com a
        // Unimed Goianiense do Goiás. Coincidência de nome, não
        // vazamento de dado — único nome que se repete de propósito
        // nesta checagem.
        for (final goiasPartner in PartnersData.all) {
          if (goiasPartner.name == 'Unimed') continue;
          expect(find.text(goiasPartner.name), findsNothing);
        }
        // Regressão 2026-09-07: o subtítulo da página era um l10n global
        // hardcoded ("Brands that walk alongside Goiás."), nunca checado
        // aqui porque o teste só olhava os NOMES dos parceiros, não o
        // texto ao redor.
        expect(find.textContaining('Goiás', skipOffstage: false), findsNothing);
        expect(
          find.textContaining('Verdão', skipOffstage: false),
          findsNothing,
        );
        expect(find.textContaining('Bragantino'), findsWidgets);
      },
    );
  });

  test('FABRICADO — nenhuma string de identidade do Goiás aparece em nenhum '
      'campo textual do institutionalContent do Bragantino', () {
    const forbidden = ['Goiás', 'Esmeraldino', 'Verdão', 'Serrinha'];
    final content = bragantinoClubConfig.institutionalContent;
    final texts = <String>[
      for (final s in content.history) ...[s.period, s.title, ...s.paragraphs],
      for (final e in content.timeline) e.title,
      for (final g in content.titles) g.competitionName,
      for (final c in content.historicalCampaigns) c.title,
      for (final s in content.songs) s.title,
      for (final p in content.partners) p.name,
      for (final i in content.idols) ...[i.name, i.description],
    ];
    for (final text in texts) {
      for (final leaked in forbidden) {
        expect(
          text.toLowerCase(),
          isNot(contains(leaked.toLowerCase())),
          reason: '"$text" contém identidade do Goiás ("$leaked")',
        );
      }
    }
  });

  test('FABRICADO — categoria de música nunca mais leva o nome "esmeraldina" '
      '(era um vazamento de nomenclatura do Goiás no enum compartilhado)', () {
    expect(
      ClubSongCategory.values.map((v) => v.name),
      isNot(contains('esmeraldina')),
    );
  });

  group('Ídolos do Bragantino — semântica de evidência preservada', () {
    test(
      'Goiás não tem ídolos (feature nunca existiu pra ele — sem regressão)',
      () {
        expect(goiasClubConfig.institutionalContent.idols, isEmpty);
      },
    );

    test('Lincom: estatística RESOLVIDA em 2026-09-07 — 160 jogos/72 gols como '
        'contador principal, 73 preservado só como nota de auditoria', () {
      final lincom = bragantinoClubConfig.institutionalContent.idols.firstWhere(
        (i) => i.name == 'Lincom',
      );
      expect(lincom.evidenceExplicitIdol, isTrue);
      expect(lincom.description, contains('160 jogos'));
      expect(lincom.description, contains('72 gols'));
      expect(
        lincom.description,
        contains('73'),
        reason:
            'a divergência de 73 gols precisa continuar preservada como '
            'nota de auditoria, nunca apagada silenciosamente',
      );
    });

    test('nomes sem evidência explícita nunca usam a formulação forte de '
        '"ídolo" na descrição — só destaque/geração histórica', () {
      final idols = bragantinoClubConfig.institutionalContent.idols;
      for (final idol in idols.where((i) => !i.evidenceExplicitIdol)) {
        expect(
          idol.description.toLowerCase(),
          isNot(contains('ídolo')),
          reason:
              '"${idol.name}" não tem evidência explícita de ídolo, mas a '
              'descrição usa a palavra: "${idol.description}"',
        );
      }
    });

    test('tier 1 tem exatamente os 14 nomes fortes do levantamento '
        '(8 originais + 7 promovidos em 2026-09-07 - "Marcelo" removido em '
        '2026-09-09, nunca substituídos)', () {
      final tier1Names = bragantinoClubConfig.institutionalContent.idols
          .where((i) => i.tier == 1)
          .map((i) => i.name)
          .toSet();
      expect(tier1Names, {
        'Mauro Silva',
        'Lincom',
        'Léo Jaime',
        'Cleiton',
        'Gil Baiano',
        'Mazinho',
        'Luís Müller',
        'Biro-Biro',
        'Ivair',
        'Ytalo',
        'Claudinho',
        'Artur',
        'Léo Ortiz',
        'Aderlan',
      });
    });

    test('25 nomes ao todo (14 tier 1 + 5 tier 2 + 6 tier 3)', () {
      final idols = bragantinoClubConfig.institutionalContent.idols;
      expect(idols.length, 25);
      expect(idols.where((i) => i.tier == 1).length, 14);
      expect(idols.where((i) => i.tier == 2).length, 5);
      expect(idols.where((i) => i.tier == 3).length, 6);
    });
  });
}
