-- ============================================================================
-- Quem Vestiu o Manto (Goiás): tira do jogo os 4 registros sem identidade
-- definida (Hugo, Júlio César, Marcão, Welliton). Decisão do usuário em
-- 2026-10-02: NÃO apagar — cada nome corresponde a várias pessoas diferentes
-- na história do clube (ver auditoria, fases 3 e 4) e o registro fica
-- guardado como `incomplete` até alguém decidir quem ele representa. Só
-- deixam de aparecer como opção de palpite (`is_active = false` = desabilitado
-- no jogo; o repositório só lê `is_active = true`).
-- ============================================================================

do $$
begin
  if (select count(*) from public.guess_players
      where id in ('hugo_identity_review', 'julio_cesar_identity_review',
                   'marcao_identity_review', 'welliton_identity_review')
        and is_active = true and data_status = 'incomplete') <> 4 then
    raise exception 'os 4 registros não estão ativos/incomplete como esperado — aborta.';
  end if;
end $$;

update public.guess_players set is_active = false
where id in ('hugo_identity_review', 'julio_cesar_identity_review',
             'marcao_identity_review', 'welliton_identity_review');

do $$
begin
  if (select count(*) from public.guess_players where is_active = false) <> 4
     or (select count(*) from public.guess_players where is_active = true) <> 170
     or (select count(*) from public.guess_players where data_status = 'verified') <> 79 then
    raise exception 'Pós: contagens do Manto não ficaram 170 ativos / 4 inativos / 79 verified.';
  end if;
end $$;
