// Regras puras de dispatch (retry/token inválido), extraídas de
// notifications-dispatch/index.ts pra serem testáveis sem Deno — mesmo
// padrão de notification_message_builder.ts/recipient_eligibility.ts.

/**
 * Um token é considerado inválido (desativado em
 * `user_notification_tokens`, nunca mais tentado) quando o FCM responde
 * 404 ou o corpo do erro menciona UNREGISTERED/NOT_FOUND — os 2 sinais
 * documentados da API de FCM HTTP v1 pra "este token não existe mais"
 * (desinstalou o app, trocou de aparelho, etc.). Qualquer outro erro
 * (rede, quota, 5xx do FCM) é transitório — nunca desativa o token, só
 * marca a entrega como `failed` pra tentar de novo depois.
 */
export function isInvalidTokenError(status: number, errorBody: string): boolean {
  return status === 404 || errorBody.includes('UNREGISTERED') || errorBody.includes('NOT_FOUND');
}

/**
 * Um evento travado em `processing` (ex.: a função caiu no meio do envio)
 * só é reclamado pelo cron de segurança depois de `thresholdMinutes` sem
 * atualização — nunca imediatamente (evitaria roubar um evento que outra
 * execução, ainda em andamento, só está demorando um pouco mais).
 */
export function isStuckProcessing(detectedAt: string, now: Date, thresholdMinutes: number): boolean {
  const stuckSince = now.getTime() - thresholdMinutes * 60 * 1000;
  return new Date(detectedAt).getTime() < stuckSince;
}
