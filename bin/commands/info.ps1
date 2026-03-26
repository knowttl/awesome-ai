# info.ps1 — show full details for a single item

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$RegistryFile = Join-Path $RegistryRoot "registry.json"

if ($args.Count -eq 0 -or $args[0] -in @("--help", "-h")) {
    Write-Host "Usage: skill info <name>"
    exit 0
}

$Name = $args[0]

if (-not (Test-Path $RegistryFile)) {
    Write-Warn "No registry.json found. Run 'skill sync' first."
    exit 1
}

$registry = Get-Content $RegistryFile -Raw | ConvertFrom-Json
$item = $registry.items | Where-Object { $_.name -eq $Name }

if (-not $item) {
    Write-Die "Item not found: $Name"
}

Write-Host ""
Write-Host "  $($item.name)  ($($item.type) v$($item.version))" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Description:  $($item.description)"
Write-Host "  Path:         $($item.path)"
Write-Host "  Tags:         $($item.tags -join ', ')"
Write-Host "  Targets:      $($item.targets -join ', ')"
Write-Host "  Files:        $($item.files -join ', ')"
if ($item.dependencies.Count -gt 0) {
    Write-Host "  Dependencies: $($item.dependencies -join ', ')"
}
Write-Host ""
