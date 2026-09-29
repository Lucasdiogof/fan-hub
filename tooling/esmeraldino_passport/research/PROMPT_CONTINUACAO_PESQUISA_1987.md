# Prompt de continuação: pesquisa de estádios do Goiás (checkpoint 1987)

Cole o texto abaixo na ferramenta de pesquisa e anexe os 3 arquivos listados em "Arquivos".

---

CONTINUE A PESQUISA HISTÓRICA DOS ESTÁDIOS DO GOIÁS ESPORTE CLUBE A PARTIR DESTE CHECKPOINT. NÃO reinicie o levantamento e NÃO revalide partidas já confirmadas sem evidência concreta de erro.

## Estado atual (2026-09-29)
- Escopo: linhas com `dataset_origin = historical_futebol80` (2.102 partidas, 1943–1999).
- **Confirmadas: 1.987 / 2.102 = 94,53%.** Pendentes (`venue_name = UNKNOWN`): **115**.
- Metas: 95% = 1.997 (faltam 10); 96% = 2.018 (faltam 31).

## Arquivos (anexos)
- `passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1987.csv`: dataset canônico. Cada confirmação traz a fonte em `source_secondary`, o trecho da evidência em `notes` e eventuais divergências em `conflict_note`.
- `GOIAS_PENDENCIAS_ESTADIOS_1987.csv`: só as 115 pendências.
- `checkpoint_goias_estadios_2026-09-27.md`: log completo (seções 1–52). Leia pelo menos as seções 44 a 52 antes de começar — a seção 52 documenta a auditoria do seu último lote (foi aceito integralmente, as 2 confirmações bateram certinho).

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
10. **Sempre dar a URL EXATA do PDF/página de onde tirou o trecho, não só um resumo de busca.** Do lado de cá eu baixo o PDF original e confiro o texto extraído antes de aceitar qualquer confirmação — já aconteceu de resumo de busca (via IA) alucinar dado que não estava na fonte real. Uma citação sem URL exata e verificável não é aceita.

## Achado do lote anterior — MUITO IMPORTANTE, seguir essa pista primeiro
No último lote você achou a **Hemeroteca Digital Catarinense** (`hemeroteca.ciasc.sc.gov.br`, acervo do jornal *O Estado*, Florianópolis-SC) e confirmou 2 jogos do Goiano de 1976 (`hist-f80-1066` e `hist-f80-1085`) através de uma nota nacional de rodada — o jornal catarinense publicava, na página de esportes, um resumo da abertura/rodadas de vários campeonatos estaduais pelo Brasil, incluindo o Goiano, sempre citando adversário + horário + estádio. **Verifiquei pessoalmente baixando os dois PDFs e lendo o texto extraído — bateu 100%, aceito.**

Isso é uma classe de fonte nova que nunca tínhamos tentado (jornal de OUTRO estado cobrindo o Goiano como notícia nacional, não jornal local de Goiás). Vale muito a pena:
1. **Esgotar 1976 primeiro** (restam 13 pendências, ver Grupo E abaixo) — procurar mais edições d'O Estado (ou outro jornal catarinense/de outro estado na mesma hemeroteca) perto das datas das 13 rodadas restantes.
2. **Tentar a MESMA técnica pros anos 1984-1986 e 1993-1995**, que são os grupos mais numerosos do backlog (77 pendências) e que ficaram sem solução porque o Diário da Manhã (jornal de Goiás) não circulou ou não tem edição digitalizada nessas janelas. Um jornal de fora do estado com nota nacional de rodada pode ter continuado cobrindo o Goiano nesses anos mesmo sem o DM. Vale testar a Hemeroteca Catarinense e also buscar hemerotecas digitais de outros estados (Bahia, Pernambuco, Rio Grande do Sul, etc. — muitos têm acervo público tipo o de SC).
3. Ao achar uma edição relevante, sempre me dar a URL exata do PDF (não só o texto que você já extraiu) — preciso baixar e conferir antes de aceitar.

## Fontes já esgotadas (não repetir sem ideia nova)
- **Futebol de Goyaz** (futeboldegoyaz.com.br, Goiás = 469): confrontos contra todos os clubes e TODAS as fichas `/partidas/<ID>/partida` a ±3 dias de cada pendência foram lidas. A partir de ~1984, e em 1976, as fichas do Goiano vêm sem estádio.
- **Diário da Manhã** no IHGG (hemeroteca.ihgg.org, PUB_IDEN=102): lido de D-3 a D+5 em texto e, nas páginas de esporte, na IMAGEM. O jornal NÃO circulou de 03/10/1984 a 10/10/1986. Faltam também edições de jul/1993, set/1994 e mai–jul/1995.
- **IHGG, outros títulos:** Folha de Goiaz (1939–52), Diário da Tarde (1958–59), 5 de Março, Jornal do Povo, Sport News (só abr–jun/1975) e Revista Brasília Esportiva (só 25/06/1953).
- **Biblioteca Nacional:** Jornal de Notícias (GO, bib 843687) sem esporte nas edições de 1952/53/57 que interessam. Correio Braziliense 1980–89 (bib 028274_03) cita muito "Serra Dourada" mas só dá pra ler no leitor com CAPTCHA (o usuário resolve, se topar).
- ogol.com.br, futebolnacional.com.br, RSSSF (inclusive tablesfq), Wikipédia, goiasec.com.br, Futebol80, cinturaobrasileiro.com, arquivosfutebolbrasil.com.br, DM Acervo (dmacervo.com.br, só 2024+). WildStat é bloqueado por Cloudflare (mas se achar um jogo lá, procure o mesmo jogo na FdG — 4 casos assim já foram confirmados de forma independente).

## As 115 pendências, por grupo
| Grupo | Qtde | IDs (hist-f80-) | Situação |
|---|---|---|---|
| A. Goiano-Citadino 1946/1955 | 2 | 0042, 0231 | Sem dado recuperável (0042) / ficha sem estádio (0231). |
| B. Torneio Início (1952/53/55/57/66) | 10 | 0149, 0172, 0227–0229, 0274, 0555–0558 | Edições exatas sem esporte ou sem local; RSSSF confirma placar mas não estádio. |
| C. Goiano 1963-1975 avulsos | 10 | 0436, 0439, 0472, 0509, 0541, 0665, 0744, 0780 (Copa Goiás), 0802 (Integração Nacional), 1028 | FdG sem estádio ou jogo ausente da tabela; 0509/0665/0780/0802 têm conflito de placar que muda o resultado (não aplicar sem 2ª fonte). |
| **D. Goiano 1976** | **13** | 1067–1071, 1073, 1078–1081, 1083, 1084, 1087 | **PRIORIDADE — seguir a pista da Hemeroteca Catarinense.** |
| E. Torneio Incentivo 1976 | 1 | 1105 | Mesma pista de fonte nova pode servir. |
| F. Goiano 1984 (ago–dez) | 13 | 1603–1614, 1617, 1624 | DM sem edições; testar fonte nova de outro estado. |
| G. Goiano 1985 | 24 | 1651–1681 | Idem (jornal de Goiás fechado o ano inteiro). |
| H. Goiano 1986 (fev–jul) | 27 | 1687–1718 | Idem. |
| I. Goiano 1987/1993/1994/1995 | 15 | 1766, 2169–2172, 2246, 2295–2311 | Sem edição do DM a ±7 dias. |

Total: 2+10+10+13+1+13+24+27+15 = 115. Na dúvida, o CSV de pendências é a referência.

## Formato de entrega de cada confirmação
```
ID | DATA | MANDANTE PLACAR VISITANTE | ESTÁDIO (como na fonte) | CIDADE | FONTE (jornal, edição, página) | URL EXATA DO PDF | TRECHO LITERAL | CONFIANÇA
```
Depois, informe: confirmadas N/2102 = X%, UNKNOWN restantes, o que foi tentado sem sucesso e por quê. Sempre incluir a URL exata de cada PDF usado, mesmo que o trecho já esteja transcrito — preciso conferir a fonte primária antes de aceitar.
