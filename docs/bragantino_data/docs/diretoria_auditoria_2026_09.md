# Diretoria / Gestão do Red Bull Bragantino — auditoria de fonte (2026-09-09)

O schema atual (`club_board_sections`/`club_board_members`, ver
`supabase/bragantino_club_board_2026_09.sql`) só guarda `name`/`role`/
`section_id`/`sort_order`/`photo_url` — sem coluna pra fonte/confiança/data
de verificação. Este arquivo é o registro dessa evidência, versionado à
parte pra não forçar uma mudança de schema sem necessidade (schema
convergido Goiás/Bragantino).

## Estrutura societária (contexto, NUNCA modelada como "pessoa" no app)

```
RED BULL BRAGANTINO FUTEBOL LTDA.
CNPJ 51.315.976/0001-94
Natureza: Sociedade Empresária Limitada
Controladora/sócia: Red Bull GmbH (Sócio Pessoa Jurídica Domiciliado no
  Exterior, entrada 26/08/2020)
```

QSA (Receita Federal, consultado/atualizado ago/2026) — 3 administradores,
todos com função executiva também listada abaixo:

| Nome | Qualificação societária | Entrada |
|---|---|---|
| André Raul Rocha | Administrador | 15/12/2022 |
| Luiz Felipe Monteiro Lemos | Administrador | 31/10/2022 |
| Diego Cerri | Administrador | 02/05/2024 |

Consta tanto na matriz quanto nas filiais atuais da Ltda.
`SOCIETARY_ADMINISTRATION = CONFIRMED`.

Marco Antônio Abi Chedid **não** consta como administrador atual do QSA —
por isso nunca deve aparecer como CEO/chefe executivo, só como papel
honorário (ver abaixo).

## Pessoas — evidência por linha

| Nome | Cargo publicado | Área | Confidence | Fonte principal | Data | Verificado em |
|---|---|---|---|---|---|---|
| André Raul Rocha | CEO / Diretor Administrativo | Administração Executiva | VERY_HIGH | QSA Receita Federal (Administrador) + imprensa recorrente 2026 ("CEO do Red Bull Bragantino" — brasilemfolhas.com.br, mktesportivo.com, portaltela.com, todas mai/mar 2026) | mai-mar/2026 | 2026-09-09 |
| Diego Cerri | Diretor Esportivo | Futebol | VERY_HIGH | Anúncio oficial redbullbragantino.com ("Diego Cerri É O Novo Diretor Esportivo"), ABEX Futebol, Transfermarkt, Wikipédia PT, Trivela (dez/2025) | jun/2023-dez/2025 | 2026-09-09 |
| Luiz Felipe Monteiro Lemos | Diretor Financeiro | Financeiro | HIGH | QSA Receita Federal (Administrador, 31/10/2022) + documentação corporativa/perfil profissional prévio + levantamento de lideranças administrativas do clube | 2022-2026 | 2026-09-09 (não re-verificado individualmente nesta rodada — mantido pela força do dado societário) |
| Marco Antônio Abi Chedid | Presidente de Honra | Institucional / Honorário | VERY_HIGH | Múltiplas fontes independentes e recentes e consistentes: Jornal Mais Bragança (fev/2024, ago/2025), Os Donos da Bola (jun/2023), futebolinterior.com.br, 102FM (2025) — todas "presidente de honra" | 2023-2025 | 2026-09-09 |
| Bernardo Caixeta Chaves | Head de Marketing | Marketing | HIGH | Evidência ligada a projeto oficial da nova Arena Red Bull chamando "Head de Marketing"; imersão Universidade do Futebol/FPF usa "Diretor de Marketing" (mais antiga/genérica, não usada) | 2026 | 2026-09-09 (não re-verificado individualmente nesta rodada) |
| Lucas Bettine | Gerente de Comunicação | Comunicação | HIGH | Fonte municipal/institucional recente ("Gerente de Comunicação"); imersão usa "Diretor de Comunicação" (mais antiga, não usada) | 2026 | 2026-09-09 |
| Carolina Soares | Gerente de Recursos Humanos | Recursos Humanos | MEDIUM_HIGH | Imersão Universidade do Futebol/FPF ("Diretora de RH" na publicação, rebaixado pra Gerente por falta de fonte oficial recente confirmando o nível hierárquico) + perfil profissional ("Human Resources Manager") | 2025-2026 | 2026-09-09 — **se aparecer fonte oficial recente dizendo "Diretora de RH", promover** |
| Igor Melissopoulos | Gerente Jurídico | Jurídico | HIGH | Fonte municipal recente usa "gerente"; imersão usa "Diretor Jurídico" (mais antiga, não usada) | 2026 | 2026-09-09 |
| Elisabete Freitas | Gerente de Infraestrutura | Infraestrutura | VERY_HIGH | Fontes oficiais do clube e da Prefeitura de Bragança Paulista (projeto da nova Arena Red Bull – Nabi Abi Chedid); documentação FPF prévia ("Infrastructure Manager") | 2025-2026 | 2026-09-09 |
| Guilherme Macedo | Diretor de Projetos | Projetos | MEDIUM_HIGH | Imersão Universidade do Futebol/FPF; LinkedIn confirma vínculo com o clube e certificação PMP® (consistente com função de projetos), mas não expõe o título exato — **sem contradição encontrada, mantido como proposto** | 2025-2026 | 2026-09-09 (busca adicional feita, sem confirmação nem contradição do título exato) |
| Miriam Medeiros | Gerente de Operações | Operações | HIGH | Fonte CBF Academy ("Gerente de Operações", responsável pelo CPD/Estádio Nabi Abi Chedid/Casa Red Bull Bragantino); documentação FPF prévia também em Operações | 2025-2026 | 2026-09-09 |
| Henrique Motta | **Head de TI e Transformação Digital** | Tecnologia | HIGH | **CORRIGIDO nesta rodada** — LinkedIn pessoal ("Head of IT & Digital Transformation at Red Bull Bragantino") + bio de palestrante Mind The Sec 2025 ("Head de TI e Transformação Digital"). A imersão usava "Diretor" e a imprensa de mai/2025 usava "Gerente de TI" — nenhum dos dois é o título mais atual/preciso; as duas fontes de 2025 mais fortes (LinkedIn + bio de evento) convergem em "Head" | 2025 | 2026-09-09 |
| Fabio Donatelli | **Head Comercial** | Comercial | HIGH | **CORRIGIDO nesta rodada** — entrevista em vídeo dez/2025 ("Head Comercial da Red Bull fala sobre exploração..."); LinkedIn pessoal diz "Business Development Manager" (mesma família de função, em inglês). A imersão usava "Diretor Comercial" — não encontrado em nenhuma fonte independente, substituído | dez/2025 | 2026-09-09 |

`REVIEW_PENDING = 0` — todos os 13 nomes bateram VERY_HIGH, HIGH ou
MEDIUM_HIGH; nenhum ficou preso em REVIEW.

## Nomes históricos — explicitamente NÃO usados como atuais

`Thiago Roberto Scuro`, `Bruno Sgorlon Abilel`, `Luiz Arthur Abi Chedid`
aparecem em documentação societária/contratual mais antiga. Thiago Scuro
saiu do Bragantino em 2023 (foi pro AS Monaco) — nenhum dos três entra
nesta rodada como diretoria `CURRENT`. `HISTORICAL != CURRENT`.

## Fotos

`ASSET_GAP` pras 13 pessoas — nenhuma foto real/confiável disponível no
projeto pra nenhuma delas. `photo_url` fica `null` em todas (a UI já cai
pro círculo com as iniciais do nome, `_InitialsAvatar` em
`club_diretoria_page.dart` — nenhuma mudança de código necessária). Nunca
usar foto de outra pessoa nem imagem gerada por IA.
