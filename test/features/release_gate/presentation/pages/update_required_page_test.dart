import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/release/app_release_requirement.dart';
import 'package:goias_app/core/release/release_gate.dart';
import 'package:goias_app/core/release/release_requirement_repository.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/release_gate/presentation/pages/update_required_page.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _FixedRepository implements ReleaseRequirementRepository {
  _FixedRepository(this._requirement);

  final AppReleaseRequirement _requirement;

  @override
  Future<Result<AppReleaseRequirement?>> getRequirement({
    required String platform,
  }) async => Success(_requirement);
}

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

void main() {
  setUp(() async {
    await sl.reset();
    PackageInfo.setMockInitialValues(
      appName: 'goias_app',
      packageName: 'br.com.goiasec.goias_app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets(
    'sem store_url configurado -> mostra o aviso sem botão de ação',
    (tester) async {
      final gate = ReleaseGate(
        _FixedRepository(
          const AppReleaseRequirement(
            platform: 'android',
            minimumVersion: '2.0.0',
            minimumBuild: 5,
            forceUpdate: true,
          ),
        ),
      );
      await gate.ensureChecked();
      sl.registerSingleton<ReleaseGate>(gate);

      await tester.pumpWidget(_wrap(const UpdateRequiredPage()));

      expect(find.text('Atualização necessária'), findsOneWidget);
      expect(find.byIcon(Icons.system_update_rounded), findsOneWidget);
      expect(find.text('Atualizar agora'), findsNothing);
    },
  );

  testWidgets(
    'com store_url configurado -> mostra o botão "Atualizar agora"',
    (tester) async {
      final gate = ReleaseGate(
        _FixedRepository(
          const AppReleaseRequirement(
            platform: 'android',
            minimumVersion: '2.0.0',
            minimumBuild: 5,
            forceUpdate: true,
            storeUrl: 'https://play.google.com/store/apps/details?id=x',
          ),
        ),
      );
      await gate.ensureChecked();
      sl.registerSingleton<ReleaseGate>(gate);

      await tester.pumpWidget(_wrap(const UpdateRequiredPage()));

      expect(find.text('Atualizar agora'), findsOneWidget);
    },
  );

  testWidgets(
    'mensagem do servidor sobrepõe a mensagem padrão quando presente',
    (tester) async {
      final gate = ReleaseGate(
        _FixedRepository(
          const AppReleaseRequirement(
            platform: 'android',
            minimumVersion: '2.0.0',
            minimumBuild: 5,
            forceUpdate: true,
            message: 'Mensagem customizada do servidor.',
          ),
        ),
      );
      await gate.ensureChecked();
      sl.registerSingleton<ReleaseGate>(gate);

      await tester.pumpWidget(_wrap(const UpdateRequiredPage()));

      expect(find.text('Mensagem customizada do servidor.'), findsOneWidget);
    },
  );

  testWidgets('nunca pode ser descartada via back gesture (PopScope)', (
    tester,
  ) async {
    final gate = ReleaseGate(
      _FixedRepository(
        const AppReleaseRequirement(
          platform: 'android',
          minimumVersion: '2.0.0',
          minimumBuild: 5,
          forceUpdate: true,
        ),
      ),
    );
    await gate.ensureChecked();
    sl.registerSingleton<ReleaseGate>(gate);

    await tester.pumpWidget(_wrap(const UpdateRequiredPage()));

    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isFalse);
  });
}
