import 'package:goias_app/features/arena/games/penalty/penalty_models.dart';
import 'package:goias_app/l10n/app_localizations.dart';

String penaltyResultLabel(AppLocalizations l10n, PenaltyResult result) =>
    switch (result) {
      PenaltyResult.goal => l10n.penaltyResultGoal,
      PenaltyResult.save => l10n.penaltyResultSave,
      PenaltyResult.out => l10n.penaltyResultOut,
      PenaltyResult.post => l10n.penaltyResultPost,
    };

String penaltyResultShortLabel(AppLocalizations l10n, PenaltyResult result) =>
    switch (result) {
      PenaltyResult.goal => l10n.penaltyResultGoalShort,
      PenaltyResult.save => l10n.penaltyResultSaveShort,
      PenaltyResult.out => l10n.penaltyResultOutShort,
      PenaltyResult.post => l10n.penaltyResultPostShort,
    };
