# lock.ps1 — .skills-lock.json management

function Initialize-LockFile {
    param([string]$Path)
    @{ version = 1; installed = @{} } | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Confirm-LockFile {
    param([string]$Path)
    if (-not (Test-Path $Path)) { Initialize-LockFile -Path $Path }
}

function Test-LockEntry {
    param([string]$Path, [string]$Name)
    if (-not (Test-Path $Path)) { return $false }
    $lock = Get-Content $Path -Raw | ConvertFrom-Json
    return $null -ne $lock.installed.PSObject.Properties[$Name]
}

function Add-LockEntry {
    param(
        [string]$Path, [string]$Name, [string]$Type, [string]$Version,
        [string]$Source, [string]$SourceUrl, [string]$SourceCommit,
        [string[]]$Agents, [string]$Profile
    )
    Confirm-LockFile -Path $Path
    $lock = Get-Content $Path -Raw | ConvertFrom-Json

    $entry = [ordered]@{
        type = $Type; version = $Version; source = $Source
        sourceUrl = if ($SourceUrl) { $SourceUrl } else { $null }
        sourceCommit = if ($SourceCommit) { $SourceCommit } else { $null }
        installedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
        agents = $Agents
        profile = if ($Profile) { $Profile } else { $null }
    }

    if ($lock.installed.PSObject.Properties[$Name]) {
        $lock.installed.PSObject.Properties.Remove($Name)
    }
    $lock.installed | Add-Member -NotePropertyName $Name -NotePropertyValue ([PSCustomObject]$entry)
    $lock | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Remove-LockEntry {
    param([string]$Path, [string]$Name)
    if (-not (Test-Path $Path)) { return }
    $lock = Get-Content $Path -Raw | ConvertFrom-Json
    if ($lock.installed.PSObject.Properties[$Name]) {
        $lock.installed.PSObject.Properties.Remove($Name)
    }
    $lock | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Get-LockEntries {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @() }
    $lock = Get-Content $Path -Raw | ConvertFrom-Json
    return $lock.installed.PSObject.Properties | ForEach-Object { $_.Name }
}

function Get-LockEntryField {
    param([string]$Path, [string]$Name, [string]$Field)
    if (-not (Test-Path $Path)) { return "" }
    $lock = Get-Content $Path -Raw | ConvertFrom-Json
    $entry = $lock.installed.PSObject.Properties[$Name]
    if ($entry) { return $entry.Value.$Field }
    return ""
}
