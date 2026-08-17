final _styleBlock = RegExp(r'<style[^>]*>([\s\S]*?)</style>', caseSensitive: false);
final _classRule = RegExp(r'\.([\w-]+)\s*\{([^}]*)\}');

/// Alguns escudos (ex.: exportados do Illustrator) definem cor via
/// `<style>.st0{fill:#000}</style>` + `class="st0"` em vez de `fill="..."`
/// direto no elemento. O `flutter_svg` não resolve classe CSS por `<style>`
/// — todo elemento sem `fill` explícito cai no preto padrão do SVG. Essa
/// função acha essas regras e substitui `class="stN"` por `style="..."`
/// equivalente, inline, antes de passar o SVG pro `flutter_svg`.
String inlineSvgCssClasses(String svg) {
  final styleMatch = _styleBlock.firstMatch(svg);
  if (styleMatch == null) return svg;

  final rules = <String, String>{};
  for (final rule in _classRule.allMatches(styleMatch.group(1)!)) {
    rules[rule.group(1)!] = rule.group(2)!.trim();
  }
  if (rules.isEmpty) return svg;

  var result = svg;
  for (final entry in rules.entries) {
    result = result.replaceAll('class="${entry.key}"', 'style="${entry.value}"');
  }
  return result;
}
