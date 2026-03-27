#Requires -Version 5.1
param([Parameter(ValueFromRemainingArguments)]$CmdArgs)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$CommandsDir = Join-Path $ScriptDir "commands"
. (Join-Path $ScriptDir "lib/common.ps1")

$Version = "0.1.0"

function Show-Usage {
    Write-Host "skill — AI skills registry CLI (v$Version)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage:  skill <command> [options]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  list, search, info, install, uninstall, update, sync"
    Write-Host ""
    Write-Host "Run 'skill <command> --help' for command-specific help."
}

if ($CmdArgs.Count -eq 0) { Show-Usage; exit 0 }

$Cmd = $CmdArgs[0]
$Rest = @()
if ($CmdArgs.Count -gt 1) { $Rest = $CmdArgs[1..($CmdArgs.Count - 1)] }

switch ($Cmd) {
    { $_ -in @("list","search","info","install","uninstall","update","sync") } {
        $script = Join-Path $CommandsDir "$Cmd.ps1"
        if (-not (Test-Path $script)) { Write-Die "Command script not found: $script" }
        & $script @Rest
    }
    { $_ -in @("--help","-h") } { Show-Usage; exit 0 }
    "--version" { Write-Host "skill v$Version"; exit 0 }
    default { Write-Die "Unknown command: $Cmd`nRun 'skill --help' for usage." }
}
