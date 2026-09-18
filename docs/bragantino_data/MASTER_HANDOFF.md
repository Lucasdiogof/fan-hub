# RB Bragantino — MASTER HANDOFF (2026-09-07)

Este é o pacote consolidado para implementação no projeto Flutter/Supabase.

## Estado das frentes
Todos os conteúdos pesquisados do Bragantino estão consolidados neste pacote, incluindo clube, história/timeline, títulos, elenco snapshot, diretoria, parceiros, transparência, estádios, ídolos, trajetórias, quiz, escalações e SQL seed. Músicas/cânticos estão fora do escopo por decisão do usuário.

## Lincom
Usar 160 jogos / 72 gols. Não usar 73 como contador principal; manter a divergência apenas como audit note.

## Passaporte Massa Bruta
A cobertura histórica 2000–2026 está auditada. Leia `data/bragantino_passport_audit_manifest_v4.json`. O manifest fixa 1.424 jogos realizados até 05/09/2026 e 1.437 registros de calendário contando o restante de 2026.

Atenção: a auditoria anual está completa E TODOS OS 27 LOTES (2000-2026, 1.436 partidas) estão materializados e validados em 2026-09-18 (`tooling/bragantino_passport/source/bragantino_passport_<ano>.json` + seed SQL por ano, `node tooling/bragantino_passport/validate_import.mjs` passa 100% pros 27 lotes). O bloqueio 403 do oGol que travava o lote 2023 não se repetiu em nenhuma das ~1.400 requisições feitas desde então (2000-2010 buscado via `fetch()` direto do Node, mais rápido que navegador). Única exceção ao total do manifest: Bragantino x São José (25/08/2006, Copa Paulista) foi decidida administrativamente (W.O., sem placar) e excluída do Passaporte — ver `important_reconciliations` no `audit_manifest_v4.json`. Nada foi aplicado no Supabase automaticamente — seguir o runbook manual do README (29 SQLs, nessa ordem, no projeto do Bragantino).

## Identidade
Clube Atlético Bragantino e Red Bull Bragantino são continuidade histórica para o Passaporte; preservar nomenclatura adequada à época quando disponível.
