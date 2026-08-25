/// Embaralha [items], mas mantém os que já estão concluídos (segundo
/// [isDone]) exatamente na mesma posição — só os restantes trocam de lugar
/// entre si. Usado pelos jogos de coleção da Arena (Adivinhe a Escalação,
/// Adivinhe o Jogador) pra cada abertura vir numa ordem diferente sem tirar
/// do lugar o que o usuário já concluiu.
List<T> shuffleKeepingDone<T>(List<T> items, bool Function(T item) isDone) {
  final result = List<T?>.filled(items.length, null);
  final remaining = <T>[];
  for (final item in items) {
    if (!isDone(item)) remaining.add(item);
  }
  remaining.shuffle();

  var pointer = 0;
  for (var i = 0; i < items.length; i++) {
    result[i] = isDone(items[i]) ? items[i] : remaining[pointer++];
  }
  return result.cast<T>();
}
