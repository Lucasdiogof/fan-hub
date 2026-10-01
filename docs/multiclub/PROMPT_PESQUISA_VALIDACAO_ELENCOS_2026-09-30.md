# Roteiro de pesquisa (outra conta) — validação de elenco e carreiras: RB Bragantino + Vila Nova FC

Cole tudo abaixo na ferramenta de pesquisa (com navegação na web ativada). Quando ele terminar, traga a resposta de volta pra eu aplicar no banco real — eu não aceito a palavra dele sozinha, vou conferir contra fonte antes de aplicar qualquer coisa.

---

## Contexto

Você vai pesquisar dados reais de futebol pra um app multi-clube (cada clube é um "flavor" separado do mesmo app). Preciso validar e completar dados de **dois clubes**: **Red Bull Bragantino** e **Vila Nova Futebol Clube (Goiânia-GO)**. São duas tarefas independentes (clubes diferentes), mas seguem exatamente a mesma metodologia — descrita abaixo.

**Regra de ouro, inegociável: NUNCA invente, estime ou arredonde um dado.** Se não achar uma fonte real que confirme um número ou fato específico, deixe em branco e diga explicitamente "não encontrei fonte" — nunca preencha com um palpite plausível. Isso vale até quando parecer "óbvio" (ex.: não assuma que um jogador jogou X partidas só porque esteve no elenco X temporadas).

**Prioridade de fonte quando duas fontes divergem** (regra aprendida numa rodada de validação que acabamos de fazer pro Goiás, onde agregadores como ogol.com.br erraram a altura de dois jogadores):
1. Site oficial do clube.
2. ogol.com.br ou Wikipédia (o que tiver o dado mais completo/recente).
3. Outras fontes (besoccer, fbref, sofascore, sites de torcida) só servem como DESEMPATE/corroboração — nunca confie numa fonte de torcida/agregador genérico sozinha contra o oficial.

Se duas fontes boas divergirem e você não conseguir desempatar com uma terceira, **não escolha um lado** — reporte os dois valores e qual fonte disse o quê, e eu decido.

**Achado importante da rodada anterior, generalize esse cuidado:** sites agregadores às vezes têm um bug sistemático — um deles (não vou dizer qual, pra não te enviesar) estava marcando "pé direito" errado pra vários jogadores canhotos de verdade, sempre no mesmo campo. Se um campo específico de uma fonte parecer suspeito (ex.: todo mundo canhoto do elenco aparece como destro nessa fonte), desconfie do CAMPO inteiro daquela fonte, não só do jogador individual — confirme com uma segunda fonte antes de aceitar.

---

## Tarefa 1 — Elenco atual (squad_members)

Pra cada um dos dois clubes, eu já tenho uma lista de jogadores no banco (abaixo). Preciso que você:

1. **Confirme que a lista bate com o elenco profissional ATUAL de verdade** — comparando contra a página oficial de elenco do clube (não contra uma página de agregador que lista "todo mundo que jogou na temporada", que pode incluir jogador já transferido ou emprestado pra outro clube — isso já nos confundiu uma vez. Sempre confirme usando a página de elenco do SITE OFICIAL do clube como critério final de "quem está no time agora").
2. Pra cada jogador, me dê (quando a fonte tiver): **nome completo, data de nascimento, nacionalidade, altura (cm), pé preferencial (destro/canhoto), posição**.
3. Se achar um jogador no elenco oficial que NÃO está na minha lista (contratação nova que eu ainda não registrei), me avise com nome completo + número da camisa + posição.
4. Se algum jogador da minha lista não estiver mais no elenco oficial (foi embora, rescindiu, etc.), me avise.

### Elenco atual — RB Bragantino (30 jogadores, projeto Supabase separado)
Cleiton, Guzmán Rodríguez, Eduardo Santos, Alix Vinícius, Fabinho, Gabriel Girotto, Eric Ramires, Sasha, Pitta, Fernando, Vanderlan, Pedro Henrique, Nacho Sosa, Gustavo Marques, Vinicinho Pereira, Tiago Volpi, Rodriguinho, Lucas Barbosa, Gustavo Neves, Agustín Sant'Anna, Davi Gomes, Juninho Capixaba, Henry Mosquera, Herrera, Andrés Hurtado, Matheus Fernandes, Fabrício, Cauê, Gustavo Reis, Marcelinho.

Site oficial: `redbullbragantino.com` (procure a página de elenco/plantel). **21 destes 30 estão com altura E pé preferencial em branco no nosso banco** — esse é o maior ganho possível aqui.

### Elenco atual — Vila Nova FC (31 jogadores)
Dalberson, Gabriel Átila, Helton Leite, Anderson Jesus, Breno Bora, Douglas Mendes, Jonathan Costa, Samuel, Tiago Pagnussat, Dudu, Enzo Bizzotto, Higor Meritão, João Vieira, Nathan Camargo, Willian Maranhão, Hayner, Higor Luiz, Igor Cariús, Willian Formiga, Dodô, Marquinhos Gabriel, André Luís, Bruno Xavier, Dellatorre, Emerson Urso, Everton Galdino, Gustavo Puskas, Janderson, Lincoln, Rafa Silva, Ryan.

Site oficial: `vilanovafc.com.br/elenco-profissional`. **Esse elenco já foi revisado recentemente e está com os dados biográficos OK** — aqui a prioridade real não é essa Tarefa 1, é a Tarefa 2 abaixo.

---

## Tarefa 2 — "Adivinhe pela Carreira" (career_players): histórico de clubes de cada jogador

Esse é um jogo do app: mostra a carreira (clube por clube, com período, jogos e gols) de um jogador e o usuário tenta adivinhar quem é. Preciso da carreira completa de cada atleta, temporada a temporada, com fonte.

**Metodologia que funcionou muito bem na rodada anterior (use exatamente essa):**
1. Ache o perfil do jogador no **ogol.com.br** (`ogol.com.br/jogador/<nome>/<id>`).
2. Abra a aba "HISTÓRICO" — ela traz uma tabela ano a ano: Temporada / Equipe / Jogos / Gols / Assistências. Em alguns casos o jogador também tem uma segunda seção "HISTÓRICO COMO TREINADOR" depois (se ele virou técnico) — ignore essa parte, você quer só a carreira como JOGADOR.
3. Some as temporadas que caem dentro de cada "passagem" pelo clube (ex.: se o jogador ficou no Clube X de 2018 a 2020, some os jogos/gols de 2018+2019+2020).
4. **Cuidado com emboscada de temporada europeia/asiática**: times fora do Brasil usam temporada tipo "2019/20" (não "2019"), não confunda com o ano brasileiro.
5. **Cuidado com empréstimo dentro do mesmo clube-mãe**: o ogol mostra assim: `Time Emprestado(E)\n[Clube Dono]`. O jogo que ele jogou foi pelo TIME EMPRESTADO, não pelo clube dono — mas registre de quem foi emprestado.
6. Quando a tabela não trouxer jogos/gols pra uma temporada específica (aparece "-"), não invente — deixe em branco e diga "sem dado nessa temporada".

### RB Bragantino — carreiras pendentes (93 de 131 passagens de clube sem jogos/gols, de 30 jogadores)
Esse é o pacote com MAIS lacuna dos dois clubes. Jogadores (alguns são ídolos/ex-jogadores do Bragantino, não necessariamente o elenco atual — são os escolhidos pro jogo de adivinhação):
Marcelo Martelotte, Nivaldo (Penafiel), e outros ~28 nomes que estão em `supabase/bragantino_career_players.sql` no repo (se você tiver acesso ao repo; senão me peça a lista completa que eu colo aqui). Pra cada um, preciso da carreira COMPLETA clube a clube com jogos/gols, não só a passagem pelo Bragantino.

### Vila Nova FC — ATENÇÃO: esse pacote está com um placeholder, não é a tarefa real ainda
O jogo "Adivinhe pela Carreira" do Vila Nova hoje está usando os **30 jogadores do elenco ATUAL** como se fossem os "jogadores a adivinhar" — isso foi uma decisão temporária só pra não travar o lançamento, mas não faz sentido pro jogo de verdade (não tem graça adivinhar o titular que já está estampado na camisa 10 do time hoje). **A tarefa de verdade é: me dê uma lista de ~20-30 JOGADORES HISTÓRICOS/ÍDOLOS do Vila Nova** (aposentados ou que já passaram por lá, de preferência com carreira interessante — passagem por clube grande, seleção, etc. — pra ficar um jogo divertido), cada um com:
- Nome completo
- Posição
- Carreira clube a clube, temporada a temporada, jogos e gols (mesma metodologia da Tarefa 2 acima)

Pode usar o Futebol de Goyaz (`futeboldegoyaz.com.br`) além do ogol pra achar nomes históricos do Vila Nova — é o banco de dados mais completo de futebol de Goiás.

---

## Formato da resposta

Pra eu conseguir aplicar isso direto, me devolva em **JSON**, um objeto por jogador, assim:

```json
{
  "id": "slug_do_jogador_em_snake_case",
  "nome_completo": "...",
  "fonte_elenco_atual": "URL da página onde confirmou que ele está no elenco atual (só Tarefa 1)",
  "dados_biograficos": {
    "nascimento": "AAAA-MM-DD ou null",
    "nacionalidade": "...",
    "altura_cm": 180,
    "pe_preferencial": "Destro | Canhoto | null"
  },
  "carreira": [
    {
      "periodo": "2018-2020",
      "clube": "Nome do Clube",
      "jogos": 45,
      "gols": 3,
      "emprestado": false,
      "fonte": "URL do ogol ou outra fonte usada",
      "obs": "qualquer nota relevante, ex. 'temporada 2019 sem dado na fonte'"
    }
  ]
}
```

Nunca omita o campo `fonte` — preciso saber de onde veio cada número pra eu conferir antes de aplicar.

---

## O que NÃO fazer

- Não escreva direto em nenhum banco de dados — você não tem acesso, e mesmo que tivesse, não é sua tarefa.
- Não resuma/arredonde ("~40 jogos") — ou é o número exato que a fonte dá, ou é null.
- Não misture dado de um jogador homônimo (nome comum) — se tiver dúvida entre dois jogadores com o mesmo nome, diga isso explicitamente em vez de escolher um.
- Não precisa reportar progresso incremental — pode trabalhar até o fim e me mandar tudo de uma vez, ou em lotes por clube se for mais prático pra você.
