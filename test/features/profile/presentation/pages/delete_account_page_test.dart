import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/l10n/app_localizations.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/theme/app_theme.dart';
import 'package:goias_app/features/auth/domain/entities/auth_user.dart';
import 'package:goias_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:goias_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:goias_app/features/profile/presentation/pages/delete_account_page.dart';

const _user = AuthUser(id: 'u-1', email: 'torcedor@example.com');

class _FakeAuthRepository implements AuthRepository {
  Failure? deleteFailure;
  int deleteCalls = 0;
  String? lastPassword;

  @override
  bool get isAuthenticated => true;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthSessionEvent> get sessionEvents => const Stream.empty();

  @override
  Future<Result<void>> deleteAccount({required String password}) async {
    deleteCalls++;
    lastPassword = password;
    if (deleteFailure != null) return Error(deleteFailure!);
    return const Success(null);
  }

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
  }) async => const Success(false);

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
}

Widget _wrap(AuthCubit cubit) {
  return MaterialApp(
      locale: const Locale('pt'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

    theme: AppTheme.light,
    home: BlocProvider.value(value: cubit, child: const DeleteAccountPage()),
  );
}

Finder _submitButton() => find.text('EXCLUIR MINHA CONTA');

Future<void> _enterPassword(WidgetTester tester, String value) async {
  await tester.enterText(find.byType(TextField).first, value);
  await tester.pump();
}

Future<void> _enterConfirmationWord(WidgetTester tester, String value) async {
  await tester.enterText(find.byType(TextField).last, value);
  await tester.pump();
}

bool _isSubmitEnabled(WidgetTester tester) {
  final button = tester.widget<Opacity>(
    find.ancestor(of: _submitButton(), matching: find.byType(Opacity)).first,
  );
  return button.opacity == 1;
}

void main() {
  group('DeleteAccountPage', () {
    testWidgets('button stays disabled with empty fields', (tester) async {
      final cubit = AuthCubit(_FakeAuthRepository());
      await tester.pumpWidget(_wrap(cubit));

      expect(_isSubmitEnabled(tester), isFalse);
      await cubit.close();
    });

    testWidgets('button stays disabled when the confirmation word is wrong', (
      tester,
    ) async {
      final cubit = AuthCubit(_FakeAuthRepository());
      await tester.pumpWidget(_wrap(cubit));

      await _enterPassword(tester, 'minhasenha');
      await _enterConfirmationWord(tester, 'exclur');

      expect(_isSubmitEnabled(tester), isFalse);
      await cubit.close();
    });

    testWidgets(
      'button enables once the password is set and EXCLUIR is typed, case/whitespace-insensitive',
      (tester) async {
        final cubit = AuthCubit(_FakeAuthRepository());
        await tester.pumpWidget(_wrap(cubit));

        await _enterPassword(tester, 'minhasenha');
        await _enterConfirmationWord(tester, '  excluir  ');

        expect(_isSubmitEnabled(tester), isTrue);
        await cubit.close();
      },
    );

    testWidgets('success calls the repository once with the typed password', (
      tester,
    ) async {
      final repository = _FakeAuthRepository();
      final cubit = AuthCubit(repository);
      await tester.pumpWidget(_wrap(cubit));

      await _enterPassword(tester, 'minhasenha');
      await _enterConfirmationWord(tester, 'EXCLUIR');
      await tester.tap(_submitButton());
      await tester.pump();
      await tester.pump();

      expect(repository.deleteCalls, 1);
      expect(repository.lastPassword, 'minhasenha');
      await cubit.close();
    });

    testWidgets('backend failure shows the error and keeps the button usable', (
      tester,
    ) async {
      final repository = _FakeAuthRepository()
        ..deleteFailure = const AuthFailure(
          'Não foi possível excluir sua conta. Tente novamente em alguns instantes.',
        );
      final cubit = AuthCubit(repository);
      await tester.pumpWidget(_wrap(cubit));

      await _enterPassword(tester, 'minhasenha');
      await _enterConfirmationWord(tester, 'EXCLUIR');
      await tester.tap(_submitButton());
      await tester.pump();
      await tester.pump();

      expect(
        find.text(
          'Não foi possível excluir sua conta. Tente novamente em alguns instantes.',
        ),
        findsOneWidget,
      );
      expect(_isSubmitEnabled(tester), isTrue);
      await cubit.close();
    });

    testWidgets('double tap while loading only fires one delete call', (
      tester,
    ) async {
      final repository = _FakeAuthRepository();
      final cubit = AuthCubit(repository);
      await tester.pumpWidget(_wrap(cubit));

      await _enterPassword(tester, 'minhasenha');
      await _enterConfirmationWord(tester, 'EXCLUIR');
      // Duas tocadas antes de qualquer pump — simula o duplo toque real
      // (a segunda ainda acha o mesmo texto porque o frame com "loading"
      // não foi desenhado ainda). O guard em `_submit` é o que garante que
      // só uma chamada realmente sai, não o rebuild da UI.
      await tester.tap(_submitButton());
      await tester.tap(_submitButton());
      await tester.pump();
      await tester.pump();

      expect(repository.deleteCalls, 1);
      await cubit.close();
    });
  });
}
