import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/crowd_lineup/domain/crowd_lineup.dart';
import 'package:goias_app/features/crowd_lineup/domain/formation.dart';
import 'package:goias_app/features/crowd_lineup/domain/goias_squad.dart';
import 'package:goias_app/features/crowd_lineup/domain/lineup_vote.dart';
import 'package:goias_app/features/crowd_lineup/domain/repositories/crowd_lineup_repository.dart';
import 'package:goias_app/features/crowd_lineup/presentation/cubit/crowd_lineup_cubit.dart';
import 'package:goias_app/features/crowd_lineup/presentation/pages/crowd_lineup_page.dart';
import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/features/match/domain/entities/team.dart';

const _match = Match(
  id: 'm-1',
  competition: 'Brasileirão Série B',
  round: '',
  homeTeam: Team(
    id: 1863,
    name: 'Goiás',
    shortName: 'GOI',
    color: Colors.green,
  ),
  awayTeam: Team(
    id: 2,
    name: 'Adversário',
    shortName: 'ADV',
    color: Colors.red,
  ),
  stadium: '',
  status: MatchStatus.scheduled,
);

/// Dublê em memória — implementa a interface direto, sem precisar de um
/// SupabaseClient de mentira (diferente de `SupabaseLineupStorage`, essa
/// aqui já é `abstract interface class`).
class _FakeCrowdLineupRepository implements CrowdLineupRepository {
  CrowdLineup crowd = const CrowdLineup.empty();
  LineupVote? myVote;

  @override
  Future<Result<LineupVote?>> getMyVote(String matchId) async =>
      Success(myVote);

  @override
  Future<Result<CrowdLineup>> getCrowdLineup(String matchId) async =>
      Success(crowd);

  @override
  Future<Result<void>> submitVote(String matchId, LineupVote vote) async =>
      const Success(null);
}

CrowdLineup _crowdWithVotes() {
  final formation = formationById('4-3-3');
  return CrowdLineup(totalVotes: 5, topFormation: formation, slots: const []);
}

Future<CrowdLineupCubit> _pump(
  WidgetTester tester, {
  required _FakeCrowdLineupRepository repository,
  bool votingOpen = true,
}) async {
  final cubit = CrowdLineupCubit(
    repository: repository,
    matchId: _match.id,
    votingOpen: votingOpen,
  );
  await cubit.load();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      theme: AppTheme.light,
      home: CrowdLineupPage(match: _match, cubit: cubit),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ClubConfig>(goiasClubConfig);
  });

  testWidgets(
    'share button is hidden on "Escalação da torcida" when nobody has voted yet',
    (tester) async {
      await _pump(tester, repository: _FakeCrowdLineupRepository());
      // Sem voto próprio, a aba inicial é "Escale" — navega explicitamente.
      await tester.tap(
        find.descendant(
          of: find.byType(TabBar),
          matching: find.text('ESCALAÇÃO DA TORCIDA'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsNothing);
    },
  );

  testWidgets(
    'share button appears on "Escalação da torcida" once there are votes',
    (tester) async {
      final repository = _FakeCrowdLineupRepository()
        ..crowd = _crowdWithVotes();
      await _pump(tester, repository: repository);
      await tester.tap(
        find.descendant(
          of: find.byType(TabBar),
          matching: find.text('ESCALAÇÃO DA TORCIDA'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    },
  );

  testWidgets(
    'switching to "Escale" with nothing filled in hides the share button',
    (tester) async {
      final repository = _FakeCrowdLineupRepository()
        ..crowd = _crowdWithVotes();
      await _pump(tester, repository: repository);
      await tester.tap(
        find.descendant(
          of: find.byType(TabBar),
          matching: find.text('ESCALAÇÃO DA TORCIDA'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);

      await tester.tap(
        find.descendant(of: find.byType(TabBar), matching: find.text('ESCALE')),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsNothing);
    },
  );

  testWidgets(
    'switching to "Escale" after picking a player shows the share button',
    (tester) async {
      final repository = _FakeCrowdLineupRepository();
      final cubit = await _pump(
        tester,
        repository: repository,
        votingOpen: true,
      );

      await tester.tap(
        find.descendant(of: find.byType(TabBar), matching: find.text('ESCALE')),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.share_rounded), findsNothing);

      final anyPlayerId = squadById.keys.first;
      cubit.selectPlayer(0, anyPlayerId);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    },
  );
}
