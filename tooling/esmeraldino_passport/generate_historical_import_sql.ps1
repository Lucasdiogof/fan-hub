# ============================================================================
# Passaporte Esmeraldino — gerador do import histórico 1943-2026 (PowerShell).
#
# Lê as duas fontes oficiais em tooling/esmeraldino_passport/source/:
#   - passaporte_esmeraldino_1943_2026_FINAL.csv       (3.840 partidas elegíveis)
#   - passaporte_esmeraldino_EXCLUIDOS_ADMIN.csv       (32 registros administrativos)
#
# Gera dois SQLs idempotentes (INSERT ... ON CONFLICT (id) DO UPDATE):
#   - supabase/passport_esmeraldino_historical_import.sql   -> public.passport_matches
#   - supabase/passport_esmeraldino_excluded_import.sql     -> public.passport_matches_excluded
#
# Por que PowerShell e não Python/Node como o gerador antigo
# (generate_import_sql.py): este ambiente de geração não tinha node/python
# no PATH; PowerShell tem Import-Csv nativo (RFC4180, lida bem com aspas e
# vírgulas embutidas) e já validou os dois CSVs byte a byte antes deste
# script existir. Ver README.md para o runbook completo e para quando
# regenerar a partir de uma futura correção do CSV fonte.
#
# Nunca escreve os dados em Dart, nunca gera um INSERT por linha — um único
# INSERT em lote por arquivo, no padrão já usado por generate_import_sql.py.
# ============================================================================

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$mainCsvPath = Join-Path $PSScriptRoot 'source\passaporte_esmeraldino_1943_2026_FINAL.csv'
$exclCsvPath = Join-Path $PSScriptRoot 'source\passaporte_esmeraldino_EXCLUIDOS_ADMIN.csv'
$mainOutPath = Join-Path $repoRoot 'supabase\passport_esmeraldino_historical_import.sql'
$exclOutPath = Join-Path $repoRoot 'supabase\passport_esmeraldino_excluded_import.sql'

$EXPECTED_MAIN_COUNT = 3840
$EXPECTED_EXCL_COUNT = 32
$EXPECTED_SEASON_MIN = 1943
$EXPECTED_SEASON_MAX = 2026
$EXPECTED_SEASON_COUNT = 84

# Todas as funções abaixo escrevem `null::<tipo>` em vez de `null` puro —
# NUNCA um `null` sem cast. Motivo (bug real batido em produção, 2026-09-15):
# `with payload (...) as (values ...)` infere o tipo de cada coluna só a
# partir dos literais daquele arquivo, sem nenhuma informação da tabela de
# destino. Como o import é dividido em partes de 300 linhas, é perfeitamente
# possível uma parte inteira ter `match_time`/`round`/etc. null em TODAS as
# 300 linhas (ex.: uma parte só com partidas históricas de 1943-1999, cujo
# horário nunca é conhecido) — nesse caso o Postgres infere a coluna inteira
# como `text`, e o INSERT final quebra com "column is of type X but
# expression is of type text". Cast explícito em cada null elimina o
# problema na raiz, não só nos casos já observados.
function Sql-Str($value) {
    if ([string]::IsNullOrWhiteSpace($value)) { return 'null::text' }
    return "'" + ($value -replace "'", "''") + "'"
}

function Sql-StrOrLiteralUnknown($value) {
    # Trata tanto branco quanto o literal textual "UNKNOWN" do CSV como null —
    # nunca grava a string "UNKNOWN" como se fosse um dado real.
    if ([string]::IsNullOrWhiteSpace($value) -or $value -eq 'UNKNOWN') { return 'null::text' }
    return "'" + ($value -replace "'", "''") + "'"
}

function Sql-Date($value) {
    if ([string]::IsNullOrWhiteSpace($value)) { return 'null::date' }
    return "date '$value'"
}

function Sql-Time($value) {
    if ([string]::IsNullOrWhiteSpace($value) -or $value -eq 'UNKNOWN') { return 'null::time' }
    return "time '$value'"
}

function Sql-Bool($value) {
    if ([string]::IsNullOrWhiteSpace($value)) { return 'null::boolean' }
    if ($value -eq 'True') { return 'true' }
    if ($value -eq 'False') { return 'false' }
    throw "valor booleano inesperado: '$value'"
}

function Sql-Int($value) {
    if ([string]::IsNullOrWhiteSpace($value)) { return 'null::integer' }
    return [string]([int]$value)
}

function Map-Outcome($value) {
    switch ($value) {
        'W' { return 'WIN' }
        'L' { return 'LOSS' }
        'D' { return 'DRAW' }
        'WIN' { return 'WIN' }
        'LOSS' { return 'LOSS' }
        'DRAW' { return 'DRAW' }
        '' { return $null }
        default { throw "outcome desconhecido: '$value'" }
    }
}

function Map-DatePrecision($value) {
    switch ($value) {
        'DAY' { return 'date_only' }
        'YEAR' { return 'year_only' }
        'date_only' { return 'date_only' }
        'datetime' { return 'datetime' }
        default { throw "date_precision desconhecida: '$value'" }
    }
}

function Build-DataNotes($notes, $classificationNote, $conflictNote, $sourceSecondary) {
    # Algumas linhas do CSV repetem o mesmo texto em notes/classification_note/
    # conflict_note (ex.: hist-f80-0004) -- deduplica pra não gravar a mesma
    # frase duas vezes em data_notes.
    $seen = New-Object System.Collections.Generic.HashSet[string]
    $parts = New-Object System.Collections.Generic.List[string]
    $notesTrim = if ($notes) { $notes.Trim() } else { '' }
    if (-not [string]::IsNullOrWhiteSpace($notesTrim)) {
        $parts.Add($notesTrim)
        [void]$seen.Add($notesTrim)
    }
    $classTrim = if ($classificationNote) { $classificationNote.Trim() } else { '' }
    if (-not [string]::IsNullOrWhiteSpace($classTrim) -and -not $seen.Contains($classTrim)) {
        $parts.Add("Classificacao: " + $classTrim)
        [void]$seen.Add($classTrim)
    }
    $conflictTrim = if ($conflictNote) { $conflictNote.Trim() } else { '' }
    if (-not [string]::IsNullOrWhiteSpace($conflictTrim) -and -not $seen.Contains($conflictTrim)) {
        $parts.Add("Conflito historico: " + $conflictTrim)
        [void]$seen.Add($conflictTrim)
    }
    $secTrim = if ($sourceSecondary) { $sourceSecondary.Trim() } else { '' }
    if (-not [string]::IsNullOrWhiteSpace($secTrim) -and -not $seen.Contains($secTrim)) {
        $parts.Add("Fonte secundaria: " + $secTrim)
    }
    if ($parts.Count -eq 0) { return $null }
    return ($parts -join ' | ')
}

# ---------------------------------------------------------------------------
# 1) Carrega e valida o CSV principal
# ---------------------------------------------------------------------------
Write-Output "[1/6] Lendo $mainCsvPath ..."
$main = Import-Csv -Path $mainCsvPath -Encoding UTF8
Write-Output "  linhas: $($main.Count)"
if ($main.Count -ne $EXPECTED_MAIN_COUNT) {
    throw "FAIL: esperado $EXPECTED_MAIN_COUNT linhas no CSV principal, encontrado $($main.Count)"
}

$notEligible = $main | Where-Object { $_.passport_eligible -ne 'True' }
if ($notEligible.Count -gt 0) {
    throw "FAIL: $($notEligible.Count) linhas no CSV principal com passport_eligible != True"
}

$mainIds = $main | Select-Object -ExpandProperty id
$dupMainIds = $mainIds | Group-Object | Where-Object { $_.Count -gt 1 }
if ($dupMainIds.Count -gt 0) {
    throw "FAIL: ids duplicados no CSV principal: $($dupMainIds.Name -join ', ')"
}

$histSourceNos = $main | Where-Object { -not [string]::IsNullOrWhiteSpace($_.historical_source_no) } | Select-Object -ExpandProperty historical_source_no
$dupHsn = $histSourceNos | Group-Object | Where-Object { $_.Count -gt 1 }
if ($dupHsn.Count -gt 0) {
    throw "FAIL: historical_source_no duplicado: $($dupHsn.Name -join ', ')"
}

$seasons = $main | Select-Object -ExpandProperty season -Unique | ForEach-Object { [int]$_ } | Sort-Object
if ($seasons[0] -ne $EXPECTED_SEASON_MIN -or $seasons[-1] -ne $EXPECTED_SEASON_MAX -or $seasons.Count -ne $EXPECTED_SEASON_COUNT) {
    throw "FAIL: temporadas esperadas $EXPECTED_SEASON_MIN..$EXPECTED_SEASON_MAX ($EXPECTED_SEASON_COUNT), encontrado $($seasons[0])..$($seasons[-1]) ($($seasons.Count))"
}
Write-Output "  OK — $($main.Count) elegíveis, $($seasons.Count) temporadas ($($seasons[0])-$($seasons[-1])), sem duplicatas de id/historical_source_no."

# ---------------------------------------------------------------------------
# 2) Carrega e valida o CSV de excluídos
# ---------------------------------------------------------------------------
Write-Output "[2/6] Lendo $exclCsvPath ..."
$excl = Import-Csv -Path $exclCsvPath -Encoding UTF8
Write-Output "  linhas: $($excl.Count)"
if ($excl.Count -ne $EXPECTED_EXCL_COUNT) {
    throw "FAIL: esperado $EXPECTED_EXCL_COUNT linhas no CSV de excluídos, encontrado $($excl.Count)"
}
$mainIdSet = [System.Collections.Generic.HashSet[string]]::new([string[]]$mainIds)
$overlap = $excl | Where-Object { $mainIdSet.Contains($_.id) }
if ($overlap.Count -gt 0) {
    $overlapIds = ($overlap | Select-Object -ExpandProperty id) -join ', '
    throw "FAIL: $($overlap.Count) ids aparecem tanto no principal quanto nos excluidos: $overlapIds"
}
Write-Output "  OK — $($excl.Count) registros administrativos, nenhum overlap de id com o principal."

# ---------------------------------------------------------------------------
# 3) Gera o SQL do import principal (public.passport_matches)
# ---------------------------------------------------------------------------
Write-Output "[3/6] Gerando linhas do import principal..."

$COLUMNS = @(
    'id','season','match_date','match_time','date_precision','status',
    'competition','competition_code','competition_source_name','round',
    'opponent','club_is_home','neutral_site','home_team','away_team',
    'home_score','away_score','club_score','opponent_score','score_display',
    'outcome','source_provider','source_match_id','source_url',
    'source_confidence','date_confidence','score_confidence',
    'venue_confidence','historical_source_no','officiality',
    'dataset_origin','data_notes'
)
# kickoff_at/display_timezone/venue_id/venue_audit_status nunca entram no
# payload deste import: são campos de enriquecimento (horário com timezone
# exato e vínculo de estádio) que este CSV não fornece para o lote
# histórico, e que uma reimportação nunca deve sobrescrever para os
# registros já existentes (2000-2026) — mesmo padrão que o gerador antigo já
# usava para venue_id.
$UPDATE_COLUMNS = $COLUMNS | Where-Object { $_ -ne 'id' }

$rows = New-Object System.Collections.Generic.List[string]
foreach ($m in $main) {
    $dataNotes = Build-DataNotes $m.notes $m.classification_note $m.conflict_note $m.source_secondary
    $values = @(
        (Sql-Str $m.id),
        (Sql-Int $m.season),
        (Sql-Date $m.effective_date),
        (Sql-Time $m.time),
        (Sql-Str (Map-DatePrecision $m.date_precision)),
        "'FINISHED'",
        (Sql-Str $m.competition),
        (Sql-Str $m.competition_code),
        (Sql-Str $m.competition_original),
        (Sql-Str $m.round),
        (Sql-Str $m.opponent),
        (Sql-Bool $m.goias_is_home),
        (Sql-Bool $m.neutral_site),
        (Sql-Str $m.home_team),
        (Sql-Str $m.away_team),
        (Sql-Int $m.home_score),
        (Sql-Int $m.away_score),
        (Sql-Int $m.goias_score),
        (Sql-Int $m.opponent_score),
        (Sql-StrOrLiteralUnknown $m.score_display),
        (Sql-Str (Map-Outcome $m.outcome)),
        (Sql-Str $m.source_provider),
        (Sql-Str $m.source_match_id),
        (Sql-Str $m.source_url),
        (Sql-Str $m.source_confidence),
        (Sql-Str $m.date_confidence),
        (Sql-Str $m.score_confidence),
        (Sql-Str $m.venue_confidence),
        (Sql-Str $m.historical_source_no),
        (Sql-Str $m.officiality),
        (Sql-Str $m.dataset_origin),
        (Sql-Str $dataNotes)
    )
    $rows.Add("    (" + ($values -join ', ') + ")")
}

$updateSet = ($UPDATE_COLUMNS | ForEach-Object { "    $_ = excluded.$_" }) -join ",`n"
$updateSet += ",`n    updated_at = now()"
$oldTuple = ($UPDATE_COLUMNS | ForEach-Object { "public.passport_matches.$_" }) -join ', '
$newTuple = ($UPDATE_COLUMNS | ForEach-Object { "excluded.$_" }) -join ', '
$colList = $COLUMNS -join ', '

# O SQL Editor do Supabase recusa a query de 3.840 linhas num arquivo só
# ("Query is too large") -- divide em partes de $CHUNK_SIZE linhas, cada
# uma um upsert transacional independente e idempotente (rodar as partes
# fora de ordem, ou repetir uma, não duplica nem apaga nada).
$CHUNK_SIZE = 300
$partsDir = Join-Path $repoRoot 'supabase\passport_esmeraldino_historical_import_parts'
if (Test-Path $partsDir) { Remove-Item $partsDir -Recurse -Force }
New-Item -ItemType Directory -Path $partsDir | Out-Null

$totalParts = [Math]::Ceiling($rows.Count / $CHUNK_SIZE)
$partFiles = New-Object System.Collections.Generic.List[string]
for ($p = 0; $p -lt $totalParts; $p++) {
    $chunkRows = $rows | Select-Object -Skip ($p * $CHUNK_SIZE) -First $CHUNK_SIZE
    $rowsSql = ($chunkRows -join ",`n")
    $partNum = ($p + 1).ToString('00')
    $partPath = Join-Path $partsDir "passport_esmeraldino_historical_import_part_$partNum.sql"

    $partSql = @"
-- ============================================================================
-- Passaporte Esmeraldino — importação histórica consolidada 1943-2026
-- PARTE $partNum de $($totalParts.ToString('00')) ($($chunkRows.Count) de $($main.Count) partidas no total)
-- (GERADO por tooling/esmeraldino_passport/generate_historical_import_sql.ps1,
-- não editar à mão).
--
-- Fonte: tooling/esmeraldino_passport/source/passaporte_esmeraldino_1943_2026_FINAL.csv
-- Temporadas no total: $($seasons[0])-$($seasons[-1]) ($($seasons.Count) temporadas)
--
-- Dividido em partes porque o SQL Editor do Supabase recusa a query inteira
-- de uma vez ("Query is too large"). Rode as $($totalParts.ToString('00'))
-- partes em ordem (01, 02, ...) — mas mesmo rodando fora de ordem, ou
-- repetindo uma parte, é seguro: cada parte é um `on conflict (id) do
-- update` independente, idempotente, e nunca apaga uma linha de
-- passport_matches (presenças de usuário em passport_attendances nunca são
-- tocadas). Roda DEPOIS da migration de schema
-- (20260915000000_passport_esmeraldino_historical_schema.sql).
-- ============================================================================

with payload ($colList) as (
  values
$rowsSql
),
upserted as (
  insert into public.passport_matches ($colList)
  select $colList from payload
  on conflict (id) do update set
$updateSet
  where ($oldTuple)
    is distinct from ($newTuple)
  returning (xmax = 0) as inserted
)
insert into public.passport_sync_runs (
  provider, started_at, finished_at, status,
  inserted_count, updated_count, unchanged_count, failed_count, metadata
)
select
  'historical_csv_1943_2026',
  now(),
  now(),
  'success',
  count(*) filter (where inserted),
  count(*) filter (where not inserted),
  (select count(*) from payload) - count(*),
  0,
  jsonb_build_object(
    'source_file', 'passaporte_esmeraldino_1943_2026_FINAL.csv',
    'part', $partNum,
    'total_parts', '$($totalParts.ToString('00'))',
    'record_count', (select count(*) from payload)
  )
from upserted
returning
  inserted_count as "inseridos",
  updated_count as "atualizados",
  unchanged_count as "sem_mudanca",
  failed_count as "erros";
"@

    # Set-Content -Encoding UTF8 grava BOM no Windows PowerShell 5.1, e o
    # SQL Editor do Supabase quebra com "syntax error at or near" no BOM —
    # escreve UTF-8 sem BOM explicitamente.
    [System.IO.File]::WriteAllText($partPath, $partSql, [System.Text.UTF8Encoding]::new($false))
    $partFiles.Add($partPath)
}

# Remove o arquivo único antigo, se existir de uma geração anterior, pra
# não deixar um artefato desatualizado (grande demais) no repo.
if (Test-Path $mainOutPath) { Remove-Item $mainOutPath -Force }

Write-Output "  Escritas $($partFiles.Count) partes em $partsDir ($CHUNK_SIZE linhas cada, $($main.Count) linhas no total)."

# ---------------------------------------------------------------------------
# 4) Gera o SQL do import de excluídos/administrativos (audit table)
# ---------------------------------------------------------------------------
Write-Output "[4/6] Gerando linhas do import de excluídos..."

$EXCL_COLUMNS = @(
    'id','season','match_date','date_precision','status','competition',
    'competition_code','round','opponent','club_is_home','neutral_site',
    'home_score','away_score','club_score','opponent_score','score_display',
    'outcome','officiality','historical_source_no','source_provider',
    'source_match_id','source_url','dataset_origin','data_notes'
)
$EXCL_UPDATE_COLUMNS = $EXCL_COLUMNS | Where-Object { $_ -ne 'id' }

$exclRows = New-Object System.Collections.Generic.List[string]
foreach ($m in $excl) {
    $dataNotes = Build-DataNotes $m.notes $m.classification_note $m.conflict_note $m.source_secondary
    $values = @(
        (Sql-Str $m.id),
        (Sql-Int $m.season),
        (Sql-Date $m.effective_date),
        (Sql-Str (Map-DatePrecision $m.date_precision)),
        (Sql-Str $m.status),
        (Sql-Str $m.competition),
        (Sql-Str $m.competition_code),
        (Sql-Str $m.round),
        (Sql-Str $m.opponent),
        (Sql-Bool $m.goias_is_home),
        (Sql-Bool $m.neutral_site),
        (Sql-Int $m.home_score),
        (Sql-Int $m.away_score),
        (Sql-Int $m.goias_score),
        (Sql-Int $m.opponent_score),
        (Sql-StrOrLiteralUnknown $m.score_display),
        (Sql-Str (Map-Outcome $m.outcome)),
        (Sql-Str $m.officiality),
        (Sql-Str $m.historical_source_no),
        (Sql-Str $m.source_provider),
        (Sql-Str $m.source_match_id),
        (Sql-Str $m.source_url),
        (Sql-Str $m.dataset_origin),
        (Sql-Str $dataNotes)
    )
    $exclRows.Add("    (" + ($values -join ', ') + ")")
}

$exclRowsSql = ($exclRows -join ",`n")
$exclUpdateSet = ($EXCL_UPDATE_COLUMNS | ForEach-Object { "    $_ = excluded.$_" }) -join ",`n"
$exclUpdateSet += ",`n    updated_at = now()"
$exclColList = $EXCL_COLUMNS -join ', '

$exclSql = @"
-- ============================================================================
-- Passaporte Esmeraldino — registros administrativos/excluídos 1943-2026
-- (GERADO por tooling/esmeraldino_passport/generate_historical_import_sql.ps1,
-- não editar à mão).
--
-- Fonte: tooling/esmeraldino_passport/source/passaporte_esmeraldino_EXCLUIDOS_ADMIN.csv
-- Registros: $($excl.Count)
--
-- Preservados só para auditoria histórica em public.passport_matches_excluded
-- (tabela sem policy pública — nunca aparecem no Passaporte, nunca permitem
-- check-in). Ver classificação de cada um em data_notes/officiality/status.
--
-- Roda DEPOIS da migration de schema
-- (20260915000000_passport_esmeraldino_historical_schema.sql).
-- ============================================================================

insert into public.passport_matches_excluded ($exclColList)
values
$exclRowsSql
on conflict (id) do update set
$exclUpdateSet;
"@

[System.IO.File]::WriteAllText($exclOutPath, $exclSql, [System.Text.UTF8Encoding]::new($false))
Write-Output "  Escrito $exclOutPath ($($exclSql.Length) bytes, $($excl.Count) linhas)."

# ---------------------------------------------------------------------------
# 5) Contagens de conferência (2026 por competição)
# ---------------------------------------------------------------------------
Write-Output "[5/6] Conferência 2026..."
$c2026 = $main | Where-Object { $_.season -eq '2026' }
Write-Output "  2026 total: $($c2026.Count)"
$c2026 | Group-Object competition_code | Sort-Object Name | ForEach-Object { Write-Output "    $($_.Name): $($_.Count)" }

Write-Output "[6/6] Concluído."
