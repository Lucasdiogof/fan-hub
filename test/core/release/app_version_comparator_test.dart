import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/core/release/app_version_comparator.dart';

void main() {
  group('compareSemanticVersions — numérico, nunca lexical', () {
    test('1.10.0 > 1.9.0 — uma comparação de string erraria isso', () {
      expect(compareSemanticVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareSemanticVersions('1.9.0', '1.10.0'), lessThan(0));
    });

    test('2.0.0 > 1.99.99 (major decide antes de minor/patch)', () {
      expect(compareSemanticVersions('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('mesma versão -> 0', () {
      expect(compareSemanticVersions('1.2.3', '1.2.3'), 0);
    });

    test('ignora sufixo de build (+N) e pre-release (-...)', () {
      expect(compareSemanticVersions('1.2.3+45', '1.2.3'), 0);
      expect(compareSemanticVersions('1.2.3-beta', '1.2.3'), 0);
    });

    test('segmentos ausentes contam como 0 ("1.2" == "1.2.0")', () {
      expect(compareSemanticVersions('1.2', '1.2.0'), 0);
    });

    test('segmento não numérico conta como 0, nunca lança', () {
      expect(() => compareSemanticVersions('1.x.0', '1.0.0'), returnsNormally);
      expect(compareSemanticVersions('1.x.0', '1.0.0'), 0);
    });
  });

  group('isBelowMinimumRelease — build number é a comparação primária', () {
    test('build atual abaixo do mínimo -> true, mesmo com semver igual', () {
      expect(
        isBelowMinimumRelease(
          currentBuild: 3,
          currentVersion: '1.0.0',
          minimumBuild: 5,
          minimumVersion: '1.0.0',
        ),
        isTrue,
      );
    });

    test('build atual igual ou acima do mínimo -> false', () {
      expect(
        isBelowMinimumRelease(
          currentBuild: 5,
          currentVersion: '1.0.0',
          minimumBuild: 5,
          minimumVersion: '1.0.0',
        ),
        isFalse,
      );
      expect(
        isBelowMinimumRelease(
          currentBuild: 6,
          currentVersion: '1.0.0',
          minimumBuild: 5,
          minimumVersion: '1.0.0',
        ),
        isFalse,
      );
    });

    test(
      'cai pro semver quando build vem zerado/ausente de qualquer lado',
      () {
        expect(
          isBelowMinimumRelease(
            currentBuild: 0,
            currentVersion: '1.9.0',
            minimumBuild: 5,
            minimumVersion: '1.10.0',
          ),
          isTrue,
        );
        expect(
          isBelowMinimumRelease(
            currentBuild: 5,
            currentVersion: '1.10.0',
            minimumBuild: 0,
            minimumVersion: '1.9.0',
          ),
          isFalse,
        );
      },
    );
  });
}
