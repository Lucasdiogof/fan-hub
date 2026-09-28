# Prompt de continuação: pesquisa de estádios do Goiás (checkpoint 1894)

Cole o texto abaixo na ferramenta de pesquisa e anexe os arquivos listados em "Arquivos".

---

CONTINUE A PESQUISA HISTÓRICA DOS ESTÁDIOS DO GOIÁS ESPORTE CLUBE A PARTIR DESTE CHECKPOINT. NÃO reinicie o levantamento e NÃO revalide partidas já confirmadas sem evidência concreta de erro.

## Estado canônico (2026-09-28)
- Escopo: linhas com `dataset_origin = historical_futebol80` (2.102 partidas, 1943–1999).
- **Confirmadas: 1.894 / 2.102 = 90,10%.** Pendentes (`venue_name = UNKNOWN`): **208**.
- Próximas metas: 91% = 1.913 (faltam 19); 92% = 1.934 (faltam 40); 95% = 1.997 (faltam 103).

## Arquivos (anexos)
- `passaporte_esmeraldino_1943_2026_ESTADIOS_CHECKPOINT_1894.csv`: dataset canônico. Cada confirmação traz a fonte em `source_secondary` e o trecho da evidência em `notes`.
- `GOIAS_PENDENCIAS_ESTADIOS_1894.csv`: só as pendências.
- `checkpoint_goias_estadios_2026-09-27.md`: log completo de TODAS as rodadas, com fontes testadas, descartes e motivos (seções 1–28). Leia as seções 17 a 28 antes de começar.

## Regras (inegociáveis)
1. NÃO inventar estádio. Não concluir por mando de campo, cidade, costume do clube, rodada vizinha, jogo do mesmo dia, estádio habitual do adversário ou probabilidade.
2. Só confirmar com evidência que ligue ESTE jogo (data + Goiás + adversário, idealmente placar) ao estádio: ficha técnica ("Jogo: A x B. Local: ..."), matéria pós-jogo ("venceu o X por 2 a 1, ontem, no Estádio Y"), ou matéria/ficha PRÉ-JOGO específica ("Goiás e X fazem hoje, às 17h, no Estádio Y").
3. A frase genérica "todo Torneio Início até 1974 foi no Olímpico" NÃO vale. Precisa de fonte da edição daquele ano.
4. Quando a fonte não individualizar totalmente o jogo, cruzar pelo menos 2 evidências independentes.
5. Rejeitar: jogos de JUNIORES e preliminares; trecho que só dá a CIDADE ("o Goiás vai a Ipameri"); estádio do jogo SEGUINTE; tabela em que não dá para saber qual jogo está em qual estádio.
6. Tolerância de data: ±2 dias, e só quando o jornal mostra que é o mesmo jogo (mesmo adversário, e placar quando houver).
7. Preservar o nome do estádio como a fonte escreve (limpando o OCR). A normalização de aliases é tarefa separada (`passaporte_esmeraldino_VENUE_ALIASES_rascunho.csv`), e o `venue_name` bruto não deve ser "canonicalizado".
8. Não mexer em nenhum campo além de `venue_name`, `venue_city`, `venue_confidence` (HIGH), `source_secondary` e `notes`.
9. Categoria separada PROVÁVEL: as colunas `venue_probable_*` (MEDIUM) NÃO contam como confirmadas e têm ~83% de acerto medido. Não promover PROVÁVEL a confirmado sem fonte.
10. A cada lote: registrar DATA, JOGO, ESTÁDIO, CIDADE, FONTE, URL, TRECHO e CONFIANÇA; recontar; gerar novo checkpoint `..._CHECKPOINT_<N>.csv`, em que N é a contagem VERIFICADA de confirmadas.

## Fontes JÁ ESGOTADAS (não repetir)
- **Futebol de Goyaz** (futeboldegoyaz.com.br): varri os confrontos do Goiás contra TODOS os clubes (IDs 1–3500) e as fichas de todas as pendências. A partir de ~1985 as fichas vêm sem estádio. Esgotado.
- **ogol.com.br** (id 2244) e **futebolnacional.com.br**: só jogos nacionais, já cruzados. Esgotados.
- **RSSSF Brasil**: as páginas de Torneio Início de 1967 e 1974 trazem o local (já aplicadas); as demais só a data. Sem estádio no Goiano.
- **Hemeroteca do IHGG** (hemeroteca.ihgg.org, sem CAPTCHA, PDF com texto): o *Diário da Manhã* (1980–2005) foi varrido de D-3 a D+5 de cada pendência. A *Folha de Goiaz* (1939–52) e o *Diário da Tarde* (1958–59) foram usados para os Torneios Início. O *5 de Março* e o *Jornal do Povo* não renderam.
- **Hemeroteca da BN**: CAPTCHA + Cloudflare nas imagens. Só funciona com o usuário baixando o PDF à mão ("Edições em PDF"). O *Jornal de Notícias* (GO, bib 843687, 1952–59) já foi usado para 1953 e 1956–59.
- Wikipédia, site oficial do Goiás (só a partir de 2003), Futebol80 (só marca C/F), Bola n@ Área (sem local): sem estádio.

## Pendências (208), por tipo
| Grupo | Qtde | Anos | Observação |
|---|---|---|---|
| A. Torneio Início | 16 | 1946 (1), 1951 (3), 1952 (1), 1953 (1), 1955 (3), 1957 (1), 1966 (4), 1984 (2) | Precisa da fonte da edição daquele ano. As edições de 1951 da *Folha de Goiaz* no IHGG são só imagem (sem OCR). O *Jornal de Notícias* não tem 1955. |
| B. Antes de 1980 (fora do Torneio Início) | 55 | 20 de 1976, 6 de 1971, 4 de 1974, 4 de 1979, 3 de 1970/75/78 e outros | Goiano (35), Brasileiro (13), Torneio Integração Nacional 1971 (4). Não há jornal diário com texto no IHGG para os anos 70. |
| C. Ano de 1985 | 24 | 1985 | O IHGG NÃO tem o *Diário da Manhã* de 1985. |
| D. 1980–99 com edição do *Diário da Manhã* por perto | 43 | 1989 (8), 1994 (8), 1993 (5), 1999 (4) e outros | A varredura automática não achou trecho específico. Leitura visual página a página (OCR ruim) pode render algo. |
| E. 1980–99 sem edição do *Diário da Manhã* em ±7 dias | 70 | 1986 (28), 1995 (15), 1984 (13), 1993 (5), 1994 (5) | Buracos no acervo do IHGG. |

## Caminhos sugeridos (do mais para o menos promissor)
1. **Grupo D (43):** abrir os PDFs do *Diário da Manhã* de D-1 a D+2 e LER visualmente a página de esporte, já que o OCR falhou. URL: `https://hemeroteca.ihgg.org/publicacoes/DIARIO_DA_MANHA/AAAA/MM/DIARIO_DA_MANHA_AAAA_MM_DD.pdf`.
2. **Anos 1986, 1995 e 1984 (grupo E) e 1985 (grupo C):** procurar OUTROS jornais goianos do período. Por exemplo, o *O Popular* (acervo próprio?), o *Correio Braziliense* (BN, com CAPTCHA) e jornais do interior no IHGG (Anápolis, Itumbiara, Jataí), que cobrem os jogos do Goiás FORA de Goiânia.
3. **Brasileiro dos anos 70–80 (grupo B):** revista *Placar* (Google Books tem edições completas) e o *Jornal dos Sports* na BN (o usuário baixa o PDF): as fichas de jogos do Brasileiro trazem "Local".
4. **Torneio Início (grupo A):** jornais da semana do torneio (o anúncio pré-jogo costuma dizer "no Estádio da Av. Paranaíba/Olímpico"), com o usuário baixando PDFs da BN quando necessário.
5. **1976 (20 jogos):** procurar qualquer jornal goiano de 1976 com cobertura esportiva (IHGG, BN, arquivos de clubes).

## Formato de entrega de cada confirmação
```
DATA | MANDANTE PLACAR VISITANTE | ESTÁDIO (como na fonte) | CIDADE | FONTE (jornal, edição, página) | URL | TRECHO LITERAL | CONFIANÇA
```
Depois, atualize: confirmadas N/2102 = X%, UNKNOWN restantes, o que foi tentado sem sucesso e por quê.
