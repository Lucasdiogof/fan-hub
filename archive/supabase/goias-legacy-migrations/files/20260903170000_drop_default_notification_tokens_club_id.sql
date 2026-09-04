-- M4.1c-B — remove o DEFAULT transicional de user_notification_tokens.club_id.
-- Autorizada só depois do runtime 1.0.2+3 (que já manda club_id explícito no
-- registro/refresh do token) estar publicado (PWA) E distribuído (APK, ~3
-- pessoas confirmadas pelo dono) — ver docs/multiclub/43_m4_1_critical_club_leakage_report.md.
--
-- club_id continua NOT NULL, FK -> clubs(id), fcm_token continua a única
-- UNIQUE — nada disso muda aqui, só o DEFAULT sai. Toda escrita nova precisa
-- mandar club_id explícito ou falha alto (NOT NULL sem DEFAULT).

alter table public.user_notification_tokens
  alter column club_id drop default;
