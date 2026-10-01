param([Parameter(Mandatory=$true)][string]$LuauPath)
$ErrorActionPreference = 'Stop'
$arenaRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$arenaSource = Get-Content -LiteralPath (Join-Path $arenaRoot 'src/server/Services/ArenaService.luau') -Raw
$arenaConfig = Get-Content -LiteralPath (Join-Path $arenaRoot 'src/shared/Config/Arena.luau') -Raw
$arenaTest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ArenaLobbySelfTest.luau') -Raw
$arenaRunner = "local run=(function()`n$arenaTest`nend)()`nprint('Arena lobby checks:',run([====[$arenaSource]====],[====[$arenaConfig]====]))"
$arenaRunnerPath = Join-Path $env:TEMP ('codex-arena-' + [guid]::NewGuid() + '.luau')
try {
    [System.IO.File]::WriteAllText($arenaRunnerPath, $arenaRunner)
    & $LuauPath $arenaRunnerPath
    if ($LASTEXITCODE -ne 0) { throw 'Arena lobby self-test failed' }
} finally {
    Remove-Item -LiteralPath $arenaRunnerPath -ErrorAction SilentlyContinue
}
