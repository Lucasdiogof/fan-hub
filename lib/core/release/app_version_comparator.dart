/// Compara duas versões semânticas (`major.minor.patch`) NUMERICAMENTE,
/// nunca como string — uma comparação lexical erraria "1.10.0" vs "1.9.0"
/// (compara caractere a caractere: '1' < '9', então "1.10.0" pareceria
/// menor). Sufixo de build (`+N`) e pre-release (`-...`) são ignorados;
/// segmentos ausentes ou não numéricos contam como 0.
///
/// Retorna negativo se `a` < `b`, zero se iguais, positivo se `a` > `b`.
int compareSemanticVersions(String a, String b) {
  final partsA = _parseVersionParts(a);
  final partsB = _parseVersionParts(b);
  for (var i = 0; i < 3; i++) {
    final cmp = partsA[i].compareTo(partsB[i]);
    if (cmp != 0) return cmp;
  }
  return 0;
}

List<int> _parseVersionParts(String version) {
  final core = version.split('+').first.split('-').first;
  final segments = core.split('.');
  return List.generate(3, (i) {
    if (i >= segments.length) return 0;
    return int.tryParse(segments[i]) ?? 0;
  });
}

/// Decide se a instalação atual está abaixo do mínimo exigido.
///
/// Build number é a comparação primária e determinística: para App
/// Store/Play Store ele é um inteiro estritamente crescente a cada release
/// (garantido pelo processo de build, nunca reaproveitado), enquanto a
/// disciplina de bump do `major.minor.patch` pode falhar humanamente. Só
/// cai pra comparação semântica se algum dos dois builds vier ausente/zerado
/// (linha de config sem build number preenchido) — nunca o contrário.
bool isBelowMinimumRelease({
  required int currentBuild,
  required String currentVersion,
  required int minimumBuild,
  required String minimumVersion,
}) {
  if (currentBuild > 0 && minimumBuild > 0) {
    return currentBuild < minimumBuild;
  }
  return compareSemanticVersions(currentVersion, minimumVersion) < 0;
}
