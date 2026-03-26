# common.ps1 — shared utilities for skills-registry CLI

# Colors
$script:UseColor = $Host.UI.SupportsVirtualTerminal -or $env:WT_SESSION
function Write-Info  { param([string]$Msg) if ($script:UseColor) { Write-Host "✓ $Msg" -ForegroundColor Green } else { Write-Host "OK $Msg" } }
function Write-Warn  { param([string]$Msg) if ($script:UseColor) { Write-Host "⚠ $Msg" -ForegroundColor Yellow } else { Write-Host "WARN $Msg" } }
function Write-Die   { param([string]$Msg) if ($script:UseColor) { Write-Host "✗ $Msg" -ForegroundColor Red } else { Write-Host "ERR $Msg" }; exit 1 }

function Confirm-Prompt {
    param([string]$Prompt)
    if ($env:SKILL_YES -eq "1") { return $true }
    $answer = Read-Host "$Prompt (y/n)"
    return $answer -match '^[Yy]'
}

function Read-YamlField {
    param([string]$Content, [string]$Key)
    $pattern = "^${Key}:\s*[`"']?([^`"']*)[`"']?\s*$"
    foreach ($line in $Content -split "`n") {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }
    return ""
}

function Read-YamlList {
    param([string]$Content, [string]$Key)
    $lines = $Content -split "`n"
    $found = $false
    $results = @()
    foreach ($line in $lines) {
        if ($line -match "^${Key}:") {
            $found = $true
            continue
        }
        if ($found -and $line -match '^\s*-\s+(.+)$') {
            $val = $Matches[1].Trim() -replace '^["'']|["'']$', ''
            $results += $val
            continue
        }
        if ($found -and $line -match '^\S') {
            $found = $false
        }
    }
    return $results
}

function Test-IsUrl {
    param([string]$Value)
    return $Value -match '^https?://' -or $Value -match '^git@'
}

function Test-IsShorthand {
    param([string]$Value)
    return (-not (Test-IsUrl $Value)) -and ($Value -match '^[a-zA-Z0-9._-]+/[a-zA-Z0-9._-]+$')
}

function Resolve-RegistryRoot {
    $dir = Split-Path -Parent $PSScriptRoot
    while ($dir -and $dir -ne [System.IO.Path]::GetPathRoot($dir)) {
        if ((Test-Path "$dir/bin/lib") -and ((Test-Path "$dir/skills") -or (Test-Path "$dir/agents") -or (Test-Path "$dir/instructions"))) {
            return $dir
        }
        if (Test-Path "$dir/bin/skill.ps1") {
            return $dir
        }
        $dir = Split-Path -Parent $dir
    }
    Write-Die "Could not find skills-registry root directory"
}
