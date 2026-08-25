final _styleBlock = RegExp(
  r'<style[^>]*>([\s\S]*?)</style>',
  caseSensitive: false,
);
final _cssRule = RegExp(r'([^{}]+)\{([^}]*)\}');

/// Alguns escudos (ex.: exportados do Illustrator) definem cor via
/// `<style>.st0{fill:#000}</style>` + `class="st0"` em vez de `fill="..."`
/// direto no elemento. O `flutter_svg` não resolve classe CSS por `<style>`
/// — todo elemento sem `fill` explícito cai no preto padrão do SVG. Essa
/// função acha essas regras e substitui `class="stN"` por `style="..."`
/// equivalente, inline, antes de passar o SVG pro `flutter_svg`.
///
/// Seletores múltiplos separados por vírgula (`.cls-1,.cls-4{fill:#fff;}`)
/// e várias regras pra mesma classe (uma pro `fill`, outra pro
/// `fill-rule`, por exemplo) são comuns em SVG exportado de ferramentas
/// vetoriais — as propriedades de cada classe são acumuladas, não
/// sobrescritas.
String inlineSvgCssClasses(String svg) {
  final styleMatch = _styleBlock.firstMatch(svg);
  if (styleMatch == null) return svg;

  final rules = <String, String>{};
  for (final rule in _cssRule.allMatches(styleMatch.group(1)!)) {
    final props = rule.group(2)!.trim();
    if (props.isEmpty) continue;

    for (final rawSelector in rule.group(1)!.split(',')) {
      final selector = rawSelector.trim();
      if (!selector.startsWith('.')) continue;
      final className = selector.substring(1);
      final existing = rules[className];
      rules[className] = existing == null ? props : '$existing;$props';
    }
  }
  if (rules.isEmpty) return svg;

  var result = svg;
  for (final entry in rules.entries) {
    result = result.replaceAll(
      'class="${entry.key}"',
      'style="${entry.value}"',
    );
  }
  // As regras já foram aplicadas inline acima — sem remover o bloco em si,
  // o `flutter_svg` ainda o encontra ao percorrer o XML e loga
  // "unhandled element <style/>", mesmo com as cores já corretas.
  return result.replaceFirst(_styleBlock, '');
}
