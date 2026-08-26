import 'package:goias_app/features/match/domain/entities/match.dart';
import 'package:goias_app/l10n/app_localizations.dart';

String matchStatusLabel(AppLocalizations l10n, MatchStatus status) =>
    switch (status) {
      MatchStatus.scheduled => l10n.matchStatusScheduled,
      MatchStatus.live => l10n.matchStatusLive,
      MatchStatus.halftime => l10n.matchStatusHalfTime,
      MatchStatus.finished => l10n.matchStatusFinished,
      MatchStatus.postponed => l10n.matchStatusPostponed,
      MatchStatus.cancelled => l10n.matchStatusCancelled,
      MatchStatus.suspended => l10n.matchStatusSuspended,
      MatchStatus.unknown => l10n.matchStatusUnknown,
    };
