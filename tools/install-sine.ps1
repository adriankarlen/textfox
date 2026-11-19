<#
.SYNOPSIS
  Instala (ou atualiza) o textfox-waterfox como mod local do Sine no perfil do Waterfox.

.DESCRIPTION
  - Copia chrome/, theme.json, user.js e LICENSE para <perfil>\chrome\sine-mods\<ModId>.
  - Registra o mod em mods.json como habilitado e com atualizações desligadas
    ("no-updates": true), para o Sine nunca sobrescrevê-lo a partir do GitHub.
  - Desabilita (sem apagar) qualquer outro mod instalado a partir do textfox original.
  - Faz backup de mods.json antes de gravar.
  As mudanças valem a partir do próximo início do Waterfox.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\install-sine.ps1
#>
[CmdletBinding()]
param(
  [string]$ProfilePath,
  [string]$ModId = "textfox-waterfox"
)

$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot

function Get-DefaultProfile {
  $root = Join-Path $env:APPDATA "Waterfox"
  $ini = Join-Path $root "installs.ini"
  if (-not (Test-Path $ini)) { throw "Não encontrei $ini. Informe -ProfilePath." }
  $line = Get-Content $ini | Where-Object { $_ -match '^Default=' } | Select-Object -First 1
  if (-not $line) { throw "installs.ini não tem perfil padrão. Informe -ProfilePath." }
  return Join-Path $root (($line -replace '^Default=', '') -replace '/', '\')
}

if (-not $ProfilePath) { $ProfilePath = Get-DefaultProfile }
$modsDir = Join-Path $ProfilePath "chrome\sine-mods"
$modsJson = Join-Path $modsDir "mods.json"
if (-not (Test-Path $modsJson)) { throw "Sine não encontrado: $modsJson não existe." }

$theme = Get-Content (Join-Path $repo "theme.json") -Raw -Encoding UTF8 | ConvertFrom-Json

# 1. Copiar arquivos do mod
$dest = Join-Path $modsDir $ModId
New-Item -ItemType Directory -Force $dest | Out-Null
$destChrome = Join-Path $dest "chrome"
if (Test-Path $destChrome) { Remove-Item -Recurse -Force $destChrome }
Copy-Item -Recurse (Join-Path $repo "chrome") $destChrome
foreach ($f in "theme.json", "user.js", "LICENSE") {
  Copy-Item (Join-Path $repo $f) (Join-Path $dest $f) -Force
}
Write-Host "Arquivos copiados para $dest"

# 2. Atualizar mods.json
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
Copy-Item $modsJson "$modsJson.bak-$stamp"
$mods = Get-Content $modsJson -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -eq $mods) { $mods = New-Object PSObject }

$entry = [ordered]@{
  style        = [ordered]@{ chrome = $theme.style.chrome; content = $theme.style.content }
  id           = $ModId
  homepage     = ""
  name         = $theme.name
  version      = $theme.version
  description  = $theme.description
  updatedAt    = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  preferences  = ""
  "no-updates" = $true
  enabled      = $true
}
$mods | Add-Member -NotePropertyName $ModId -NotePropertyValue ([pscustomobject]$entry) -Force

foreach ($p in $mods.PSObject.Properties) {
  $m = $p.Value
  if ($p.Name -ne $ModId -and "$($m.homepage)" -match 'adriankarlen/textfox' -and $m.enabled) {
    $m.enabled = $false
    Write-Host "Mod desabilitado: $($m.name) ($($p.Name))"
  }
}

# UTF-8 sem BOM (o Sine lê com IOUtils.readJSON)
$json = $mods | ConvertTo-Json -Depth 20 -Compress
[System.IO.File]::WriteAllText($modsJson, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "mods.json atualizado (backup: mods.json.bak-$stamp)"

if (Get-Process waterfox -ErrorAction SilentlyContinue) {
  Write-Host "O Waterfox está aberto: reinicie-o para aplicar." -ForegroundColor Yellow
}
