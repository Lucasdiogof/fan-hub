# Roda o sync do X localmente, na SUA rede — que é o teste que decide se o
# problema é o script/token ou o IP do runner do GitHub.
#
#   powershell -ExecutionPolicy Bypass -File scripts\social\run_sync_local.ps1
#
# O token vem de, nesta ordem: variável de ambiente X_AUTH_TOKEN, um arquivo
# .env na raiz do repo (ignorado pelo git), ou uma pergunta na hora. Quando
# perguntado, ele fica só na memória deste processo: não é gravado, não vai
# pro histórico do PowerShell e não aparece na tela enquanto você digita.

$ErrorActionPreference = 'Stop'
$repo = Resolve-Path (Join-Path $PSScriptRoot '..\..')

function Get-Token {
    if ($env:X_AUTH_TOKEN) {
        Write-Host 'Token: usando X_AUTH_TOKEN do ambiente.'
        return $env:X_AUTH_TOKEN
    }

    $envFile = Join-Path $repo '.env'
    if (Test-Path $envFile) {
        foreach ($line in Get-Content $envFile) {
            if ($line -match '^\s*X_AUTH_TOKEN\s*=\s*(.+?)\s*$') {
                Write-Host 'Token: usando o .env da raiz do repo.'
                return $Matches[1].Trim('"').Trim("'")
            }
        }
    }

    # AsSecureString: o que você digita não ecoa na tela.
    $secure = Read-Host 'Cole o auth_token do X (não fica salvo)' -AsSecureString
    return [System.Net.NetworkCredential]::new('', $secure).Password
}

# Checagem do pacote com o ErrorActionPreference afrouxado: no PowerShell 5.1
# redirecionar a saída de um .exe faz cada linha de stderr virar ErrorRecord,
# o que sob 'Stop' abortaria o script mesmo com o import falhando de forma
# esperada.
$prev = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
python -c "import Scweet" *> $null
$hasScweet = ($LASTEXITCODE -eq 0)
$ErrorActionPreference = $prev

if (-not $hasScweet) {
    Write-Host 'Scweet nao esta instalada. Instalando...'
    python -m pip install --quiet "Scweet>=5.3,<6"
}

$token = Get-Token
if (-not $token) { Write-Error 'Nenhum token informado.'; exit 1 }

Push-Location $repo
try {
    $env:X_AUTH_TOKEN = $token
    python scripts/social/sync_x_posts.py
    $code = $LASTEXITCODE

    Write-Host ''
    if ($code -eq 0) {
        Write-Host 'FUNCIONOU LOCAL. Se o GitHub Actions continuar devolvendo 0,' -ForegroundColor Green
        Write-Host 'o problema é o ambiente do runner (IP), nao o script nem o token.' -ForegroundColor Green
        Write-Host 'Caminho: definir o secret X_PROXY, ou um runner self-hosted.'
    } else {
        Write-Host 'Falhou local tambem. Olhe a linha de diagnostico acima:' -ForegroundColor Yellow
        Write-Host '  AuthError    -> o token nao vale mais'
        Write-Host '  RateLimit    -> 429, esperar'
        Write-Host '  NetworkError -> bloqueio de rede tambem aqui'
        Write-Host '  sem excecao  -> caso ambiguo (manifesto ou perfil)'
    }
    exit $code
} finally {
    # Some com o token do ambiente deste processo assim que termina.
    Remove-Item Env:\X_AUTH_TOKEN -ErrorAction SilentlyContinue
    Pop-Location
}
