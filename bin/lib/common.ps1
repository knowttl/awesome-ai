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
    # Reads a scalar field. Handles inline values (quoted or bare, including
    # values containing apostrophes) and folded/literal block scalars
    # (`Key: >` / `Key: |`), folding continuation lines into a space-joined string.
    param([string]$Content, [string]$Key)
    $inBlock = $false
    $val = ""
    foreach ($rawLine in ($Content -split "`n")) {
        $line = $rawLine -replace "`r$", ""
        if ($inBlock) {
            if ($line -match '^\s*$') { continue }            # blank line inside block: fold away
            if ($line -match '^\s+\S') {                       # indented continuation
                $t = $line.Trim()
                if ($val -eq "") { $val = $t } else { $val = "$val $t" }
                continue
            }
            return $val                                        # dedented: block ended
        }
        if ($line -match "^${Key}:\s*(.*?)\s*$") {
            $rest = $Matches[1]
            if ($rest -match '^[>|][+-]?$') { $inBlock = $true; $val = ""; continue }
            if ( (($rest.StartsWith('"')) -and ($rest.EndsWith('"'))) -or (($rest.StartsWith("'")) -and ($rest.EndsWith("'"))) ) {
                if ($rest.Length -ge 2) { $rest = $rest.Substring(1, $rest.Length - 2) }
            }
            return $rest
        }
    }
    if ($inBlock) { return $val }
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
