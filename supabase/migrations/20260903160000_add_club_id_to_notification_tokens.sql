-- M4.1c-A — user_notification_tokens ganha club_id (ADDITIVE, compatível
-- com o runtime em produção hoje). Um token FCM representa uma instalação
-- de app (Firebase App ID = package/bundle id), e uma instalação pertence
-- a exatamente 1 clube (modelo APP_CLUB) — nunca muitos-pra-muitos, então
-- uma coluna simples resolve (nunca uma join table). fcm_token continua
-- UNIQUE sozinho — o mesmo token físico nunca pode existir 2x, com
-- club_id ou sem.
--
-- Correção de rollout (achado do dono, antes de aplicar): a produção hoje
-- roda 1.0.1+2, cujo `registerToken` NÃO manda `club_id` — um `SET NOT
-- NULL` sem `DEFAULT` na mesma migration quebraria todo registro/refresh
-- desse runtime em produção (NOT NULL violation). Por isso esta migration
-- SÓ faz a parte aditiva: adiciona a coluna, faz o backfill via DEFAULT
-- (confirmado ao vivo em 2026-09-03: exatamente 2 tokens, ambos
-- inequivocamente Goiás), e marca NOT NULL — mas MANTÉM o DEFAULT
-- Goiás, de propósito, como rede de compatibilidade transitória enquanto
-- o runtime 1.0.1+2 continuar em campo.
--
-- `ALTER COLUMN club_id DROP DEFAULT` fica pra uma 2ª migration
-- (M4.1c-B, projetada mas NÃO criada como arquivo ainda — ver
-- docs/multiclub/43_m4_1_critical_club_leakage_report.md §"M4.1c-B"),
-- só aplicável depois que o runtime novo (que manda club_id explícito)
-- estiver de fato distribuído — nunca antes.

do $$
begin
  if (select count(*) from public.clubs) <> 1
     or not exists (
       select 1 from public.clubs
       where id = '4c16340d-300c-5ab2-903f-17519db9b146'::uuid
         and slug = 'goias'
     )
  then
    raise exception 'M4.1c-A guard: esperava clubs=1 (Goiás) — abortando';
  end if;
end $$;

alter table public.user_notification_tokens
  add column club_id uuid
    references public.clubs(id)
    default '4c16340d-300c-5ab2-903f-17519db9b146'::uuid;

alter table public.user_notification_tokens
  alter column club_id set not null;

-- DEFAULT MANTIDO DE PROPÓSITO NESTA MIGRATION — não remover aqui.
-- Compatibilidade com o runtime 1.0.1+2 em produção, que ainda não manda
-- club_id. A remoção definitiva (M4.1c-B) só acontece depois do rollout
-- do runtime novo estar confirmado.

-- fcm_token continua a única chave de unicidade (confirmado, não alterado):
--   user_notification_tokens_fcm_token_key = UNIQUE (fcm_token)
-- club_id nunca entra na chave — é atributo do token, não parte dela.
