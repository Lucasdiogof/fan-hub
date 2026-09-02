/// Fallback offline de UM dataset de conteúdo, indexado por
/// [ClubIdentity.code] — nunca um fallback único "genérico" que qualquer
/// clube acabaria compartilhando.
///
/// Hoje só existe a entrada `'goias'` em cada registry real (o único
/// clube cadastrado) — mas o mecanismo em si já é reutilizável: cadastrar
/// um 2º clube nunca envolve editar 5 `switch (code)` espalhados pelos
/// repositories, só adicionar uma entrada aqui.
///
/// Deliberadamente NUNCA resolve pra um clube "default" quando o código
/// pedido não está registrado — [forClub] devolve `null` nesse caso, e é
/// responsabilidade explícita de quem chama decidir o que fazer (ver
/// `ClubDataUnavailableException`), nunca um fallback implícito.
class ClubScopedFallback<T> {
  const ClubScopedFallback(this._byClubCode);

  final Map<String, T> _byClubCode;

  T? forClub(String clubCode) => _byClubCode[clubCode];
}
