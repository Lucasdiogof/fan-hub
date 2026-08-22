import 'package:flutter/material.dart';
import 'package:goias_app/core/theme/app_colors.dart';

enum PenaltyResult { goal, save, out, post }

extension PenaltyResultLabel on PenaltyResult {
  String get label => switch (this) {
    PenaltyResult.goal => 'GOL!',
    PenaltyResult.save => 'DEFESA!',
    PenaltyResult.out => 'PRA FORA!',
    PenaltyResult.post => 'NA TRAVE!',
  };

  /// Rótulo curto pro histórico de cobranças do resultado final — sem o
  /// ponto de exclamação do flash de HUD.
  String get shortLabel => switch (this) {
    PenaltyResult.goal => 'Gol',
    PenaltyResult.save => 'Defesa',
    PenaltyResult.out => 'Fora',
    PenaltyResult.post => 'Trave',
  };

  IconData get icon => switch (this) {
    PenaltyResult.goal => Icons.check_rounded,
    PenaltyResult.save => Icons.front_hand_rounded,
    PenaltyResult.out => Icons.close_rounded,
    PenaltyResult.post => Icons.crop_din_rounded,
  };

  Color colorFor(AppColors colors) => switch (this) {
    PenaltyResult.goal => colors.success,
    PenaltyResult.save => colors.error,
    PenaltyResult.out => colors.textHint,
    PenaltyResult.post => colors.gold,
  };

  bool get isGoal => this == PenaltyResult.goal;
}

enum PenaltyPhase { ready, approaching, shooting, resolving, finished }

enum ShotZone { left, center, right }
