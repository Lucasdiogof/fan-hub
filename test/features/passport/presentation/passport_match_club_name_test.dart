// REGRESSÃO 2026-09-09 — achado real reportado pelo usuário: o seletor de
// "jogo mais memorável" mostrava "Goiás x <adversário>" MESMO no flavor
// Bragantino (o dado da partida já era isolado por projeto Supabase — o
// bug era só o texto, cravado, nunca lido de `ClubConfig`). O mesmo
// literal existia em mais 3 lugares (`passport_trajectory_page.dart`,
// `passport_match_row_v1.dart`, `passport_match_ticket_v2.dart`), todos
// corrigidos juntos — este teste trava só o mais visível (o picker), mas
// serve de sentinela pro padrão inteiro.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/bragantino_club_config.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/passport/domain/entities/passport_match.dart';
import 'package:goias_app/features/passport/presentation/widgets/passport_memorable_match_picker.dart';
import 'package:goias_app/l10n/app_localizations.dart';

PassportMatch _match() => PassportMatch(
  id: 'm1',
  season: 2026,
  matchDate: DateTime(2026, 6, 1),
  status: PassportMatchStatus.finished,
  competition: 'Brasileirão',
  competitionCode: 'BR',
  opponent: 'Adversário Teste',
  attended: true,
);

void main() {
  tearDown(() => sl.reset());

  for (final (clubName, config) in [
    ('Goiás', goiasClubConfig),
    ('Bragantino', bragantinoClubConfig),
  ]) {
    testWidgets(
      '$clubName: o rótulo do jogo usa o nome do clube ATIVO, nunca "Goiás" cravado',
      (tester) async {
        await sl.reset();
        sl.registerSingleton<ClubConfig>(config);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showMemorableMatchPicker(
                  context,
                  matches: [_match()],
                  selectedMatchId: null,
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();

        final expectedLabel = '${config.identity.shortName} x Adversário Teste';
        expect(find.text(expectedLabel), findsOneWidget);
        if (config.identity.code != 'goias') {
          expect(find.textContaining('Goiás'), findsNothing);
        }
      },
    );
  }
}
