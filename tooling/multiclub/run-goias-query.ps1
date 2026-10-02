# Roda consultas SÓ DE LEITURA no banco do Goiás (transação read only) e
# imprime o resultado. Pede a senha na hora (não fica salva).
# Uso (de dentro da pasta fan-hub):
#   powershell -ExecutionPolicy Bypass -File tooling\multiclub\run-goias-query.ps1
#   powershell -ExecutionPolicy Bypass -File tooling\multiclub\run-goias-query.ps1 -Query tooling\multiclub\diagnostics\outro.sql
param(
  [string]$Query = 'tooling\multiclub\diagnostics\notificacoes_goias.sql',
  [string]$DbHost = 'aws-0-sa-east-1.pooler.supabase.com',
  [string]$DbUser = 'postgres.yonozsdgyrhgqrvydbnr'
)

$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path "$PSScriptRoot\..\..")

if (-not (Test-Path $Query)) { throw "Arquivo não encontrado: $Query" }

$secure = Read-Host -AsSecureString "Senha do banco do Goiás"
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
  $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  $encoded = [Uri]::EscapeDataString($plain)
  $env:GOIAS_DB_URL = "postgresql://${DbUser}:${encoded}@${DbHost}:5432/postgres"
  node tooling/multiclub/query-sql-file.mjs goias $Query
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  Remove-Item Env:GOIAS_DB_URL -ErrorAction SilentlyContinue
  $plain = $null; $encoded = $null
}
