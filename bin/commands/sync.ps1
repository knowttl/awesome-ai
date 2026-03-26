# sync.ps1 — regenerate registry.json

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$OutputFile = Join-Path $RegistryRoot "registry.json"

$items = @()
foreach ($contentDir in @("skills", "agents", "instructions")) {
    $dirPath = Join-Path $RegistryRoot $contentDir
    if (-not (Test-Path $dirPath)) { continue }

    foreach ($itemDir in Get-ChildItem -Path $dirPath -Directory) {
        $mp = Join-Path $itemDir.FullName "manifest.yaml"
        if (-not (Test-Path $mp)) { continue }

        $c = Get-Content $mp -Raw
        $version = Read-YamlField -Content $c -Key "version"
        if (-not $version) { $version = "0.0.0" }

        $items += [ordered]@{
            name         = Read-YamlField -Content $c -Key "name"
            type         = Read-YamlField -Content $c -Key "type"
            description  = Read-YamlField -Content $c -Key "description"
            tags         = @(Read-YamlList -Content $c -Key "tags")
            targets      = @(Read-YamlList -Content $c -Key "targets")
            files        = @(Read-YamlList -Content $c -Key "files")
            dependencies = @(Read-YamlList -Content $c -Key "dependencies")
            version      = $version
            path         = "$contentDir/$($itemDir.Name)"
        }
    }
}

[ordered]@{
    version     = 1
    generatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    items       = $items
} | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Encoding UTF8

Write-Info "Registry updated: $($items.Count) items -> registry.json"
