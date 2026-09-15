# Auditoria final — Passaporte Esmeraldino 1943–2026

**Corte:** 2026-09-15
**Partidas elegíveis no arquivo principal:** 3.840
**Registros no master (inclui administrativos/excluídos):** 3.872
**Excluídos/administrativos:** 32

## Integridade

- IDs duplicados no master: **0**
- IDs duplicados no principal: **0**
- `historical_source_no` duplicado: **0**
- Temporadas cobertas: **84/84 (1943–2026)**
- Temporadas faltantes: **nenhuma**
- Candidatos de chave natural duplicada: **0** (mantidos para revisão apenas se houver; ID continua único)

## Qualidade conhecida

- Partidas elegíveis sem placar: **1** — hist-f80-0042
- Partidas elegíveis sem data exata: **1** — hist-f80-0042
- Partidas elegíveis com estádio desconhecido: **2140**
- Partidas elegíveis com horário desconhecido: **2379**

## Validações de 2026

- Campeonato Goiano: **14**
- Copa do Brasil: **5**
- Série B: **28**
- Total: **47**

## Exceções documentais importantes

- 1943: temporada interrompida/não homologada; Goiás x Goiânia de 12/09 fica `SCHEDULED_UNCONFIRMED` e fora do principal.
- 1943 Atlético x Goiás: adotado 5–2 para o Atlético; RSSSF apresenta divergência 5–1.
- 1946 Goiás x ABG: partida competitiva conhecida, mas sem dia/mês e sem placar recuperáveis.
- 26/02/1964 Goiás x Ferroviário: reposição preservada em 1–2 com `score_confidence=MEDIUM`.
- 1984: seis jogos marcados como `Goiano (Desconsiderado)` ficam no master, fora do principal.
- Os originais anulados de 17/11/1963, 13/12/1976 e 16/09/1984 foram reconstruídos como `ADMIN_EVENT` apenas para auditoria.
- Torneios Renê Pompeu de Pina (1978), Adjair Lima (1980), Luiz Miguel Estêvão (1986) e Íris Rezende (1993) ficam fora do principal como amistosos/complementares.
- O registro `Torneio-GO` de 04/09/1955 foi preservado como exceção de natureza não comprovada e não entra no principal.

## Contagem anual do Passaporte

- 1943: 3
- 1944: 4
- 1945: 9
- 1946: 11
- 1947: 14
- 1948: 14
- 1949: 10
- 1950: 18
- 1951: 19
- 1952: 16
- 1953: 20
- 1954: 8
- 1955: 17
- 1956: 16
- 1957: 21
- 1958: 16
- 1959: 15
- 1960: 18
- 1961: 19
- 1962: 6
- 1963: 17
- 1964: 31
- 1965: 26
- 1966: 28
- 1967: 28
- 1968: 26
- 1969: 36
- 1970: 23
- 1971: 40
- 1972: 43
- 1973: 58
- 1974: 57
- 1975: 48
- 1976: 56
- 1977: 44
- 1978: 50
- 1979: 52
- 1980: 45
- 1981: 69
- 1982: 56
- 1983: 59
- 1984: 45
- 1985: 52
- 1986: 57
- 1987: 38
- 1988: 67
- 1989: 65
- 1990: 57
- 1991: 52
- 1992: 63
- 1993: 59
- 1994: 65
- 1995: 63
- 1996: 67
- 1997: 69
- 1998: 57
- 1999: 60
- 2000: 84
- 2001: 64
- 2002: 55
- 2003: 72
- 2004: 75
- 2005: 65
- 2006: 69
- 2007: 66
- 2008: 63
- 2009: 68
- 2010: 74
- 2011: 64
- 2012: 68
- 2013: 71
- 2014: 62
- 2015: 64
- 2016: 58
- 2017: 62
- 2018: 64
- 2019: 64
- 2020: 57
- 2021: 51
- 2022: 61
- 2023: 72
- 2024: 58
- 2025: 60
- 2026: 47
