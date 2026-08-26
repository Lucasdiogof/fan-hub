/// Encurta o nome oficial de um time pra exibição — tira sufixos de sigla
/// no fim do nome (ex.: "FC", "EC", "S.J.", "SJDR") mantendo o nome de
/// verdade intacto. "São Bernardo FC" → "São Bernardo", "Athletic Club
/// SJDR" → "Athletic Club". Só mexe em tokens finais que são só letras
/// maiúsculas (com ou sem ponto) — sem limite de tamanho, porque siglas de
/// cidade (ex. "SJDR" = São João del-Rei) passam fácil de 3 letras; nunca
/// mexe em palavras reais como "Clube"/"Esporte" porque essas nunca vêm
/// inteiramente em maiúsculas nesses nomes, só as siglas vêm.
String shortTeamName(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  while (words.length > 1) {
    final bare = words.last.replaceAll('.', '');
    final isAbbreviation = bare.isNotEmpty && bare == bare.toUpperCase();
    if (!isAbbreviation) break;
    words.removeLast();
  }
  return words.join(' ');
}
