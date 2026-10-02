# Roteiro de pesquisa — Fase 4 da auditoria da Arena do Goiás (2026-10-01)

Cole o bloco abaixo na ferramenta de pesquisa, com navegação na web ligada. Traga a resposta para conferência antes de aplicar.

Contexto: fases 1 a 3 aplicadas (migrations 20261001010000, 20261001020000, 20261001030000). Estas são as pendências que sobraram. Ficam FORA deste prompt (decisões do usuário, não pesquisa): regra de camisa antes de 2008 (camisas de Amaral, Ramón e Dill), fotos, clube formador e o que fazer com os registros vazios de Hugo/Júlio César/Marcão/Welliton no "Quem Vestiu o Manto".

---

```
Estou validando o banco de jogadores de um app do Goiás Esporte Clube (Goiânia-GO). Uma rodada anterior de pesquisa já resolveu quase tudo; sobraram os casos abaixo, em que as fontes divergem ou a identidade não fechou. Quero evidência NOVA e verificável. "Sem fonte" é uma resposta aceitável; chute não é.

REGRA NOVA E OBRIGATÓRIA
- TODA afirmação precisa de URL. A rodada anterior veio sem links e eu não consegui aproveitar metade dela. Resposta sem URL = descartada.
- Se a fonte é impressa/digitalizada (jornal, revista, súmula em PDF), dê o link da página digitalizada e a edição/página.

REGRAS
- Nunca invente, estime ou complete por lógica ("ele era titular naquela época", "o estádio habitual era X", "pela posição ele devia ser..."). Sem fonte: "sem fonte".
- Prioridade: 1) Goiás EC (site/redes/acervo), CBF (súmulas, BID, sistema de competições), Federação Goiana; 2) jornais da época (Hemeroteca Digital da Biblioteca Nacional, acervos de O Popular, Folha, Estadão, O Globo, Jornal dos Sports, Placar); 3) RSSSF, Futebol80, ogol/zerozero, Wikipédia — só como apoio, nunca contra 1 ou 2.
- Wayback Machine vale (link arquivado + data da captura).
- Se duas fontes boas divergirem e não houver terceira, NÃO escolha: traga os dois valores com as URLs.
- Confirme identidade por nome completo + data de nascimento para não misturar homônimos.
- Para cada item eu digo o que JÁ foi visto. Não me devolva essas mesmas fontes como novidade.

FORMATO DA RESPOSTA
Uma tabela por item: campo | valor encontrado | URL | data/edição da fonte | tipo (oficial / jornal / base estatística) | observação.
No fim: lista "sem fonte" com o que não foi resolvido.

=== PRIORIDADE 1 — partidas ===

1) GOIÁS 3 x 0 SANTOS — Brasileirão 2003 (técnico Cuca), Serra Dourada.
   Divergência de DATA: uma pesquisa disse 29/11/2003 (sábado); o ogol registra 30/11/2003 16:00 (domingo), "Rodada 44".
   Quero: data exata pela súmula da CBF, tabela oficial do Brasileirão 2003 ou jornal do dia seguinte. A escalação já está confirmada; só falta a data.

2) GOIÁS 4 x 2 ATLÉTICO-PR — Brasileirão 2005, 13/11/2005, Serra Dourada (técnico Geninho).
   Divergência na ESCALAÇÃO: uma pesquisa listou André Leone como titular; o ogol lista Luciano Almeida (e não André Leone). Os outros 10 batem: Harlei, Júlio Santos, Jadílson, Danilo Portugal, Cléber (Goiano), Paulo Baier, Rodrigo Tabata, Romerito, Souza, Roni.
   Quero: súmula da CBF ou ficha técnica de jornal (O Popular, Folha de 14/11/2005 etc.) dizendo quem foi titular — André Leone ou Luciano Almeida.

3) ESTÁDIO de três jogos (hoje cada um tem uma fonte só):
   a) Goiás 6 x 1 Fluminense — 12/10/2003 — Brasileirão (uma pesquisa disse Serra Dourada).
   b) Newell's Old Boys 0 x 0 Goiás — 22/03/2006 — Libertadores (uma pesquisa disse El Coloso del Parque).
   c) Vasco 3 x 2 Goiás — 24/10/2013 — quartas da Copa do Brasil (o ogol diz Maracanã).
   Quero uma segunda fonte para cada estádio.

=== PRIORIDADE 2 — dados de jogadores com fontes divergentes ===

4) DALTON — Dalton Gomes de Araújo, nasc. 13/11/1963, Goiás 1989–1992.
   Posição principal no Goiás diverge: uma pesquisa disse VOLANTE (com lateral-esquerdo como improviso); o ogol diz LATERAL-DIREITO; nosso banco tem LATERAL-ESQUERDO (ele jogou de LE na final da Copa do Brasil de 1990).
   Quero: como ele era escalado/descrito na maioria dos jogos do Goiás (fichas técnicas de 1989–1992, reportagens da época). Diga quantas fichas viu e em qual posição em cada uma.

5) GUSTAVO — Gustavo Ratunde de Carvalho, lateral-direito, Goiás 2002–2004.
   a) Ano do PRIMEIRO JOGO OFICIAL pelo Goiás: o ogol mostra 7 jogos em 2002; nosso banco tem 2003. Quero a 1ª partida oficial com data e adversário.
   b) Data de nascimento: 01/03/1980 (ogol) × 01/09/1980 (outra base). Quero CBF/BID ou documento do clube.

6) RENATO SILVA — Renato Assis da Silva, zagueiro, nasc. 26/07/1983, Goiás 2002–2004.
   Ano do PRIMEIRO JOGO OFICIAL pelo Goiás: 2002 (ogol: 5 jogos) × 2003. Quero a 1ª partida oficial com data e adversário.

7) EVANDRO — Evandro Gama do Nascimento Alexandre, nasc. 09/12/1970, Goiás 1992–1996 (CBF ID histórico 104812).
   Quero a data e o adversário do PRIMEIRO JOGO OFICIAL pelo Goiás (há indício de jogos já em 1992).

8) TADEU — Tadeu Antônio Ferreira, goleiro, nasc. 04/02/1992, no Goiás desde 2019; 400º jogo em 28/08/2026.
   Gols pelo Goiás: fontes contemporâneas ao 400º jogo falam em 13 (todos de pênalti); a soma por temporada do ogol (2024=4, 2025=7, 2026=3) dá 14.
   Quero: lista dos gols com data, adversário e competição (para contar de verdade), de preferência pelo site/redes do Goiás ou súmulas. Diga se algum deles foi em disputa de pênaltis (que não conta como gol) ou em jogo amistoso.

=== PRIORIDADE 3 — identidades não fechadas ===

9) MICHAEL (1999) — titular na final da Série B 1999, Goiás x Santa Cruz, 12/12/1999 (substituído por Tiago Fraga). NÃO é Michael Richard Delgado de Oliveira (2017–2019).
   Quero nome completo e data de nascimento (súmula da final, ficha de jornal, BID/CBF).

10) JOSUÉ (1987–1991) — meia, titular na final da Copa do Brasil de 1990 (Goiás 0x0 Flamengo, 07/11/1990). Perfil no ogol: ogol.com.br/jogador/josue/231317. NÃO é Josué Anunciado de Oliveira (1997–2004).
    Quero nome completo e data de nascimento.

11) MARCÃO — quatro casos ainda sem identidade civil (perfis do ogol entre parênteses):
    a) Marcão 1993 (ogol.com.br/jogador/marcao/349)
    b) Marcão 1998–1999 — há indício de que era goleiro (ogol.com.br/jogador/marcao/88925)
    c) Marcão 2000–2001 (ogol.com.br/jogador/marcao/179428)
    d) Marcão 2018–2019 (ogol.com.br/jogador/marcao/218687)
    Para cada um: nome completo, nascimento, posição. Já resolvidos (não repetir): Marcos Alberto Skavinski (2010–11), Marcos Assis de Santana (2016), Marcos Antônio Almeida Silva (2024–25).

12) HUGO "2010" — uma pesquisa identificou Hugo Guimarães Silva Santos Almeida (nasc. 06/01/1986), mas achou a passagem pelo Goiás em 2011, não 2010; o ogol o lista no elenco de 2010 (ogol.com.br/jogador/hugo/97486). Em qual(is) temporada(s) ele de fato jogou pelo Goiás? Quero partidas com data.
```
