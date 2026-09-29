# Prompt de continuação: pesquisa de estádios do Goiás (checkpoint 1985)

Cole o texto abaixo na ferramenta de pesquisa e anexe os 3 arquivos listados em "Arquivos".

---

CONTINUE A PESQUISA HISTÓRICA DOS ESTÁDIOS DO GOIÁS ESPORTE CLUBE A PARTIR DESTE CHECKPOINT. NÃO reinicie o levantamento e NÃO revalide partidas já confirmadas sem evidência concreta de erro.

## Estado atual (2026-09-28)
- Escopo: linhas com `dataset_origin = historical_futebol80` (2.102 partidas, 1943–1999).
- **Confirmadas: 1.985 / 2.102 = 94,43%.** Pendentes (`venue_name = UNKNOWN`): **117**.
- Metas: 95% = 1.997 (faltam 12); 96% = 2.018 (faltam 33).

## Arquivos (anexos)
- `passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1985.csv`: dataset canônico. Cada confirmação traz a fonte em `source_secondary`, o trecho da evidência em `notes` e eventuais divergências em `conflict_note`.
- `GOIAS_PENDENCIAS_ESTADIOS_1985.csv`: só as 117 pendências.
- `checkpoint_goias_estadios_2026-09-27.md`: log completo (seções 1–51). Leia pelo menos as seções 45 a 51 antes de começar.

## Regras (inegociáveis)
1. NÃO inventar estádio. Não concluir por mando de campo, cidade, costume do clube, rodada vizinha, "essa competição sempre foi nesse estádio" ou probabilidade.
2. Só confirmar com evidência que ligue ESTE jogo (data + Goiás + adversário, idealmente placar) ao estádio: ficha técnica ("Jogo: A x B. Local: ..."), matéria pós-jogo ("venceu o X por 2 a 1, ontem, no Estádio Y") ou matéria/ficha PRÉ-JOGO específica ("Goiás e X jogam hoje, às 16h, no Estádio Y"). Quando a fonte não individualizar o jogo, cruzar pelo menos 2 evidências independentes.
3. Torneio Início: só vale fonte da edição daquele ano ("o Torneio Início será hoje no estádio X"). A frase genérica "todo Torneio Início foi no Olímpico" NÃO vale.
4. Rejeitar: jogos de juniores e preliminares; trecho que só dá a CIDADE ("o Goiás vai a Caldas Novas"); estádio do jogo seguinte; tabela em que não dá para saber qual jogo foi em qual estádio.
5. Tolerância de data de ±2 dias, só quando é inequivocamente o mesmo jogo. NÃO mude a data do CSV; registre a divergência no `conflict_note`.
6. Placar diferente: julgue sempre pelas colunas `goias_score`/`opponent_score`, NUNCA pelo `score_display`, que em várias linhas está na ordem mandante x visitante. Se o RESULTADO (V/E/D) mudar, não aplique; só documente.
7. Preservar o nome do estádio como a fonte escreve (limpando o OCR). Não mexer em nenhum campo além de `venue_name`, `venue_city`, `venue_state`, `venue_confidence` (HIGH), `source_secondary`, `notes` e `conflict_note`. Ao confirmar, limpar as colunas `venue_probable_*`.
8. As colunas `venue_probable_*` (PROVÁVEL) NÃO contam como confirmadas. Não promover PROVÁVEL sem fonte.
9. A cada lote: recontar e gerar um novo checkpoint `..._CHECKPOINT_<N>.csv`, em que N é a contagem VERIFICADA.

## Fontes já esgotadas (não repetir sem ideia nova)
- **Futebol de Goyaz** (futeboldegoyaz.com.br, Goiás = 469): confrontos contra todos os clubes e TODAS as fichas `/partidas/<ID>/partida` a ±3 dias de cada pendência foram lidas. A partir de ~1984, e em 1976, as fichas do Goiano vêm sem estádio.
- **Diário da Manhã** no IHGG (hemeroteca.ihgg.org, PUB_IDEN=102): lido de D-3 a D+5 em texto e, nas páginas de esporte, na IMAGEM (as fichas pré-jogo com "Local:" só aparecem lendo a imagem). O jornal NÃO circulou de 03/10/1984 a 10/10/1986. Faltam também edições de jul/1993, set/1994 e mai–jul/1995. Parte do acervo é PDF só com imagem (sem OCR).
- **IHGG, outros títulos:** Folha de Goiaz (1939–52), Diário da Tarde (1958–59), 5 de Março, Jornal do Povo, Sport News (só abr–jun/1975) e Revista Brasília Esportiva (só 25/06/1953).
- **Biblioteca Nacional:** o Jornal de Notícias (GO, bib 843687) já foi usado; não tem esporte nas edições de 1952/53/57 que interessam. Para GO nos anos 80 a BN só tem o Jornal do Tocantins. O **Correio Braziliense 1980–89 (bib 028274_03)** cita muito o "Serra Dourada" (3.977 ocorrências; em 1985–86, quase toda edição), mas NÃO tem PDF para download (só 1960–67). Só dá para ler página por página no leitor, com CAPTCHA resolvido pelo usuário.
- ogol.com.br, futebolnacional.com.br, RSSSF (inclusive tablesfq), Wikipédia, goiasec.com.br, Futebol80, cinturaobrasileiro.com, arquivosfutebolbrasil.com.br: já cruzados. DM Acervo (dmacervo.com.br) só tem edições de 2024 em diante. WildStat é bloqueado por Cloudflare.

## As 117 pendências, por grupo
| Grupo | Qtde | IDs (hist-f80-) | Situação |
|---|---|---|---|
| A. Goiano 1985 | 24 | 1651–1681 | Sem Diário da Manhã (jornal fechado). Única pista: Correio Braziliense na BN (leitor, CAPTCHA). |
| B. Goiano 1986 (fev–jul) | 27 | 1687–1718 | Mesmo caso do grupo A. |
| C. Goiano 1984 (ago–dez) | 13 | 1603–1624 | DM sem edições; o Correio no leitor da BN só começa em meados de out/1984 (serve para 1617 e 1624). |
| D. Goiano 1993/94/95 | 14 | 2169–2172, 2246, 2295–2311 | Sem edição do DM a ±7 dias (2295: o jornal só diz "em Caldas Novas"). |
| E. Goiano 1976 | 15 | 1066–1087 | FdG sem estádio em 1976 inteiro. Sem jornal diário digitalizado. |
| F. Torneio Início | 10 | 0149, 0172, 0227–0229, 0274, 0555–0558 | 1952: acervo da BN começa em jul/1952. 1953/1957: as edições exatas não têm esporte. 1955 e 1966 (RSSSF confirma placares, mas sem local). |
| G. Conflito de placar com resultado diferente | 4 | 0509, 0665, 0780, 0802 | O FdG tem a ficha com estádio, mas o resultado não bate com o CSV. Não aplicar sem 2ª fonte. |
| H. Avulsos 1946–1987 | 10 | 0042, 0231, 0436, 0439, 0472, 0541, 0744, 1028, 1105, 1766 | FdG sem estádio ou jogo ausente; 1028 (Anapolina 1975): o Sport News só diz "em Anápolis". |

Total: 24 + 27 + 13 + 14 + 15 + 10 + 4 + 10 = 117. Na dúvida, o CSV de pendências é a referência.

## Caminhos sugeridos
1. **Grupos A/B/C (64 jogos):** o Correio Braziliense 1980–89 no leitor da BN (https://memoria.bn.gov.br/docreader/docreader.aspx?bib=028274_03). A busca por "Serra Dourada" ou "Goiás" marca as edições com ocorrências. O usuário resolve o CAPTCHA e manda prints das páginas de esporte. Edição estimada do dia seguinte ao jogo (±2): em 1985, edição ≈ 07948 + dia do ano − 1; em 1986, ≈ 08308 + dia do ano − 1. Testar primeiro 1 ou 2 jogos para ver se o jornal traz "Local:" no Goiano.
2. **Outros jornais goianos com acervo próprio** (O Popular, Jornal Opção, Folha de Goiaz dos anos 80), se houver acesso.
3. **Grupo G:** procurar uma 2ª fonte do placar (jornal da época) que desempate CSV x FdG.

## Formato de entrega de cada confirmação
```
ID | DATA | MANDANTE PLACAR VISITANTE | ESTÁDIO (como na fonte) | CIDADE | FONTE (jornal, edição, página) | URL | TRECHO LITERAL | CONFIANÇA
```
Depois, informe: confirmadas N/2102 = X%, UNKNOWN restantes, o que foi tentado sem sucesso e por quê.
