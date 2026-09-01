# 14 — Feature Flags, Mock do Juventude e Testes de Contaminação

> Proposta — nada implementado. Esta é a ÚLTIMA fase, só depois de `08`-`13` estarem prontos de verdade. Gerado em 2026-09-01.

## Feature flags

Nem todo clube terá as mesmas funcionalidades desde o dia 1 (ex.: Sócio Torcedor real pode não existir ainda pro Juventude). Proposta: `ClubFeatureFlags` como parte do `ClubConfig` (`10_club_config.md`):

```dart
class ClubFeatureFlags {
  const ClubFeatureFlags({
    this.arenaEnabled = true,
    this.passportEnabled = true,
    this.storeEnabled = true,
    this.membershipEnabled = true,
    this.mediaEnabled = true,          // notícias + social feed
    this.liveMatchEnabled = true,
    this.rankingEnabled = true,
    this.songsEnabled = true,
    this.ticketsEnabled = true,
  });
  // ...
}
```

Consumo: telas/abas checam `sl<ClubConfig>().features.xEnabled` antes de se registrar na navegação (`GamesCubit`, `HomeShellCubit`, rotas do `app_router.dart`) — nunca um `if` espalhado tela por tela; centralizar a decisão no ponto de composição da navegação, igual ao padrão que `arena_catalog.dart` já usa pra listar jogos disponíveis (reaproveitar essa mesma ideia pra secções inteiras do app).

## Mock mínimo do Juventude — só depois de `08`-`13` prontos

Dataset de teste, não o clube completo:
- 3 partidas (`passport_matches`, `club_id='juventude'`)
- 5 jogadores (`squad_members`, `club_id='juventude'`)
- 5 questões de quiz (`quiz_questions`, `club_id='juventude'`)
- 1 desafio de cada tipo de jogo Arena que estiver habilitado nas feature flags do Juventude
- 1 produto (`club_id='juventude'` no catálogo de loja, uma vez que ele migrar de JSON local pra tabela — ver `09_supabase_migration_plan.md`)
- 1 `ClubConfig` completo (`lib/club_configs/juventude.dart`) com cores/nome/logo temporários (podem ser placeholder, não precisam ser a marca real do Juventude ainda — o objetivo aqui é provar isolamento, não lançar o app)

**Objetivo único**: provar que um build `--flavor juventude` nunca mostra dado/marca do Goiás e vice-versa. Não é o início de "montar o Juventude de verdade" — isso só acontece depois (fora do escopo desta auditoria, conforme pedido).

## Testes de contaminação entre clubes

### 1. Teste estático — grep de branding no build

Um teste (script, não `flutter test`, já que precisa inspecionar o OUTPUT do build) que roda depois de `flutter build web --flavor juventude` e faz grep no bundle gerado por strings proibidas:
```
Goiás, Goias, GOIAS, Esmeraldino, Esmeraldina, Arena Esmeraldina,
Passaporte Esmeraldino, Haile Pinheiro, goiasec.com.br, goias-1863
```
Qualquer match = falha. Mesmo teste рodado ao contrário pro build `goias` (procurando strings do Juventude, uma vez que existirem).

### 2. Teste de assets — nenhum asset do outro clube no bundle

Verificar que `build/web/assets/lib/assets/branding/` (ou equivalente) só contém arquivos do clube ativo — se a abordagem escolhida em `11_flavors_android.md §7`/`13_flavors_web.md` for "empacotar todos os clubes em todo build" (opção (a), recomendada pra começar), este teste específico não se aplica ainda — só passa a fazer sentido se/quando migrar pra opção (b) (asset por flavor de verdade).

### 3. Teste de banco — `club_id` nunca vaza entre clubes

`flutter test`/`dart test` de integração (ou um teste SQL direto no Supabase) que, autenticado como um usuário fictício do flavor Juventude, tenta:
- Ler `squad_members` filtrando só por `club_id='juventude'` e confirma que nenhuma linha com `club_id='goias'` aparece.
- Chamar `arena_record_score` com um `item_id` que só existe no `club_id='goias'` e confirma que a RPC rejeita (não deixa pontuar em cima de conteúdo de outro clube).
- Confirma que `subscribe_to_plan` só aceita `plan_id`s da tabela `membership_plans` filtrada pelo `club_id` do chamador.

### 4. Teste de config — `ClubConfig` nunca fica `null`/genérico em produção

Um teste simples garantindo que `main.dart` falha explicitamente (não cai num default silencioso) se `CLUB_ID` não for passado ou não bater com nenhum `ClubConfig` conhecido — evita o cenário de um build de produção acidentalmente subir com branding/config errados.

## Ordem de execução desta fase

1. `08`+`09`+`10` implementados de verdade (contrato, Supabase, ClubConfig) — pré-requisito, não pular.
2. Feature flags no `ClubConfig`.
3. Mock mínimo do Juventude (dado de teste, não o clube completo).
4. Os 4 testes de contaminação acima, rodando em CI a partir daqui pra frente (qualquer novo clube precisa passar por eles antes de qualquer build de produção).
5. **Só então** — fora do escopo desta auditoria — pesquisar/importar o dataset completo do Juventude.
