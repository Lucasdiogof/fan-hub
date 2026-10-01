# Roda uma migration no banco do Goiás pedindo a senha na hora (não fica salva).
# Uso (de dentro da pasta fan-hub):
#   powershell -ExecutionPolicy Bypass -File tooling\multiclub\run-goias-migration.ps1
#   powershell -ExecutionPolicy Bypass -File tooling\multiclub\run-goias-migration.ps1 -Migration supabase\migrations\outra.sql
param(
  [string]$Migration = 'supabase\migrations\20261001010000_fix_arena_goias_audit_phase1.sql',
  [string]$DbHost = 'aws-0-sa-east-1.pooler.supabase.com',
  [string]$DbUser = 'postgres.yonozsdgyrhgqrvydbnr'
)

$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path "$PSScriptRoot\..\..")

if (-not (Test-Path $Migration)) { throw "Migration não encontrada: $Migration" }

$secure = Read-Host -AsSecureString "Senha do banco do Goiás"
$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
try {
  $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  $encoded = [Uri]::EscapeDataString($plain)
  $env:GOIAS_DB_URL = "postgresql://${DbUser}:${encoded}@${DbHost}:5432/postgres"
  Write-Host "Aplicando $Migration ..."
  node tooling/multiclub/run-sql-file.mjs goias $Migration --yes
  if ($LASTEXITCODE -ne 0) { Write-Host "Falhou (código $LASTEXITCODE). Nada foi aplicado se o erro veio de uma pré-condição." -ForegroundColor Red }
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  Remove-Item Env:GOIAS_DB_URL -ErrorAction SilentlyContinue
  $plain = $null; $encoded = $null
}
