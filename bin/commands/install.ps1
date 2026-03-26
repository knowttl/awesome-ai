# install.ps1 — install skills/agents/instructions into a target project

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")
. (Join-Path $CmdDir "../lib/agents.ps1")
. (Join-Path $CmdDir "../lib/git.ps1")
. (Join-Path $CmdDir "../lib/lock.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }
$RegistryFile = Join-Path $RegistryRoot "registry.json"

# Parse arguments
$TargetDir = Get-Location | Select-Object -ExpandProperty Path
$GlobalInstall = $false
$UseSymlink = $false
$AgentArgs = @()
$SkillArgs = @()
$Profile = ""
$Ref = ""
$Positional = ""

$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--target"   { $TargetDir = $args[++$i] }
        { $_ -in @("--global","-g") } { $GlobalInstall = $true }
        "--symlink"  { $UseSymlink = $true }
        { $_ -in @("--agent","-a") }  { $AgentArgs += $args[++$i] }
        { $_ -in @("--skill","-s") }  { $SkillArgs += $args[++$i] }
        "--profile"  { $Profile = $args[++$i] }
        "--ref"      { $Ref = $args[++$i] }
        { $_ -in @("--yes","-y") }    { $env:SKILL_YES = "1" }
        { $_ -in @("--help","-h") }   {
            Write-Host "Usage: skill install [<name|url>] [options]"; exit 0
        }
        default {
            if ($_.StartsWith("-")) { Write-Die "Unknown flag: $_" }
            else { $Positional = $_ }
        }
    }
    $i++
}

# Lock-file restore (no args)
if (-not $Positional -and -not $Profile) {
    $lockPath = Join-Path $TargetDir ".skills-lock.json"
    if (-not (Test-Path $lockPath)) {
        Write-Die "No item specified and no .skills-lock.json found in $TargetDir"
    }
    # Delegate to lock restore (Task 12)
    Write-Die "Lock restore not yet implemented"
}

# Profile install (Task 13)
if ($Profile) { Write-Die "Profile install not yet implemented" }

# Resolve source
$ItemName = ""; $ItemDir = ""; $SourceType = "local"
$SourceUrl = ""; $SourceCommit = ""; $TempClone = ""

if ((Test-IsUrl $Positional) -or (Test-IsShorthand $Positional)) {
    $SourceType = "remote"
    $SourceUrl = Resolve-RepoUrl $Positional
    Write-Host "Cloning $SourceUrl..."
    $TempClone = Invoke-ShallowClone -Url $SourceUrl -Commit $Ref
    $SourceCommit = Get-RepoCommit -RepoDir $TempClone

    $foundItems = Find-RepoItems -RepoDir $TempClone
    if ($foundItems.Count -eq 0) {
        Remove-TempClone $TempClone
        Write-Die "No items found in $Positional"
    }

    if ($SkillArgs.Count -gt 0) {
        $foundItems = $foundItems | Where-Object {
            $manifest = Join-Path $_ "manifest.yaml"
            if (Test-Path $manifest) {
                $n = Read-YamlField -Content (Get-Content $manifest -Raw) -Key "name"
                $n -in $SkillArgs
            } else { (Split-Path $_ -Leaf) -in $SkillArgs }
        }
    }

    $ItemDir = $foundItems | Select-Object -First 1
    $manifest = Join-Path $ItemDir "manifest.yaml"
    if (Test-Path $manifest) {
        $ItemName = Read-YamlField -Content (Get-Content $manifest -Raw) -Key "name"
    } else { $ItemName = Split-Path $ItemDir -Leaf }
} else {
    $ItemName = $Positional
    if (-not (Test-Path $RegistryFile)) { Write-Die "No registry.json. Run 'skill sync' first." }

    $reg = Get-Content $RegistryFile -Raw | ConvertFrom-Json
    $item = $reg.items | Where-Object { $_.name -eq $ItemName }
    if (-not $item) { Write-Die "Item not found: $ItemName" }
    $ItemDir = Join-Path $RegistryRoot $item.path
}

# Read manifest
$manifestPath = Join-Path $ItemDir "manifest.yaml"
if (-not (Test-Path $manifestPath)) { Write-Die "No manifest.yaml in $ItemDir" }

$mc = Get-Content $manifestPath -Raw
$ItemType = Read-YamlField -Content $mc -Key "type"
$ItemVersion = Read-YamlField -Content $mc -Key "version"
if (-not $ItemVersion) { $ItemVersion = "0.0.0" }
$ItemTargets = Read-YamlList -Content $mc -Key "targets"
$ItemFiles = Read-YamlList -Content $mc -Key "files"

# Select agents
if ($AgentArgs.Count -eq 0) {
    $Selected = Select-Agents -Compatible $ItemTargets
} else {
    $Selected = $AgentArgs
}

if ($Selected.Count -eq 0) {
    Write-Warn "No agents selected."
    if ($TempClone) { Remove-TempClone $TempClone }
    exit 0
}

# Install files
$lockPath = if ($GlobalInstall) { Join-Path $HOME ".skills-lock.json" } else { Join-Path $TargetDir ".skills-lock.json" }

foreach ($agent in $Selected) {
    $basePath = if ($GlobalInstall) { Get-GlobalPath $agent } else { Join-Path $TargetDir (Get-ProjectPath $agent) }
    if (-not $basePath) { Write-Warn "Unknown agent: $agent"; continue }

    $destDir = Join-Path $basePath $ItemName
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null

    foreach ($file in $ItemFiles) {
        $src = Join-Path $ItemDir $file
        $dst = Join-Path $destDir $file
        if (-not (Test-Path $src)) { Write-Warn "File not found: $src"; continue }

        if (Test-Path $dst) {
            if ((Get-FileHash $src).Hash -eq (Get-FileHash $dst).Hash) { continue }
            if (-not (Confirm-Prompt "File exists and differs: $dst. Overwrite?")) { continue }
        }

        $dstParent = Split-Path $dst -Parent
        New-Item -ItemType Directory -Path $dstParent -Force | Out-Null

        if ($UseSymlink) {
            New-Item -ItemType SymbolicLink -Path $dst -Target $src -Force | Out-Null
        } else {
            Copy-Item $src $dst -Force
        }
    }

    $relDest = if ($GlobalInstall) { $destDir } else { $destDir.Replace("$TargetDir\", "").Replace("\", "/") }
    Write-Host "  -> ${agent}: $relDest"
}

# Update lock
Add-LockEntry -Path $lockPath -Name $ItemName -Type $ItemType -Version $ItemVersion `
    -Source $SourceType -SourceUrl $SourceUrl -SourceCommit $SourceCommit `
    -Agents $Selected -Profile ""

Write-Info "Installed $ItemName ($ItemType v$ItemVersion)"
Write-Host "  Lock file updated: $(Split-Path $lockPath -Leaf)"

if ($TempClone) { Remove-TempClone $TempClone }
