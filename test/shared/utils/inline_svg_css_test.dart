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

    test('returns the SVG unchanged when there is no <style> block', () {
      const svg = '<svg><path fill="#0093D8" d="M0,0" /></svg>';

      expect(inlineSvgCssClasses(svg), svg);
    });

    test('returns the SVG unchanged when the <style> block has no class rules', () {
      const svg = '<svg><style>svg { enable-background: new; }</style><path d="M0,0" /></svg>';

      expect(inlineSvgCssClasses(svg), svg);
    });
  });
}
