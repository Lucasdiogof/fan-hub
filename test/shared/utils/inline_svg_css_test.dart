import 'package:flutter_test/flutter_test.dart';
import 'package:goias_app/shared/utils/inline_svg_css.dart';

void main() {
  group('inlineSvgCssClasses', () {
    test('replaces class="stN" with inline style from the <style> block', () {
      const svg = '''
<svg viewBox="0 0 590 590">
<style type="text/css">
	.st0{fill:#26603C;}
	.st1{fill:#FBFCFC;}
</style>
<path class="st0" d="M0,0" />
<path class="st1" d="M1,1" />
</svg>
''';

      final result = inlineSvgCssClasses(svg);

      expect(result, contains('style="fill:#26603C;"'));
      expect(result, contains('style="fill:#FBFCFC;"'));
      expect(result, isNot(contains('class="st0"')));
      expect(result, isNot(contains('class="st1"')));
    });

    test('strips the <style> block itself once its rules are inlined', () {
      // Sem isso o flutter_svg ainda encontra o elemento <style> ao
      // percorrer o XML e loga "unhandled element <style/>", mesmo com as
      // cores já corretas via style="..." inline.
      const svg = '''
<svg viewBox="0 0 590 590">
<style type="text/css">
	.st0{fill:#26603C;}
</style>
<path class="st0" d="M0,0" />
</svg>
''';

      final result = inlineSvgCssClasses(svg);

      expect(result, isNot(contains('<style')));
      expect(result, isNot(contains('</style>')));
      expect(result, contains('style="fill:#26603C;"'));
    });

    test('returns the SVG unchanged when there is no <style> block', () {
      const svg = '<svg><path fill="#0093D8" d="M0,0" /></svg>';

      expect(inlineSvgCssClasses(svg), svg);
    });

    test(
      'returns the SVG unchanged when the <style> block has no class rules',
      () {
        const svg =
            '<svg><style>svg { enable-background: new; }</style><path d="M0,0" /></svg>';

        expect(inlineSvgCssClasses(svg), svg);
      },
    );

    test(
      'handles comma-separated selectors and merges multiple rules per class',
      () {
        // Padrão real do escudo do Fortaleza: seletores agrupados por
        // vírgula, e uma classe recebendo fill de uma regra e fill-rule de
        // outra.
        const svg = '''
<svg viewBox="0 0 500 500">
<style>.cls-1,.cls-4{fill:#fefefe;}.cls-1,.cls-2,.cls-3{fill-rule:evenodd;}.cls-2{fill:#2861a6;}.cls-3{fill:#e1251b;}</style>
<path class="cls-1" d="M0,0" />
<path class="cls-2" d="M1,1" />
<path class="cls-3" d="M2,2" />
<path class="cls-4" d="M3,3" />
</svg>
''';

        final result = inlineSvgCssClasses(svg);

        expect(result, contains('style="fill:#fefefe;;fill-rule:evenodd;"'));
        expect(result, contains('style="fill-rule:evenodd;;fill:#2861a6;"'));
        expect(result, contains('style="fill-rule:evenodd;;fill:#e1251b;"'));
        expect(result, contains('style="fill:#fefefe;"'));
        expect(result, isNot(contains('class="cls-')));
      },
    );
  });
}
