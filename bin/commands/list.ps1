# list.ps1 — list all items in the registry

param(
    [string]$Type,
    [string]$Tag,
    [string]$For
)

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$RegistryFile = Join-Path $RegistryRoot "registry.json"

# Parse args
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--type" { $Type = $args[++$i] }
        "--tag"  { $Tag = $args[++$i] }
        "--for"  { $For = $args[++$i] }
        { $_ -in @("--help","-h") } {
            Write-Host "Usage: skill list [--type <type>] [--tag <tag>] [--for <agent>]"
            exit 0
        }
    }
    $i++
}

if (-not (Test-Path $RegistryFile)) {
    Write-Warn "No registry.json found. Run 'skill sync' first."
    exit 1
}

$registry = Get-Content $RegistryFile -Raw | ConvertFrom-Json
$items = $registry.items

if ($Type) { $items = $items | Where-Object { $_.type -eq $Type } }
if ($Tag)  { $items = $items | Where-Object { $_.tags -contains $Tag } }
if ($For)  { $items = $items | Where-Object { $_.targets -contains $For } }

$items | Format-Table @(
    @{Label="NAME"; Expression={$_.name}; Width=30}
    @{Label="TYPE"; Expression={$_.type}; Width=12}
    @{Label="VERSION"; Expression={$_.version}; Width=8}
    @{Label="DESCRIPTION"; Expression={
        if ($_.description.Length -gt 50) { $_.description.Substring(0,47) + "..." } else { $_.description }
    }}
) -AutoSize
