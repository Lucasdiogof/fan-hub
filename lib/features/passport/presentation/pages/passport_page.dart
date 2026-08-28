import 'package:flutter/widgets.dart';
import 'package:goias_app/features/passport/passport_ui_variant.dart';
import 'package:goias_app/features/passport/presentation/v1/pages/passport_page_v1.dart';
import 'package:goias_app/features/passport/presentation/v2/pages/passport_page_v2.dart';

/// Só escolhe a versão visual — ver [PassportUiConfig].
class PassportPage extends StatelessWidget {
  const PassportPage({super.key});

  @override
  Widget build(BuildContext context) => switch (PassportUiConfig.current) {
    PassportUiVariant.v1 => const PassportPageV1(),
    PassportUiVariant.v2 => const PassportPageV2(),
  };
}
