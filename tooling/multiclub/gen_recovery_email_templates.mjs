// Gera docs/auth_email_templates/<clube>/recovery.html (+ recovery_subject.txt):
// template "Reset password" SÓ com o código ({{ .Token }}), sem link/botão.
//   node tooling/multiclub/gen_recovery_email_templates.mjs
import { mkdirSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const crest = (worker, file) =>
  `https://${worker}.lucasdiogo1234.workers.dev/assets/lib/assets/branding/${file}`;

const clubs = {
  goias: {
    name: 'GOIÁS APP',
    alt: 'Goiás Esporte Clube',
    crest: crest('goias-app', 'goias/goias_crest.png'),
    head: '#004C1B',
    accent: '#004C1B',
    box: '#EEF5F0',
    border: '#D3E4D8',
    bg: '#F3F6F4',
    subject: 'Seu código para redefinir a senha — GOIÁS APP',
  },
  bragantino: {
    name: 'RED BULL BRAGANTINO',
    alt: 'Red Bull Bragantino',
    crest: crest('bragantino-app', 'bragantino/crest_badge.png'),
    head: '#001D46',
    accent: '#D2003C',
    box: '#FBEAEE',
    border: '#F0CBD4',
    bg: '#F7F7F8',
    subject: 'Seu código para redefinir a senha — Bragantino',
  },
  vilanova: {
    name: 'VILA NOVA FUTEBOL CLUBE',
    alt: 'Vila Nova Futebol Clube',
    crest: crest('vilanova-app', 'vilanova/crest_badge.png'),
    head: '#7A2226',
    accent: '#C33D41',
    box: '#F8ECEC',
    border: '#EFD3D4',
    bg: '#F7F3F3',
    subject: 'Seu código para redefinir a senha — Vila Nova',
  },
};

const render = (key, c) => `<!doctype html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light">
  <title>Redefinir senha</title>
</head>
<!--
  Template "Reset password" do projeto Supabase de ${key}
  (Authentication → Emails → Templates → Reset password → Source).
  Assunto: ${c.subject}
  SÓ o código ({{ .Token }}) — sem link nem botão.
  Gerado por tooling/multiclub/gen_recovery_email_templates.mjs.
-->
<body style="margin:0;padding:0;background-color:${c.bg};font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;color:#1c1c1e;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:${c.bg};">
  <tr>
    <td align="center" style="padding:40px 16px;">
      <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:520px;background:#ffffff;border-radius:20px;overflow:hidden;box-shadow:0 10px 35px rgba(0,0,0,0.08);">
        <tr>
          <td align="center" style="background:${c.head};padding:30px 32px 28px;">
            <img src="${c.crest}" alt="${c.alt}" width="80" style="display:block;width:80px;max-width:80px;height:auto;margin:0 auto 16px;border:0;" />
            <div style="font-size:12px;line-height:18px;font-weight:700;letter-spacing:2.2px;color:#ffffff;text-transform:uppercase;opacity:.85;">${c.name}</div>
            <div style="margin-top:8px;font-size:26px;line-height:34px;font-weight:800;color:#ffffff;">Redefinir senha</div>
          </td>
        </tr>
        <tr>
          <td style="padding:32px 36px 8px;">
            <p style="margin:0;font-size:15px;line-height:24px;color:#555a5f;">Digite o código abaixo no aplicativo para criar uma nova senha.</p>
          </td>
        </tr>
        <tr>
          <td align="center" style="padding:18px 36px 22px;">
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
              <tr>
                <td align="center" style="background:${c.box};border:1px solid ${c.border};border-radius:16px;padding:26px 20px 24px;">
                  <div style="font-family:'Courier New',Courier,monospace;font-size:38px;line-height:48px;font-weight:800;letter-spacing:8px;color:${c.accent};white-space:nowrap;">{{ .Token }}</div>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td style="padding:0 36px 30px;">
            <p style="margin:0;text-align:center;font-size:13px;line-height:21px;color:#80858a;">Não compartilhe este código. Se não foi você, ignore este e-mail.</p>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
</body>
</html>
`;

for (const [key, c] of Object.entries(clubs)) {
  const dir = join(root, 'docs', 'auth_email_templates', key);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, 'recovery.html'), render(key, c));
  writeFileSync(join(dir, 'recovery_subject.txt'), `${c.subject}\n`);
  console.log('ok', key);
}
