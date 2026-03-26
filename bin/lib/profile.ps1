# profile.ps1 — profile loading and installation

function Install-Profile {
    param(
        [string]$ProfileName, [string]$TargetDir,
        [bool]$GlobalInstall, [bool]$UseSymlink, [string[]]$AgentsOverride
    )

    $RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
    $profileFile = Join-Path $RegistryRoot "profiles/$ProfileName.yaml"
    if (-not (Test-Path $profileFile)) { Write-Die "Profile not found: $ProfileName" }

    $content = Get-Content $profileFile -Raw
    $description = Read-YamlField -Content $content -Key "description"

    Write-Host "`nInstalling profile: $ProfileName" -ForegroundColor Cyan
    if ($description) { Write-Host "  $description" }
    Write-Host ""

    # Parse items
    $lines = $content -split "`n"
    $inItems = $false; $items = @()
    $currentItem = @{}

    foreach ($line in $lines) {
        if ($line -match '^items:') { $inItems = $true; continue }
        if ($inItems -and $line -match '^\S' -and $line -notmatch '^items:') { break }
        if ($inItems -and $line -match '^\s+-\s+name:\s*(.+)') {
            if ($currentItem.Count -gt 0) { $items += [PSCustomObject]$currentItem }
            $currentItem = @{ name = $Matches[1].Trim(); source = ""; ref = "" }
        }
        if ($inItems -and $line -match '^\s+source:\s*(.+)') { $currentItem.source = $Matches[1].Trim() }
        if ($inItems -and $line -match '^\s+ref:\s*(.+)') { $currentItem.ref = $Matches[1].Trim() }
    }
    if ($currentItem.Count -gt 0) { $items += [PSCustomObject]$currentItem }

    $installScript = Join-Path $PSScriptRoot "../commands/install.ps1"
    $count = 0

    foreach ($item in $items) {
        Write-Host "  Installing: $($item.name) (from $($item.source))..."

        $installArgs = @("--target", $TargetDir, "--yes")
        if ($GlobalInstall) { $installArgs += "--global" }
        if ($UseSymlink) { $installArgs += "--symlink" }
        foreach ($a in $AgentsOverride) { $installArgs += @("--agent", $a) }

        if ($item.source -eq "local") {
            & $installScript $item.name @installArgs
        } else {
            & $installScript $item.source @installArgs --skill $item.name
        }
        $count++
    }

    Write-Host ""
    Write-Info "Profile '$ProfileName' installed: $count items"
}
