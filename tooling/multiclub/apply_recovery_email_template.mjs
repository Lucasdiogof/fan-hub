// Aplica (ou só lê, sem --apply) o template "Reset password" por CÓDIGO e
// confirma OTP length 6 no projeto Supabase de um clube, via Management API.
//   SUPABASE_ACCESS_TOKEN=<token da ORG do projeto> \
//     node tooling/multiclub/apply_recovery_email_template.mjs --club goias [--apply]
// Destino = clube -> projectRef (registry); nunca a "conta" do token.
// Sai com código 0 só se a leitura de volta confirmar tudo.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const args = process.argv.slice(2);
const club = args[args.indexOf('--club') + 1];
const apply = args.includes('--apply');
const registry = JSON.parse(
  readFileSync(join(root, 'tooling/multiclub/supabase_projects_registry.json'), 'utf8'),
);
const ref = registry[club]?.projectRef;
const token = process.env.SUPABASE_ACCESS_TOKEN;
if (!ref || !token) {
  console.error(
    'uso: SUPABASE_ACCESS_TOKEN=... node apply_recovery_email_template.mjs --club goias|bragantino|vilanova [--apply]',
  );
  process.exit(2);
}
const dir = join(root, 'docs/auth_email_templates', club);
const html = readFileSync(join(dir, 'recovery.html'), 'utf8');
const subject = readFileSync(join(dir, 'recovery_subject.txt'), 'utf8').trim();
const url = `https://api.supabase.com/v1/projects/${ref}/config/auth`;
const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

if (apply) {
  const res = await fetch(url, {
    method: 'PATCH',
    headers,
    body: JSON.stringify({
      mailer_subjects_recovery: subject,
      mailer_templates_recovery_content: html,
      mailer_otp_length: 6,
    }),
  });
  if (!res.ok) {
    console.error('PATCH falhou', res.status, await res.text());
    process.exit(1);
  }
}
const res = await fetch(url, { headers });
if (!res.ok) {
  console.error('GET falhou', res.status, await res.text());
  process.exit(1);
}
const cfg = await res.json();
const tpl = cfg.mailer_templates_recovery_content ?? '';
const checks = {
  otp_length_6: cfg.mailer_otp_length === 6,
  has_token: tpl.includes('{{ .Token }}'),
  no_link: !/ConfirmationURL|<a\s/i.test(tpl),
  matches_repo: tpl.trim() === html.trim(),
  subject_ok: cfg.mailer_subjects_recovery === subject,
};
console.log(club, ref, { applied: apply, mailer_otp_length: cfg.mailer_otp_length, ...checks });
process.exit(Object.values(checks).every(Boolean) ? 0 : 1);
