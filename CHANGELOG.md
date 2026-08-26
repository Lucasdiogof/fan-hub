# Changelog

Histórico de funcionalidades do app, da mais recente pra mais antiga. Commits automáticos de sincronização de conteúdo (posts do X, etc.) não entram aqui — só o que muda a experiência do app.

## 2026-08-25

- **Sócio Esmeralda**: FAQ (33 perguntas) e Regulamento migrados pro Supabase — conteúdo agora editável pelo dashboard sem precisar de um novo build do app, com fallback local se a tabela estiver vazia ou sem rede.
- **Arena Esmeraldina**: catálogos de Adivinhe o Jogador, Adivinhe a Escalação e Quem Vestiu o Manto migrados pro Supabase, no mesmo padrão do Quiz.
- **Jogos**: lista de partidas agora mostra o placar parcial e um indicador "ao vivo" enquanto o jogo está em andamento (antes só aparecia ao final).
- Corrigido um crash no botão "Revisar mais" do Quiz.
- **Conta**: exclusão de conta (LGPD) — remove a conta e todos os dados vinculados, com dupla confirmação.
- **O Clube**: novo hub institucional do clube — História, Linha do Tempo, Títulos, Hino & Músicas, além de Elenco e Parceiros reaproveitados das telas já existentes.
- **Conta**: páginas reais de Termos de Uso e Política de Privacidade.
- **Jogos**: tela de detalhes da partida passou a mostrar placar, timeline de eventos e as escalações titulares.
- **Notícias**: leitor nativo de matérias do clube, com backend próprio de scraping.
- Nova seção "Siga o Goiás" com os links das redes sociais oficiais, e autopreenchimento de CEP no cadastro de endereço.
- **Arena Esmeraldina**: progresso e ranking persistentes entre os minigames, telas padronizadas (loading/erro/vazio).
- **Perfil**: troca de senha, upload de avatar e edição de dados pessoais.
- Fonte de dados de futebol (jogos, rodada, classificação) trocada pra OneFootball.
- Diversas correções de estabilidade nos jogos e nas telas de futebol.

## 2026-08-24

- **Arena Esmeraldina**: adicionados Adivinhe o Jogador, Adivinhe a Escalação (renomeado de "Missing Eleven") e Quem é o Esmeraldino — todos com dados reais do elenco/histórico do Goiás.
- Novo hub **Elenco** e **Escalação da Torcida** (torcedores votam na escalação provável do próximo jogo).
- Modo escuro com seletor de tema.
- Splash screen em vídeo.
- Minigame Embaixadinhas adicionado (removido no dia seguinte).

## 2026-08-22 a 2026-08-23

- **Arena Esmeraldina**: primeira versão do hub de minigames, com o Quiz do Verdão.
- Reorganização dos assets do app por jogo/categoria.

## 2026-08-17 a 2026-08-21

- Fundação do app: Início, Jogos (classificação, rodada atual, próximo jogo e resultados), Ingressos (setores do estádio), Sócio Esmeralda (vitrine de planos, associação em 3 etapas — mock), Perfil.
- Autenticação real via Supabase (e-mail/senha, recuperação de senha, confirmação de e-mail).
- **Mídia**: feed unificado "Goiás na Rede" (X + YouTube).
- Rede de Parceiros do clube.
- Backend próprio (Cloudflare Worker) agregando dados públicos de futebol e redes sociais.
