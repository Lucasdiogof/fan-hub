# RB Bragantino — MASTER HANDOFF (2026-09-07)

Este é o pacote consolidado para implementação no projeto Flutter/Supabase.

## Estado das frentes
Todos os conteúdos pesquisados do Bragantino estão consolidados neste pacote, incluindo clube, história/timeline, títulos, elenco snapshot, diretoria, parceiros, transparência, estádios, ídolos, trajetórias, quiz, escalações e SQL seed. Músicas/cânticos estão fora do escopo por decisão do usuário.

## Lincom
Usar 160 jogos / 72 gols. Não usar 73 como contador principal; manter a divergência apenas como audit note.

## Passaporte Massa Bruta
A cobertura histórica 2000–2026 está auditada. Leia `data/bragantino_passport_audit_manifest_v4.json`. O manifest fixa 1.424 jogos realizados até 05/09/2026 e 1.437 registros de calendário contando o restante de 2026.

Atenção: a auditoria anual está completa. Lotes 2011-2023 (759 partidas) materializados e validados em 2026-09-18 (`tooling/bragantino_passport/source/bragantino_passport_<ano>.json` + seed SQL por ano, `node tooling/bragantino_passport/validate_import.mjs` passa 100% pros 16 lotes/945 partidas 2011-2026) — o bloqueio 403 do oGol que travava o lote 2023 não se repetiu ao testar via navegador. As 492 partidas de 2000–2010 ainda não estão materializadas. Não gerar dados fictícios para preencher esse espaço.

## Identidade
Clube Atlético Bragantino e Red Bull Bragantino são continuidade histórica para o Passaporte; preservar nomenclatura adequada à época quando disponível.
