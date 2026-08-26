import 'package:flutter/material.dart';
import 'package:goias_app/core/l10n/l10n_extensions.dart';
import 'package:goias_app/shared/widgets/page_title.dart';

class GamesHeader extends StatelessWidget {
  const GamesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return PageTitle(context.l10n.matchGamesTitle);
  }
}
