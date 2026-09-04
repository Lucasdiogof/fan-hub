# M4 — Checklist de config de Auth não-SQL (por projeto)

Data: 2026-09-04
Escopo: documentar, nunca aplicar. Nenhum valor foi copiado do Goiás pro Bragantino — cada linha marcada explicitamente `SHARED`/`PER_CLUB`/`PER_ENVIRONMENT`, valores reais preenchidos só quando confirmados (a maioria não é lida via SQL — vive na config gerenciada da Supabase, dashboard/Management API — por isso este checklist é ESTRUTURA, não um dump de valores).

## Como usar
Antes de considerar o Bragantino (ou qualquer clube novo) pronto pra Auth funcionar de verdade, cada linha abaixo precisa de uma decisão + um valor real, confirmado no dashboard do projeto certo — nunca assumido/copiado do Goiás.

| Config | Tipo | Onde vive | Fonte no código (se houver) | Nota |
|---|---|---|---|---|
| Site URL | PER_CLUB | Dashboard → Auth → URL Configuration | — | Base pra construir links de e-mail; cada projeto Supabase tem o seu, aponta pro domínio/Worker daquele clube. |
| Redirect URLs (allowlist) | PER_CLUB | Dashboard → Auth → URL Configuration | `SupabaseConfig.redirectUrl` (`lib/core/config/supabase_config.dart`) → hoje hardcoded pro Worker do Goiás, usado em `resetPasswordForEmail` | Achado no relatório 48 §9: precisa entrar no mesmo pacote de correção do `Supabase.initialize` por flavor (item 15, fora de escopo desta rodada). |
| Confirm signup (template + OTP) | PER_CLUB (copy) / SHARED (mecanismo) | Dashboard → Auth → Email Templates | `auth_remote_data_source.dart` usa `OtpType.signup`, código de 6 dígitos | O MECANISMO (OTP de 6 dígitos) é igual pros dois; o TEXTO do e-mail (nome do clube, cores, remetente) é por clube. |
| Reset password (template) | PER_CLUB (copy) / SHARED (mecanismo) | Dashboard → Auth → Email Templates | `sendPasswordReset`/`resetPasswordForEmail` | Idem — mecanismo igual, copy por clube. |
| OTP expiry | SHARED (proposto) | Dashboard → Auth → Providers → Email | — | Sem motivo de produto pra divergir entre clubes; confirmar valor real do Goiás antes de replicar (não lido via SQL). |
| Providers habilitados (email/social login) | PER_CLUB (potencialmente) | Dashboard → Auth → Providers | — | Hoje só email/senha é usado no app (confirmado em `auth_remote_data_source.dart`) — sem evidência de OAuth social configurado; se algum dia um clube quiser login social e outro não, vira PER_CLUB de verdade. |
| SMTP customizado (remetente) | PER_CLUB (recomendado) | Dashboard → Auth → SMTP Settings | — | Cada clube provavelmente quer e-mails saindo com o nome/domínio dele, não do outro — confirmar se o Goiás já usa SMTP customizado ou o padrão da Supabase antes de decidir pro Bragantino. |
| JWT expiry / refresh token settings | SHARED (proposto) | Dashboard → Auth → Sessions | — | Configuração de segurança de sessão, sem motivo de produto pra divergir por clube. |
| CAPTCHA (se habilitado) | SHARED (proposto) | Dashboard → Auth → Attack Protection | — | Mesma lógica do JWT — proteção de plataforma, não identidade de clube. |
| PER_ENVIRONMENT (dev/staging/prod) | PER_ENVIRONMENT | — | — | Nenhuma evidência de múltiplos ambientes por clube hoje (1 projeto Supabase = 1 ambiente) — categoria reservada caso isso mude no futuro. |

## O que este checklist NÃO faz
- Não lê nenhum valor real do dashboard (SQL/`db query` não alcança config de Auth gerenciada) — os valores concretos do Goiás precisam ser conferidos manualmente por você antes de decidir o que replicar/adaptar pro Bragantino.
- Não altera nenhum dashboard nesta rodada.
- Não assume que "copiar tudo do Goiás" é a resposta certa pra nenhuma linha — cada PER_CLUB precisa de uma decisão própria quando o Bragantino for realmente inicializado (Fase 1, passo além do que esta rodada cobre).
