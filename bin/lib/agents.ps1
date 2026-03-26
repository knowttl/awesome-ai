# agents.ps1 — agent path registry and detection

$script:AgentTable = @(
    @{ Name="claude-code";     ProjectPath=".claude/skills";            GlobalSuffix=".claude/skills";               DetectDirs=@(".claude");             DetectBins=@("claude") }
    @{ Name="github-copilot";  ProjectPath=".github/copilot/skills";   GlobalSuffix=".copilot/skills";              DetectDirs=@(".copilot",".github");  DetectBins=@("copilot") }
    @{ Name="cursor";          ProjectPath=".agents/skills";            GlobalSuffix=".cursor/skills";               DetectDirs=@(".cursor");             DetectBins=@("cursor") }
    @{ Name="cline";           ProjectPath=".agents/skills";            GlobalSuffix=".agents/skills";               DetectDirs=@(".cline");              DetectBins=@("cline") }
    @{ Name="opencode";        ProjectPath=".agents/skills";            GlobalSuffix=".config/opencode/skills";      DetectDirs=@(".config/opencode");    DetectBins=@("opencode") }
    @{ Name="codex";           ProjectPath=".agents/skills";            GlobalSuffix=".codex/skills";                DetectDirs=@(".codex");              DetectBins=@("codex") }
    @{ Name="windsurf";        ProjectPath=".windsurf/skills";          GlobalSuffix=".codeium/windsurf/skills";     DetectDirs=@(".codeium/windsurf");   DetectBins=@("windsurf") }
    @{ Name="roo";             ProjectPath=".roo/skills";               GlobalSuffix=".roo/skills";                  DetectDirs=@(".roo");                DetectBins=@("roo") }
)

function Get-ProjectPath {
    param([string]$Agent)
    $entry = $script:AgentTable | Where-Object { $_.Name -eq $Agent }
    if ($entry) { return $entry.ProjectPath }
    return ""
}

function Get-GlobalPath {
    param([string]$Agent)
    $entry = $script:AgentTable | Where-Object { $_.Name -eq $Agent }
    if ($entry) { return Join-Path $HOME $entry.GlobalSuffix }
    return ""
}

function Get-KnownAgents {
    return $script:AgentTable | ForEach-Object { $_.Name }
}

function Find-InstalledAgents {
    $found = @()
    foreach ($entry in $script:AgentTable) {
        $detected = $false
        foreach ($dir in $entry.DetectDirs) {
            if (Test-Path (Join-Path $HOME $dir)) {
                $detected = $true
                break
            }
        }
        if (-not $detected) {
            foreach ($bin in $entry.DetectBins) {
                if (Get-Command $bin -ErrorAction SilentlyContinue) {
                    $detected = $true
                    break
                }
            }
        }
        if ($detected) { $found += $entry.Name }
    }
    return $found
}

function Select-Agents {
    param([string[]]$Compatible)
    $detected = Find-InstalledAgents
    Write-Host "`nDetected agents: $($detected -join ', ')" -ForegroundColor Cyan
    Write-Host ""

    $selected = @()
    foreach ($agent in $Compatible) {
        $isDetected = $agent -in $detected
        if ($env:SKILL_YES -eq "1") {
            if ($isDetected) { $selected += $agent }
        } else {
            $suffix = if ($isDetected) { " (detected)" } else { "" }
            $answer = Read-Host "  Install to $agent$suffix? (y/n)"
            if ($answer -match '^[Yy]' -or ($answer -eq '' -and $isDetected)) {
                $selected += $agent
            }
        }
    }
    return $selected
}
