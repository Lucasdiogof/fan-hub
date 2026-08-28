import 'package:flutter/widgets.dart';
import 'package:goias_app/features/passport/passport_ui_variant.dart';
import 'package:goias_app/features/passport/presentation/v1/pages/passport_ranking_page_v1.dart';
import 'package:goias_app/features/passport/presentation/v2/pages/passport_ranking_page_v2.dart';

/// Só escolhe a versão visual — ver [PassportUiConfig].
class PassportRankingPage extends StatelessWidget {
  const PassportRankingPage({super.key});

  @override
  Widget build(BuildContext context) => switch (PassportUiConfig.current) {
    PassportUiVariant.v1 => const PassportRankingPageV1(),
    PassportUiVariant.v2 => const PassportRankingPageV2(),
  };
}
