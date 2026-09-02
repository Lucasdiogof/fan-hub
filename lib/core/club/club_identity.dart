/// Quem é o clube — nunca conteúdo, nunca cor, nunca integração externa.
///
/// [code] e [slug] são conceitualmente diferentes mesmo coincidindo hoje
/// (os dois valem `'goias'` pro único clube cadastrado): [code] é o
/// seletor de build (`APP_CLUB=<code>`, ver `resolve_active_club.dart`),
/// [slug] é a chave real de `public.clubs.slug` no Supabase — nada garante
/// que sempre serão o mesmo texto se um dia divergirem (ex.: rebrand de
/// slug sem trocar o build flavor).
class ClubIdentity {
  const ClubIdentity({
    required this.code,
    required this.slug,
    required this.displayName,
    required this.shortName,
    required this.fanDemonym,
    required this.canonicalClubId,
  });

  /// Seletor de build — o valor esperado em `APP_CLUB`.
  final String code;

  /// `public.clubs.slug` no Supabase.
  final String slug;

  /// Nome completo — ex.: `'Goiás Esporte Clube'`.
  final String displayName;

  /// Nome curto — ex.: `'Goiás'`.
  final String shortName;

  /// Gentílico da torcida — ex.: `'Esmeraldino'`. Nunca mostrado cru ao
  /// usuário fora de composição l10n (ver `docs/multiclub/10_club_config
  /// .md#4`) — hoje só documentado aqui, nenhum consumidor real ainda.
  final String fanDemonym;

  /// `people`/`clubs.id` — o UUID canônico já usado pela fundação
  /// multiclub (Etapas B-F7). Pro Goiás: `4c16340d-300c-5ab2-903f-
  /// 17519db9b146` — o MESMO valor hoje espalhado só em
  /// `supabase/migrations/*` e `tooling/multiclub/*`, nunca em `lib/`
  /// (confirmado por auditoria — zero ocorrências).
  final String canonicalClubId;
}
