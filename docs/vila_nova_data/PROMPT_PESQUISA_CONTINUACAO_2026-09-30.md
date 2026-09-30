# Roteiro de continuação da pesquisa — pacote Vila Nova v1.2 (2026-09-30)

> Cole tudo abaixo da linha na ferramenta de pesquisa. Ainda NÃO enviado — o texto foi registrado aqui por engano/registro; nenhum ZIP novo chegou no Desktop em resposta a ele até 2026-09-30. Quando o usuário mandar, aguardar o ZIP de volta e auditar pela receita do §7 do `HANDOFF_ESTADO.md` antes de aplicar.

---

Continue o trabalho no pacote **Vila Nova Fan Hub v1.2** a partir do estado atual.

NÃO reinicie pesquisas já concluídas e NÃO substitua dados confirmados por inferências.

Quero fechar as pendências abaixo, atualizar os arquivos reais do pacote e entregar um novo checkpoint consistente.

# 1. CORRIGIR OS DOIS RIO BRANCO

Existem dois clubes capixabas diferentes e eles NÃO podem ser confundidos.

## Copa do Brasil 2025

Partida:

```text
13/03/2025
Vila Nova 6 x 0 Rio Branco
Copa do Brasil — 2ª fase
Serra Dourada
```

O adversário correto é:

```text
Rio Branco-VN
Rio Branco Futebol Clube
Venda Nova do Imigrante-ES
```

NÃO é o Rio Branco Atlético Clube de Cariacica.

O próprio Vila Nova publicou:

```text
VILA NOVA F.C. X RIO BRANCO VN-ES
```

Corrija qualquer registro do pacote que esteja identificando esse jogo como:

```text
Rio Branco-ES
Rio Branco AC
Rio Branco de Cariacica
```

Faça a correção também nos IDs/referências se necessário, sem criar duplicatas.

## Copa Verde 2026

ATENÇÃO: aqui ocorre o contrário.

O jogo de 24/03/2026:

```text
Rio Branco 1 x 0 Vila Nova
Kleber Andrade
Cariacica-ES
Copa Verde / Copa Centro-Oeste
```

é realmente contra:

```text
Rio Branco-ES
Rio Branco Atlético Clube SAF
Cariacica-ES
```

Esse NÃO deve ser alterado para Rio Branco-VN.

Audite todos os `Rio Branco` do dataset para garantir que os dois clubes estejam separados corretamente.

---

# 2. `calendar_year` DOS JOGOS CDB 2026

Nos três registros:

```text
vn_official_cdb_2026_f*
```

o campo está incorretamente serializado como:

```json
"calendar_year": "2026"
```

Corrigir para número:

```json
"calendar_year": 2026
```

Audite o arquivo inteiro para verificar se existem outros anos numéricos armazenados como string.

Não altere IDs sem necessidade.

---

# 3. HONORS — CAMPEONATO GOIANO

A fonte oficial do Vila Nova registra:

```text
16 títulos do Campeonato Goiano
```

Temporadas:

```text
1961
1962
1963
1969
1973
1977
1978
1979
1980
1982
1984
1993
1995
2001
2005
2025
```

O dado oficial continua sendo a fonte canônica.

### IMPORTANTE SOBRE O CONFLITO

Foi identificado anteriormente um material/revisão da Wikipedia contabilizando 17.

Porém NÃO registre de forma falsa que a Wikipedia atual necessariamente continua com 17.

Primeiro confira a revisão/fonte já salva no pacote.

Se aquela fonte/revisão realmente mostrar:

```text
Wikipedia = 17
Oficial Vila Nova = 16
```

registre em `conflicts` algo conceitualmente como:

```json
{
  "topic": "Campeonato Goiano titles",
  "official_value": 16,
  "alternate_value": 17,
  "resolution": "OFFICIAL_SOURCE_WINS"
}
```

mantendo 16 no dado canônico.

Se a Wikipedia atual já estiver em 16, preserve o conflito apenas como histórico se houver URL/revisão que sustente os 17.

Nunca invente conflito.

---

# 4. VENUES — ARENA NICNET / SANTA CRUZ

Fundir:

```text
vn_venue_arena_nicnet
```

em:

```text
vn_venue_santa_cruz_ribeirao
```

A Arena Nicnet corresponde ao complexo/naming rights associado ao Estádio Santa Cruz do Botafogo-SP em Ribeirão Preto.

A partir deste pacote, use somente:

```text
vn_venue_santa_cruz_ribeirao
```

para partidas disputadas nesse estádio.

Faça:

- migração das referências;
- remoção da duplicata;
- atualização dos aliases/naming rights;
- preservação dos nomes históricos quando útil.

Algo conceitualmente como:

```json
{
  "id": "vn_venue_santa_cruz_ribeirao",
  "canonical_name": "Estádio Santa Cruz",
  "aliases": [
    "Arena Nicnet",
    "Arena Nicnet Eurobike",
    "Estádio Santa Cruz/Arena Nicnet"
  ]
}
```

Não duplique venue por naming rights.

---

# 5. ARENA — FECHAR O GAP ANTIGO

Essa pendência existe desde o v0.6 e NÃO deve continuar sendo empurrada.

Quero:

```text
21 jogadores
12 técnicos
```

## Perfis

Para cada perfil, basta:

- nome;
- período no Vila;
- função/posição;
- 4–6 evidências de ESTILO.

NÃO precisa:

- pergunta de quiz;
- nota;
- score;
- texto inventado;
- atributo sem fonte.

### O que significa evidência de estilo

Exemplos:

```text
artilheiro
bom jogo aéreo
velocidade
marcação forte
liderança
especialista em bolas paradas
drible
jogo físico
organização defensiva
time ofensivo
transição rápida
posse de bola
```

Mas cada característica deve possuir evidência textual/fonte.

Não transforme estatística em característica subjetiva sem suporte.

## Técnicos

Total:

```text
12
```

Priorize técnicos historicamente relevantes.

Registrar:

- nome;
- períodos;
- função;
- estilo;
- 4–6 evidências.

## Jogadores

Total:

```text
21
```

Boa distribuição por épocas.

Não concentrar quase tudo em 2020–2026.

---

# 6. CARREIRAS HISTÓRICAS

Hoje há carreiras atuais demais.

Quero:

```text
15 carreiras HISTÓRICAS
```

Substitua as atuais sempre que necessário.

Priorize atletas associados à história do Vila e distribua pelas décadas.

Não transforme `career` em biografia genérica.

Registrar trajetória relevante ao clube:

- chegada;
- período;
- posição;
- campanhas;
- conquistas;
- saída/retorno quando relevante.

### Túlio

Túlio deve permanecer:

```text
REVIEW
```

Não promover para confirmado apenas pela fama ou por associação geral ao futebol goiano.

Só fechar quando a evidência específica exigida pela feature estiver satisfeita.

---

# 7. ESCALAÇÕES HISTÓRICAS

Precisamos de:

```text
>= 5 escalações anteriores a 2000
```

Escalação significa formação real de partida, não elenco da temporada.

Cada uma precisa ter:

- data;
- adversário;
- competição;
- titulares;
- fonte confiável.

Preferir partidas históricas/relevantes, mas a confiabilidade da escalação vem antes da importância.

Não inventar formação para completar meta.

---

# 8. CARTAS "QUEM VESTIU O MANTO?"

Precisamos de pelo menos:

```text
>= 10 cartas
```

com jogador cuja:

```text
estreia pelo Vila < 2005
```

A estreia precisa ser sustentada por fonte.

Não vale usar jogador moderno apenas porque teve passagem antiga por outro clube.

O corte é estreia pelo VILA NOVA.

---

# 9. PARCEIROS 2026 — `data/partners.json`

Essa parte exige auditoria nova.

Hoje aparentemente existem somente:

```text
FatalFans
Volt Sport
```

Isso está incompleto.

Quero mapear os patrocinadores/parceiros efetivamente presentes na temporada **2026**, especialmente no uniforme profissional.

## Patrocinador máster

NÃO prolongar a GingaBet automaticamente.

A GingaBet foi anunciada em:

```text
26/02/2025
```

com contrato de:

```text
12 meses
```

Portanto, o contrato anunciado originalmente chegava aproximadamente ao fim em fevereiro de 2026.

### Evidência atual

A pesquisa já encontrou:

```text
BET DÁ SORTE
```

como patrocinador máster do Vila Nova em 2026.

Foi anunciado em março de 2026 para ocupar o principal espaço da camisa durante a temporada.

Então, salvo evidência oficial posterior em sentido contrário:

```text
Bet Dá Sorte
tier = MASTER
placement = FRONT_MAIN / CHEST_MAIN
season = 2026
```

Confirme novamente com fonte/foto de 2026 antes de persistir.

---

# 10. FATALFANS

FatalFans é patrocinadora real de 2026.

Contrato anunciado em março de 2026 com duração de um ano.

A evidência mais específica de uniforme aponta:

```text
placement = dentro da numeração da camisa
```

Portanto NÃO classifique automaticamente como MASTER só porque algumas matérias usaram essa palavra.

Há evidência visual e comercial de Bet Dá Sorte no principal espaço frontal.

Trate isso como possível conflito editorial entre matérias.

A princípio:

```text
FatalFans
tier = OFFICIAL
category = conteúdo/plataforma digital
placement = NUMBER
since = 2026-03
```

Use nome/categoria compatíveis com o schema atual.

Não aplicar julgamento editorial sobre o ramo da empresa.

---

# 11. VOLT SPORT

Volt Sport é a fornecedora de material esportivo.

Registrar como:

```text
tier = SUPPLIER
category = sportswear
placement = KIT_SUPPLIER
```

Confirmar contrato/período vigente.

---

# 12. AUDITORIA COMPLETA DO UNIFORME 2026

Não copie cegamente a lista de 2025.

Use:

- fotos oficiais de jogos de 2026;
- Vila Nova;
- CBF;
- parceiros;
- veículos confiáveis;
- fotos em boa resolução.

Audite:

```text
frente
peito
ombros
mangas
costas superiores
costas inferiores
número
calção frente
calção costas
meião
fornecedor
```

### Marcas que já aparecem como fortes candidatas e DEVEM ser verificadas

```text
Bet Dá Sorte
FatalFans
Volt Sport
Unimed Goiânia
GAV Resorts
Eternit
Tintas Luztol
Arroz Cristal
UniCesumar
Grupo F8
Fórmula Distribuidora
BCJ
Oficial Sport
Cash Cash
```

Essa lista é de investigação, NÃO de confirmação automática.

Podem existir:

- parceiros que saíram;
- parceiros que entraram no meio do ano;
- marcas apenas de treino;
- propriedades comerciais sem presença no uniforme;
- mudança de placement;
- patrocinadores antigos ainda presentes em bases desatualizadas.

### Unimed

Há confirmação pública de renovação com o Vila Nova para a temporada 2026.

Validar placement visualmente.

### GAV

Existe parceria histórica e evidência de exposição na omoplata em contratos anteriores.

Confirmar se permanece em 2026 e exatamente onde aparece.

---

# 13. SCHEMA DE `partners.json`

Para CADA parceiro confirmado quero, no mínimo:

```json
{
  "id": "...",
  "name": "...",
  "tier": "MASTER | OFFICIAL | SUPPLIER | ...",
  "category": "...",
  "url": "...",
  "logo_source_url": "...",
  "since": "...",
  "placement": "...",
  "sources": [...]
}
```

`logo_source_url` deve apontar para fonte legítima da marca.

Não:

- inventar URL;
- extrair logo ruim de screenshot se houver brand asset legítimo;
- reutilizar logo de terceiros;
- assumir `since` sem fonte.

Se uma marca tiver presença confirmada em 2026 mas `since` histórico não puder ser fechado:

```text
since = null / GAP
```

conforme schema.

É preferível GAP factual a data inventada.

---

# 14. EVIDÊNCIA VISUAL POR PATROCINADOR

Quero pelo menos uma evidência de uniforme para cada placement afirmado.

Exemplo:

```text
Bet Dá Sorte
→ foto de jogo 2026 mostrando peito

Arroz Cristal
→ foto mostrando manga

FatalFans
→ foto/anúncio mostrando marca na numeração
```

Salve URL/fonte de evidência quando o schema permitir.

Se houver mudança de patrocinadores durante 2026, registre período/observação em vez de fingir que todos coexistiram o ano inteiro.

---

# 15. PASSAPORTE — PRÓXIMO LOTE

Depois de fechar as correções estruturais acima, retome o Passaporte.

Ordem obrigatória:

```text
2019
2018
2017
2016
...
1943
```

Trabalhar para trás.

NÃO voltar para temporadas já fechadas sem motivo concreto.

## Para cada partida

Confirmar principalmente:

- estádio;
- cidade;
- adversário correto;
- competição;
- data;
- aliases do estádio.

Prioridade para fonte de partida individual.

Não inferir estádio apenas porque "o Vila normalmente mandava ali".

---

# 16. MÉTODO DO PASSAPORTE

Para cada ano:

1. listar `UNKNOWN` / `REVIEW`;
2. pesquisar individualmente;
3. resolver o máximo possível;
4. registrar fonte;
5. só então avançar ao ano anterior.

Fontes úteis:

```text
site oficial Vila Nova
CBF
FGF
ge
Futebol Nacional
oGol/Zerozero
acervos de jornais
RSSSF
Hemeroteca
arquivos históricos
```

Para jogos antigos, cruzar fontes quando necessário.

Não usar agregador fraco como única prova de estádio se existir fonte melhor.

---

# 17. NÃO INVENTAR PARA BATER META

As metas:

```text
21 jogadores
12 técnicos
15 carreiras
5 escalações pré-2000
10 cartas pré-2005
```

são metas de pesquisa, NÃO autorização para preencher dado sem evidência.

Se após pesquisa exaustiva algum item ficar incompleto:

```text
REVIEW
GAP
```

e documente exatamente o que falta.

---

# 18. ENTREGA DO NOVO PACOTE

No final:

1. valide todos os JSON;
2. execute os validadores existentes;
3. confira IDs órfãos;
4. confira referências de venues;
5. confira duplicatas;
6. confira schema;
7. confira que não existe `calendar_year: "2026"`;
8. confira separação Rio Branco-VN x Rio Branco-ES;
9. confira `vn_venue_arena_nicnet` removido/migrado;
10. confira parceiros 2026;
11. confira metas da Arena;
12. informe progresso do Passaporte.

Entregar relatório objetivo:

```text
Correções concluídas
Arena
Partners 2026
Passaporte
Conflicts
GAPs restantes
Validação
Arquivos modificados
```

Inclua contagens antes/depois.

NÃO pare para me pedir autorização a cada descoberta.

Pesquise, corrija, valide e avance.
