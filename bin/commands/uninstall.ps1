# uninstall.ps1 — remove an installed item

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")
. (Join-Path $CmdDir "../lib/agents.ps1")
. (Join-Path $CmdDir "../lib/lock.ps1")

$TargetDir = Get-Location | Select-Object -ExpandProperty Path
$GlobalInstall = $false; $AgentArgs = @(); $Name = ""

$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--target"   { $TargetDir = $args[++$i] }
        { $_ -in @("--global","-g") } { $GlobalInstall = $true }
        { $_ -in @("--agent","-a") }  { $AgentArgs += $args[++$i] }
        { $_ -in @("--yes","-y") }    { $env:SKILL_YES = "1" }
        { $_ -in @("--help","-h") }   {
            Write-Host "Usage: skill uninstall <name> [--target <path>] [--global] [--agent <agent>]"
            exit 0
        }
        default {
            if ($_.StartsWith("-")) { Write-Die "Unknown flag: $_" }
            else { $Name = $_ }
        }
    }
    $i++
}

if (-not $Name) { Write-Die "Usage: skill uninstall <name>" }

$lockPath = if ($GlobalInstall) { Join-Path $HOME ".skills-lock.json" } else { Join-Path $TargetDir ".skills-lock.json" }

# Determine agents
if ($AgentArgs.Count -gt 0) {
    $removeAgents = $AgentArgs
} elseif (Test-LockEntry -Path $lockPath -Name $Name) {
    $agents = Get-LockEntryField -Path $lockPath -Name $Name -Field "agents"
    $removeAgents = if ($agents -is [array]) { $agents } else { @($agents) }
} else {
    $removeAgents = Get-KnownAgents
}

$removed = $false
foreach ($agent in $removeAgents) {
    $basePath = if ($GlobalInstall) { Get-GlobalPath $agent } else { Join-Path $TargetDir (Get-ProjectPath $agent) }
    if (-not $basePath) { continue }

    $skillDir = Join-Path $basePath $Name
    if (Test-Path $skillDir) {
        if (Confirm-Prompt "Remove $skillDir?") {
            Remove-Item -Recurse -Force $skillDir
            $relPath = if ($GlobalInstall) { $skillDir } else { $skillDir.Replace("$TargetDir\","").Replace("\","/") }
            Write-Host "  -> Removed: $relPath"
            $removed = $true
        }
    }
}

if ($removed -and (Test-LockEntry -Path $lockPath -Name $Name)) {
    Remove-LockEntry -Path $lockPath -Name $Name
    Write-Info "Uninstalled $Name"
    Write-Host "  Lock file updated: $(Split-Path $lockPath -Leaf)"
} elseif (-not $removed) {
    Write-Warn "No installed files found for: $Name"
}
