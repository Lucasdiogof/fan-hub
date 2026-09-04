import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/club/club_config.dart';
import 'package:goias_app/core/club/goias_club_config.dart';
import 'package:goias_app/core/di/injection_container.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/home/presentation/widgets/home_brand_header.dart';
import 'package:goias_app/l10n/app_localizations.dart';

import '../../../../core/club/synthetic_club_config.dart';
import '../../../../support/fake_asset_bundle.dart';

/// Sem usuário logado — só isso importa aqui: `HomeBrandHeader` cai no
/// título/escudo do `ClubConfig` ativo, nunca num literal do Goiás.
class _FakeUnauthenticatedRepository implements AuthRepository {
  @override
  bool get isAuthenticated => false;

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthSessionEvent> get sessionEvents => const Stream.empty();

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async => const Success(null);

  @override
  Future<Result<bool>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
    required String phone,
    required bool marketingOptIn,
  }) async => const Success(false);

  @override
  Future<Result<void>> verifyEmailOtp({
    required String email,
    required String token,
  }) async => const Success(null);

  @override
  Future<Result<bool>> isCpfTaken(String cpf) async => const Success(false);

  @override
  Future<Result<void>> signOut() async => const Success(null);

  @override
  Future<Result<void>> sendPasswordReset(String email) async =>
      const Success(null);

  @override
  Future<Result<void>> resendConfirmationEmail(String email) async =>
      const Success(null);

  @override
  Future<Result<void>> updatePassword(String newPassword) async =>
      const Success(null);

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => const Success(null);

  @override
  Future<Result<void>> deleteAccount({required String password}) async =>
      const Success(null);
}

Widget _wrap() {
  return DefaultAssetBundle(
    bundle: FakeAssetBundle(),
    child: MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: BlocProvider(
        create: (_) => AuthCubit(_FakeUnauthenticatedRepository()),
        child: const Scaffold(body: HomeBrandHeader()),
      ),
    ),
  );
}

String _assetNameOf(WidgetTester tester) {
  final image = tester.widget<Image>(find.byType(Image));
  return (image.image as AssetImage).assetName;
}

void main() {
  setUp(() async {
    await sl.reset();
  });

  group('Goiás — usa o próprio ClubConfig (comportamento inalterado)', () {
    setUp(() => sl.registerSingleton<ClubConfig>(goiasClubConfig));

    testWidgets('mostra o crestBadge e o displayName do Goiás', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(_assetNameOf(tester), goiasClubConfig.assets.crestBadge);
      expect(find.text('GOIÁS ESPORTE CLUBE'), findsOneWidget);
    });
  });

  group('Clube sintético (Bragantino-like) — nunca mostra nada do Goiás', () {
    setUp(() => sl.registerSingleton<ClubConfig>(syntheticClubBConfig));

    testWidgets('mostra o crestBadge e o displayName do clube ativo', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(_assetNameOf(tester), syntheticClubBConfig.assets.crestBadge);
      expect(find.text('CLUBE SINTÉTICO B'), findsOneWidget);
    });

    testWidgets('NUNCA referencia o crest ou o nome do Goiás', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(_assetNameOf(tester), isNot(goiasClubConfig.assets.crestBadge));
      expect(find.text('GOIÁS ESPORTE CLUBE'), findsNothing);
    });
  });
}
