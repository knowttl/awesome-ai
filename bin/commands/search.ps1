# search.ps1 — full-text search across registry

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$RegistryFile = Join-Path $RegistryRoot "registry.json"

$Query = ""; $Type = ""; $Tag = ""; $For = ""
$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--type" { $Type = $args[++$i] }
        "--tag"  { $Tag = $args[++$i] }
        "--for"  { $For = $args[++$i] }
        { $_ -in @("--help","-h") } {
            Write-Host "Usage: skill search <query> [--type <type>] [--tag <tag>] [--for <agent>]"
            exit 0
        }
        default { if (-not $_.StartsWith("-")) { $Query = $_ } else { Write-Die "Unknown flag: $_" } }
    }
    $i++
}

if (-not $Query) { Write-Die "Usage: skill search <query>" }
if (-not (Test-Path $RegistryFile)) { Write-Warn "No registry.json found. Run 'skill sync' first."; exit 1 }

$registry = Get-Content $RegistryFile -Raw | ConvertFrom-Json
$items = $registry.items

if ($Type) { $items = $items | Where-Object { $_.type -eq $Type } }
if ($Tag)  { $items = $items | Where-Object { $_.tags -contains $Tag } }
if ($For)  { $items = $items | Where-Object { $_.targets -contains $For } }

$ql = $Query.ToLower()
$items = $items | Where-Object {
    $searchable = "$($_.name) $($_.description) $($_.tags -join ' ')".ToLower()
    $searchable.Contains($ql)
}

if ($items.Count -eq 0) {
    Write-Host "No items found matching: $Query"
} else {
    $items | Format-Table @(
        @{Label="NAME"; Expression={$_.name}; Width=30}
        @{Label="TYPE"; Expression={$_.type}; Width=12}
        @{Label="VERSION"; Expression={$_.version}; Width=8}
        @{Label="DESCRIPTION"; Expression={
            if ($_.description.Length -gt 50) { $_.description.Substring(0,47) + "..." } else { $_.description }
        }}
    ) -AutoSize
}
