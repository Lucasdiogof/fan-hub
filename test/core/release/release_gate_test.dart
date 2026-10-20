import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/error/failures.dart';
import 'package:goias_app/core/error/result.dart';
import 'package:goias_app/core/release/app_release_requirement.dart';
import 'package:goias_app/core/release/release_gate.dart';
import 'package:goias_app/core/release/release_requirement_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _FakeRepository implements ReleaseRequirementRepository {
  _FakeRepository(this._result, {this.delay});

  final Result<AppReleaseRequirement?> _result;
  final Duration? delay;

  @override
  Future<Result<AppReleaseRequirement?>> getRequirement({
    required String platform,
  }) async {
    if (delay != null) await Future<void>.delayed(delay!);
    return _result;
  }
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'goias_app',
      packageName: 'br.com.goiasec.goias_app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('ReleaseGate — política fail-safe', () {
    test('sem linha configurada (Success(null)) -> nunca bloqueia', () async {
      final gate = ReleaseGate(_FakeRepository(const Success(null)));
      await gate.ensureChecked();
      expect(gate.checked, isTrue);
      expect(gate.blocked, isFalse);
      expect(gate.requirement, isNull);
    });

    test(
      'linha existe mas force_update=false -> nunca bloqueia, mesmo abaixo do mínimo',
      () async {
        final gate = ReleaseGate(
          _FakeRepository(
            const Success(
              AppReleaseRequirement(
                platform: 'android',
                minimumVersion: '9.9.9',
                minimumBuild: 999,
                forceUpdate: false,
              ),
            ),
          ),
        );
        await gate.ensureChecked();
        expect(gate.blocked, isFalse);
      },
    );

    test(
      'force_update=true e build atual abaixo do mínimo -> bloqueia',
      () async {
        final gate = ReleaseGate(
          _FakeRepository(
            const Success(
              AppReleaseRequirement(
                platform: 'android',
                minimumVersion: '2.0.0',
                minimumBuild: 5,
                forceUpdate: true,
              ),
            ),
          ),
        );
        await gate.ensureChecked();
        expect(gate.blocked, isTrue);
        expect(gate.requirement?.minimumBuild, 5);
      },
    );

    test(
      'force_update=true mas build atual já é o mínimo -> não bloqueia',
      () async {
        final gate = ReleaseGate(
          _FakeRepository(
            const Success(
              AppReleaseRequirement(
                platform: 'android',
                minimumVersion: '1.0.0',
                minimumBuild: 1,
                forceUpdate: true,
              ),
            ),
          ),
        );
        await gate.ensureChecked();
        expect(gate.blocked, isFalse);
      },
    );

    test(
      'Error do repositório (falha de rede/servidor) -> fail-open, nunca bloqueia',
      () async {
        final gate = ReleaseGate(
          _FakeRepository(const Error(ServerFailure('fora do ar'))),
        );
        await gate.ensureChecked();
        expect(gate.checked, isTrue);
        expect(gate.blocked, isFalse);
      },
    );

    test(
      'timeout (indisponibilidade) -> fail-open, nunca bloqueia',
      () async {
        final gate = ReleaseGate(
          _FakeRepository(
            const Success(
              AppReleaseRequirement(
                platform: 'android',
                minimumVersion: '99.0.0',
                minimumBuild: 999,
                forceUpdate: true,
              ),
            ),
            delay: const Duration(seconds: 10), // > o timeout interno de 3s
          ),
        );
        await gate.ensureChecked();
        expect(gate.checked, isTrue);
        expect(gate.blocked, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test('idempotente — a 2ª chamada não refaz a checagem', () async {
      var calls = 0;
      final gate = ReleaseGate(_CountingRepository(() => calls++));
      await gate.ensureChecked();
      await gate.ensureChecked();
      expect(calls, 1);
    });

    test('notifica listeners exatamente uma vez após checar', () async {
      final gate = ReleaseGate(_FakeRepository(const Success(null)));
      var notifications = 0;
      gate.addListener(() => notifications++);
      await gate.ensureChecked();
      expect(notifications, 1);
    });

    test(
      'release M3.4 real (app 1.0.1+2) contra a config publicada (mínimo 1.0.0/build 1, force_update=false) -> nunca bloqueia',
      () async {
        PackageInfo.setMockInitialValues(
          appName: 'goias_app',
          packageName: 'br.com.goiasec.goias_app',
          version: '1.0.1',
          buildNumber: '2',
          buildSignature: '',
        );
        final gate = ReleaseGate(
          _FakeRepository(
            const Success(
              AppReleaseRequirement(
                platform: 'web',
                minimumVersion: '1.0.0',
                minimumBuild: 1,
                forceUpdate: false,
              ),
            ),
          ),
        );
        await gate.ensureChecked();
        expect(gate.blocked, isFalse);
      },
    );
  });
}

class _CountingRepository implements ReleaseRequirementRepository {
  _CountingRepository(this._onCall);

  final void Function() _onCall;

  @override
  Future<Result<AppReleaseRequirement?>> getRequirement({
    required String platform,
  }) async {
    _onCall();
    return const Success(null);
  }
}
