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

    Write-Host "Restoring from .skills-lock.json..."
    $entries = Get-LockEntries -Path $lockPath
    $count = 0

    foreach ($entryName in $entries) {
        $source = Get-LockEntryField -Path $lockPath -Name $entryName -Field "source"
        $url = Get-LockEntryField -Path $lockPath -Name $entryName -Field "sourceUrl"
        $commit = Get-LockEntryField -Path $lockPath -Name $entryName -Field "sourceCommit"

        $restoreArgs = @("--target", $TargetDir, "--yes")
        $agents = Get-LockEntryField -Path $lockPath -Name $entryName -Field "agents"
        # Parse agents from the stored value
        if ($agents -is [array]) {
            foreach ($a in $agents) { $restoreArgs += @("--agent", $a) }
        }

        if ($source -eq "remote" -and $url) {
            $refArgs = @()
            if ($commit) { $refArgs = @("--ref", $commit) }
            & (Join-Path $CmdDir "install.ps1") $url @restoreArgs @refArgs --skill $entryName
        } else {
            & (Join-Path $CmdDir "install.ps1") $entryName @restoreArgs
        }
        $count++
    }

    Write-Info "Restored $count items from lock file"
    exit 0
}

# Profile install
if ($Profile) {
    . (Join-Path $CmdDir "../lib/profile.ps1")
    Install-Profile -ProfileName $Profile -TargetDir $TargetDir `
        -GlobalInstall $GlobalInstall -UseSymlink $UseSymlink -AgentsOverride $AgentArgs
    exit 0
}

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

# Deduplicate: github-copilot reads .claude/skills, so skip it when claude-code is also selected
$Selected = Remove-DuplicateAgents -Agents $Selected

if ($Selected.Count -eq 0) {
    Write-Warn "No agents selected."
    if ($TempClone) { Remove-TempClone $TempClone }
    exit 0
}

# Install files
$lockPath = if ($GlobalInstall) { Join-Path $HOME ".skills-lock.json" } else { Join-Path $TargetDir ".skills-lock.json" }

foreach ($agent in $Selected) {
    $pathSuffix = if ($GlobalInstall) { Get-GlobalPath $agent } else { Get-ProjectPath $agent }
    if (-not $pathSuffix) { Write-Warn "Unknown agent: $agent"; continue }
    $basePath = if ($GlobalInstall) { $pathSuffix } elseif ($agent -eq "claude-code") { Join-Path $TargetDir ".agents/skills" } else { Join-Path $TargetDir $pathSuffix }

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

    if ($agent -eq "claude-code" -and -not $GlobalInstall) {
        $claudeSkillsDir = Join-Path $TargetDir ".claude/skills"
        $symlinkTarget = "../../.agents/skills/$ItemName"
        New-Item -ItemType Directory -Path $claudeSkillsDir -Force | Out-Null
        $symlinkPath = Join-Path $claudeSkillsDir $ItemName
        if (Test-Path $symlinkPath) { Remove-Item $symlinkPath -Force }
        New-Item -ItemType SymbolicLink -Path $symlinkPath -Target $symlinkTarget -Force | Out-Null
        Write-Host "  -> claude-code: .claude/skills/$ItemName -> .agents/skills/$ItemName"
    } else {
        $relDest = if ($GlobalInstall) { $destDir } else { $destDir.Replace("$TargetDir\", "").Replace("\", "/") }
        Write-Host "  -> ${agent}: $relDest"
    }
}

# Update lock
Add-LockEntry -Path $lockPath -Name $ItemName -Type $ItemType -Version $ItemVersion `
    -Source $SourceType -SourceUrl $SourceUrl -SourceCommit $SourceCommit `
    -Agents $Selected -Profile ""

Write-Info "Installed $ItemName ($ItemType v$ItemVersion)"
Write-Host "  Lock file updated: $(Split-Path $lockPath -Leaf)"

if ($TempClone) { Remove-TempClone $TempClone }
