/// Levantada quando um dataset tenant-scoped (Supabase filtrado por
/// `club_id`) não tem nenhuma linha pro clube ativo E esse clube também
/// não tem fallback offline registrado (`ClubScopedFallback.forClub`
/// devolveu `null`).
///
/// Nunca significa "erro de rede/banco" — a query pode ter funcionado
/// perfeitamente e simplesmente não existir dado provisionado pra este
/// clube ainda. É o invariante NO_CROSS_CLUB_FALLBACK tornado explícito:
/// nunca silenciosamente devolver o fallback de outro clube (hoje,
/// Goiás) só porque ele é o único disponível.
///
/// Deliberadamente sem UI/dialog acoplado — quem chama decide como tratar
/// (hoje, nenhum caller trata isso de propósito, porque o único clube
/// real cadastrado sempre tem dado + fallback; existe pra ficar seguro
/// quando um 2º clube for cadastrado sem fallback ainda).
class ClubDataUnavailableException implements Exception {
  const ClubDataUnavailableException({
    required this.table,
    required this.clubCode,
  });

  final String table;
  final String clubCode;

  @override
  String toString() =>
      'ClubDataUnavailableException: nenhum dado em "$table" pro clube '
      '"$clubCode" (Supabase vazio/indisponível e sem fallback offline '
      'registrado pra este clube).';
}
