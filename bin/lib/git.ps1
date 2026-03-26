# git.ps1 — git operations for remote skill fetching

function ConvertTo-RepoUrl {
    param([string]$Shorthand)
    return "https://github.com/$Shorthand.git"
}

function Resolve-RepoUrl {
    param([string]$Input)
    if (Test-IsUrl $Input) { return $Input }
    if (Test-IsShorthand $Input) { return ConvertTo-RepoUrl $Input }
    Write-Die "Cannot resolve '$Input' as a URL or owner/repo shorthand"
}

function Invoke-ShallowClone {
    param([string]$Url, [string]$Commit = "")
    $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "skills-registry-$(Get-Random)"
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    if ($Commit) {
        git init $tmpDir --quiet
        git -C $tmpDir remote add origin $Url
        $fetched = $false
        try {
            git -C $tmpDir fetch --depth 1 origin $Commit --quiet 2>$null
            git -C $tmpDir checkout FETCH_HEAD --quiet 2>$null
            $fetched = $true
        } catch { }
        if (-not $fetched) {
            Remove-Item -Recurse -Force $tmpDir
            $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "skills-registry-$(Get-Random)"
            git clone --depth 1 $Url $tmpDir --quiet
        }
    } else {
        git clone --depth 1 $Url $tmpDir --quiet
        if ($LASTEXITCODE -ne 0) { Write-Die "Failed to clone $Url" }
    }
    return $tmpDir
}

function Get-RepoCommit {
    param([string]$RepoDir)
    return (git -C $RepoDir rev-parse HEAD).Trim()
}

function Remove-TempClone {
    param([string]$Dir)
    $tempRoot = [System.IO.Path]::GetTempPath()
    if ($Dir.StartsWith($tempRoot) -and (Test-Path $Dir)) {
        Remove-Item -Recurse -Force $Dir
    }
}

function Find-RepoItems {
    param([string]$RepoDir)
    $found = @()
    foreach ($subdir in @("skills", "agents", "instructions", ".claude/skills", ".agents/skills")) {
        $fullPath = Join-Path $RepoDir $subdir
        if (Test-Path $fullPath) {
            foreach ($itemDir in Get-ChildItem -Path $fullPath -Directory) {
                if (Test-Path (Join-Path $itemDir.FullName "manifest.yaml")) {
                    $found += $itemDir.FullName
                } elseif (Test-Path (Join-Path $itemDir.FullName "SKILL.md")) {
                    New-SyntheticManifest -ItemDir $itemDir.FullName | Out-Null
                    $found += $itemDir.FullName
                }
            }
        }
    }
    if (Test-Path (Join-Path $RepoDir "manifest.yaml")) {
        $found += $RepoDir
    } elseif (Test-Path (Join-Path $RepoDir "SKILL.md")) {
        New-SyntheticManifest -ItemDir $RepoDir | Out-Null
        $found += $RepoDir
    }
    return $found
}

function New-SyntheticManifest {
    param([string]$ItemDir)
    $skillMd = Join-Path $ItemDir "SKILL.md"
    $manifestPath = Join-Path $ItemDir "manifest.yaml"

    if (-not (Test-Path $skillMd)) { return $false }
    if (Test-Path $manifestPath) { return $true }

    $content = Get-Content $skillMd -Raw
    # Extract frontmatter
    if ($content -match '(?s)^---\r?\n(.+?)\r?\n---') {
        $fm = $Matches[1]
        $name = Read-YamlField -Content $fm -Key "name"
        $description = Read-YamlField -Content $fm -Key "description"
    }
    if (-not $name) { $name = Split-Path $ItemDir -Leaf }
    if (-not $description) { $description = "Skill imported from external repository" }

    @"
name: $name
type: skill
description: $description
tags: []
targets:
  - claude-code
  - github-copilot
files:
  - SKILL.md
version: "0.0.0"
"@ | Set-Content -Path $manifestPath -Encoding UTF8
    return $true
}
