# Documentação de arquitetura — `fan-hub`

Mapa técnico consolidado do projeto: arquitetura, features, domínios, fluxos, backend, navegação, multi-clube, segurança, testes, onboarding e débito técnico. Foi produzido a partir de uma análise **estática** do código (grafo de conhecimento + auditorias de leitura) no commit `e90de17`, em 2026-10-02.

> Esta pasta **não substitui** a documentação existente; ela a indexa e a confronta com o código. Onde algo já está correto em outro lugar, há link em vez de cópia: `README.md` (visão de produto), `docs/multiclub/*` (≈60 relatórios históricos do rollout multi-clube) e `supabase/MIGRATIONS.md` (**parcialmente desatualizado**, ver [technical-debt.md](technical-debt.md) M9).

## Índice

| Documento | Para quê |
|---|---|
| [architecture-overview.md](architecture-overview.md) | Visão geral, diagrama de contexto, stack, mapa do repositório, camadas, arquivos centrais |
| [feature-map.md](feature-map.md) | As 18 features, o que cada uma usa no backend e a matriz de capabilities por clube |
| [domain-map.md](domain-map.md) | Os 8 domínios de negócio, seus fluxos e um glossário |
| [data-flow.md](data-flow.md) | 14 fluxos rastreados no código (inicialização, auth, push, Arena, loja, ingressos, pipelines de dados…) com Mermaid |
| [backend-integrations.md](backend-integrations.md) | Supabase (migrations, tabelas, RPCs, RLS, Edge Functions), Cloudflare Worker, Firebase, Sentry, CI e tooling |
| [navigation.md](navigation.md) | `go_router`, ordem do `redirect`, rotas, deep links, riscos de `state.extra` |
| [multi-club.md](multi-club.md) | Como os 3 clubes compartilham código, e os vazamentos entre clubes |
| [security-overview.md](security-overview.md) | Achados de segurança estática por severidade |
| [testing-overview.md](testing-overview.md) | O que existe de teste, o que falta e como rodar |
| [onboarding.md](onboarding.md) | Guia para novos desenvolvedores (setup, roteiro, tarefas, armadilhas) |
| [technical-debt.md](technical-debt.md) | Débito técnico (crítico/alto/médio/baixo), acoplamento, quick wins e mudanças de alto risco |

**Por onde começar:** quem chega agora → [onboarding.md](onboarding.md). Quem vai decidir prioridades → [technical-debt.md](technical-debt.md) (§1 e §9). Quem mexe em segurança → [security-overview.md](security-overview.md) (S-01).

## Como esta análise foi feita

1. **Grafo de conhecimento** (`/understand`): 1.414 arquivos em 65 lotes → 2.783 nós, 8.653 arestas, 10 camadas, tour de 15 passos. As arestas de `imports` (4.801) vêm de um resolvedor próprio (`.ua/custom-import-resolver.cjs`), porque o do plugin falhou para Dart/TypeScript.
2. **Grafo de domínio** (`/understand-domain`): 8 domínios, 18 fluxos, 61 passos.
3. **Auditorias de leitura** (arquitetura, backend, multi-clube, segurança, testes/código morto) e **cálculos determinísticos** sobre o grafo (ciclos, fan-in, blast radius, violações de camada).
4. **Verificação cruzada:** as afirmações mais importantes foram reconferidas diretamente no código antes de entrar aqui. Durante esse processo foram **corrigidos** erros das auditorias automáticas (por exemplo, o número de rotas, o projeto Firebase único, a existência do script `check_app_club_enforced.mjs`, e o fan-in que contava importações de testes).

Arquivos gerados (locais, **ignorados pelo git** via `.git/info/exclude`): `.ua/knowledge-graph.json`, `.ua/domain-graph.json`, `.ua/meta.json`, `.ua/fingerprints.json`.

## Convenções dos documentos

- **CONFIRMADO** = lido diretamente no código/SQL. **POSSÍVEL** = depende de estado que não foi visível.
- **NÃO VERIFICADO** = não foi lido ou depende de execução/banco vivo. Nunca é apresentado como fato.
- Caminhos são relativos à raiz do repositório. Segredos e identificadores de projeto **não** são reproduzidos.

## Limitações

- **Análise estática.** Nada foi executado contra bancos, Cloudflare ou Firebase; **o estado vivo dos três projetos Supabase não foi verificado** (principalmente grants e se os scripts de hardening foram aplicados).
- **Cobertura de testes sem medição.** Os números são "tem teste direto" por import/nome, não porcentagem de linhas.
- **Resumos genéricos em `tooling/`.** Os nós de função/classe dos lotes 60–65 (scripts de `tooling/`) têm resumos em modelo, não escritos um a um. A estrutura e as dependências estão corretas, a semântica por função é rasa.
- **Grafo de domínio raso.** Derivado de nomes e resumos; foi complementado manualmente em [domain-map.md](domain-map.md).
- **Working tree.** O grafo corresponde ao commit `e90de17` e ao working tree no momento do scan; o repositório recebeu outros commits e arquivos durante a sessão (por exemplo a migration `20261002030000_manto_goias_academy_club_rule.sql`, ainda *untracked*, não é parte do commit).
- Arquivos fora do escopo do scan: `lib/l10n/app_localizations.dart` (gerado, não versionado), scripts `.ps1`, JSONs de dados em `src/social/data/`.

## Como atualizar

```text
/understand                 # atualização incremental do grafo (usa .ua/meta.json)
/understand-dashboard       # abre o dashboard interativo
```

Se o resolvedor de imports do plugin falhar de novo, rode `node .ua/custom-import-resolver.cjs` antes do passo de *merge* (gera `.ua/intermediate/batch-66.json`). Depois de mudanças grandes, revise os números citados nestes documentos (contagens de arquivos, rotas, testes e fan-in).

> **Cuidado ao reproduzir auditorias:** os scripts `tooling/multiclub/audit_*.mjs` gravam em `data_export/goias/player_reconciliation/` e sujam o working tree.
