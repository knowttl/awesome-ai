# update.ps1 — pull latest skills from an upstream repo into the local registry

$CmdDir = $PSScriptRoot
. (Join-Path $CmdDir "../lib/common.ps1")
. (Join-Path $CmdDir "../lib/git.ps1")

$RegistryRoot = if ($env:REGISTRY_ROOT) { $env:REGISTRY_ROOT } else { Resolve-RegistryRoot }

$DefaultUpstream = "obra/superpowers"
$Upstream = ""
$Ref = ""
$DryRun = $false
$Force = $false
$Items = @()

$i = 0
while ($i -lt $args.Count) {
    switch ($args[$i]) {
        "--ref"      { $Ref = $args[++$i] }
        "--dry-run"  { $DryRun = $true }
        { $_ -in @("--force","-f") } { $Force = $true }
        { $_ -in @("--item","-i") }  { $Items += $args[++$i] }
        { $_ -in @("--yes","-y") }   { $env:SKILL_YES = "1" }
        { $_ -in @("--help","-h") }  {
            Write-Host @"
Usage: skill update [<url|owner/repo>] [options]

Pull the latest skills from an upstream repository and update local copies.

  skill update                         Update from $DefaultUpstream
  skill update obra/superpowers        Update from a GitHub repo
  skill update <url>                   Update from any Git URL
  skill update --item brainstorming    Update a specific item only

Options:
  --item, -i <name>   Update only the named item(s), repeatable
  --ref <commit>      Fetch a specific commit/tag/branch
  --dry-run           Show what would change without modifying files
  --force, -f         Overwrite without prompting
  --yes, -y           Auto-accept prompts
"@
            exit 0
        }
        default {
            if ($_.StartsWith("-")) { Write-Die "Unknown flag: $_" }
            else { $Upstream = $_ }
        }
    }
    $i++
}

if (-not $Upstream) { $Upstream = $DefaultUpstream }

# --- Clone upstream ---
if (Test-IsUrl $Upstream) {
    $SourceUrl = $Upstream
} elseif (Test-IsShorthand $Upstream) {
    $SourceUrl = "https://github.com/$Upstream.git"
} else {
    Write-Die "Cannot resolve '$Upstream' as a URL or owner/repo shorthand"
}
Write-Host "Fetching upstream: $SourceUrl"
$TempClone = Invoke-ShallowClone -Url $SourceUrl -Commit $Ref

try {
    $UpstreamCommit = Get-RepoCommit -RepoDir $TempClone
    Write-Host "  Commit: $($UpstreamCommit.Substring(0, 10))"
    Write-Host ""

    # --- Scan upstream for items ---
    $foundItems = Find-RepoItems -RepoDir $TempClone
    if ($foundItems.Count -eq 0) {
        Write-Die "No skills/instructions found in $Upstream"
    }

    # --- Compare and update ---
    $Updated = 0
    $Skipped = 0
    $NewItems = @()

    foreach ($remoteDir in $foundItems) {
        $remoteDir = $remoteDir.TrimEnd('\', '/')

        # Read remote manifest
        $manifestPath = Join-Path $remoteDir "manifest.yaml"
        if (-not (Test-Path $manifestPath)) { continue }

        $mc = Get-Content $manifestPath -Raw
        $remoteName = Read-YamlField -Content $mc -Key "name"
        $remoteType = Read-YamlField -Content $mc -Key "type"
        $remoteVersion = Read-YamlField -Content $mc -Key "version"

        if (-not $remoteName) { $remoteName = Split-Path $remoteDir -Leaf }
        if (-not $remoteType) { $remoteType = "skill" }
        if (-not $remoteVersion) { $remoteVersion = "0.0.0" }

        # If --item filter is set, skip non-matching
        if ($Items.Count -gt 0 -and $remoteName -notin $Items) { continue }

        # Determine local type directory
        $localTypeDir = switch ($remoteType) {
            "instruction" { "instructions" }
            default { "skills" }
        }

        $localDir = Join-Path $RegistryRoot (Join-Path $localTypeDir $remoteName)

        if (-not (Test-Path $localDir)) {
            $NewItems += "$remoteName ($remoteType)"
            continue
        }

        # Compare files
        $changedFiles = @()
        $remoteFiles = Read-YamlList -Content $mc -Key "files"
        $allFiles = @("manifest.yaml") + $remoteFiles

        foreach ($file in $allFiles) {
            if (-not $file) { continue }
            $remoteFile = Join-Path $remoteDir $file
            $localFile = Join-Path $localDir $file

            if (-not (Test-Path $remoteFile)) { continue }

            if (-not (Test-Path $localFile)) {
                $changedFiles += "$file (new)"
            } else {
                $remoteHash = (Get-FileHash $remoteFile -Algorithm SHA256).Hash
                $localHash = (Get-FileHash $localFile -Algorithm SHA256).Hash
                if ($remoteHash -ne $localHash) {
                    $changedFiles += $file
                }
            }
        }

        if ($changedFiles.Count -eq 0) {
            $Skipped++
            continue
        }

        # Show changes
        Write-Host "$remoteName ($remoteType v$remoteVersion)" -ForegroundColor White
        foreach ($cf in $changedFiles) {
            Write-Host "  ~ $cf"
        }

        if ($DryRun) {
            $Updated++
            Write-Host ""
            continue
        }

        # Prompt unless --force or --yes
        if (-not $Force -and $env:SKILL_YES -ne "1") {
            if (-not (Confirm-Prompt "  Update ${remoteName}?")) {
                $Skipped++
                Write-Host ""
                continue
            }
        }

        # Copy files
        foreach ($file in $allFiles) {
            if (-not $file) { continue }
            $remoteFile = Join-Path $remoteDir $file
            $localFile = Join-Path $localDir $file

            if (-not (Test-Path $remoteFile)) { continue }

            $parentDir = Split-Path $localFile -Parent
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            Copy-Item $remoteFile $localFile -Force
        }

        $Updated++
        Write-Host ""
    }

    # --- Summary ---
    Write-Host "---"
    if ($DryRun) {
        Write-Host "Dry run: $Updated item(s) would be updated, $Skipped unchanged"
    } else {
        if ($Updated -gt 0) {
            Write-Info "Updated $Updated item(s) from upstream"
            Write-Host "  Run 'skill sync' to regenerate the registry index."
        } else {
            Write-Host "All local items are up to date."
        }
    }

    if ($NewItems.Count -gt 0) {
        Write-Host ""
        Write-Host "New items available upstream:" -ForegroundColor White
        foreach ($ni in $NewItems) {
            Write-Host "  + $ni"
        }
        Write-Host "  Use 'skill install $Upstream --skill <name>' to add them."
    }
} finally {
    Remove-TempClone $TempClone
}
