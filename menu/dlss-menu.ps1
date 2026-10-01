#Requires -Version 5.1
<#
  GTA V Legacy - Clarity / Sharpening Menu
  Story Mode only - see README.md before using. Does not touch GTA Online in any way.
  Manages a ReShade install (you install ReShade yourself) for GTA V Legacy.
#>

$ErrorActionPreference = 'Stop'

$ScriptRoot   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot     = Split-Path -Parent $ScriptRoot
$SettingsPath = Join-Path $ScriptRoot 'settings.json'

function Load-Settings {
    if (Test-Path $SettingsPath) {
        return Get-Content $SettingsPath -Raw | ConvertFrom-Json
    }
    return [pscustomobject]@{ GamePath = $null; BackupPath = $null; Sharpness = 0.6 }
}

function Save-Settings {
    param($Settings)
    $Settings | ConvertTo-Json | Set-Content -Path $SettingsPath -Encoding UTF8
}

function Find-GTAVCandidates {
    $candidates = @(
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\Grand Theft Auto V\GTA5.exe",
        "${env:ProgramFiles}\Rockstar Games\Grand Theft Auto V\GTA5.exe",
        "${env:ProgramFiles(x86)}\Rockstar Games\Grand Theft Auto V\GTA5.exe",
        "${env:ProgramFiles}\Epic Games\GTAV\GTA5.exe",
        "D:\Steam\steamapps\common\Grand Theft Auto V\GTA5.exe",
        "D:\Games\Grand Theft Auto V\GTA5.exe"
    )
    $candidates | Where-Object { Test-Path $_ }
}

function Locate-Game {
    param($Settings)
    Write-Host "`nSearching common install locations..." -ForegroundColor Cyan
    $found = @(Find-GTAVCandidates)
    $choice = $null
    if ($found.Count -gt 0) {
        Write-Host "Found:" -ForegroundColor Green
        $i = 1
        foreach ($f in $found) { Write-Host "  [$i] $f"; $i++ }
        Write-Host "  [0] None of these / enter path manually"
        $choice = Read-Host "Pick a number"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $found.Count) {
            $Settings.GamePath = $found[[int]$choice - 1]
        }
    }
    if (-not $Settings.GamePath -or $choice -eq '0') {
        $manual = Read-Host "Paste the GTA V folder, or the full path to GTA5.exe"
        $manual = $manual.Trim('"')
        if (Test-Path $manual -PathType Leaf) {
            $Settings.GamePath = $manual
        } elseif (Test-Path $manual -PathType Container) {
            $exePath = Join-Path $manual 'GTA5.exe'
            if (Test-Path $exePath) {
                $Settings.GamePath = $exePath
            } else {
                Write-Host "No GTA5.exe found inside $manual" -ForegroundColor Red
            }
        } else {
            Write-Host "That path doesn't exist." -ForegroundColor Red
        }
    }
    Save-Settings $Settings
    return $Settings
}

function Require-GamePath {
    param($Settings)
    if (-not $Settings.GamePath -or -not (Test-Path $Settings.GamePath)) {
        Write-Host "GTA V path isn't set yet. Run option 1 first." -ForegroundColor Yellow
        return $false
    }
    return $true
}

function Get-GameDir {
    param($Settings)
    if (-not $Settings.GamePath) { return $null }
    Split-Path -Parent $Settings.GamePath
}

function Test-ReShadeInstalled {
    param($Settings)
    $dir = Get-GameDir $Settings
    if (-not $dir) { return $false }
    $dlls = @('dxgi.dll', 'd3d11.dll', 'd3d9.dll') | ForEach-Object { Join-Path $dir $_ } | Where-Object { Test-Path $_ }
    $ini = Join-Path $dir 'ReShade.ini'
    return (@($dlls).Count -gt 0 -and (Test-Path $ini))
}

function Backup-GameFiles {
    param($Settings)
    if (-not (Require-GamePath $Settings)) { return $Settings }
    $dir = Get-GameDir $Settings
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupDir = Join-Path $env:LOCALAPPDATA "GTAVLegacyDLSSMenu\backups\$stamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    $patterns = @('dxgi.dll', 'd3d11.dll', 'd3d9.dll', 'ReShade.ini', 'ReShadePreset.ini')
    $copied = 0
    foreach ($p in $patterns) {
        $src = Join-Path $dir $p
        if (Test-Path $src) {
            Copy-Item $src -Destination $backupDir
            $copied++
        }
    }
    $shadersDir = Join-Path $dir 'reshade-shaders'
    if (Test-Path $shadersDir) {
        Copy-Item $shadersDir -Destination $backupDir -Recurse
    }
    $Settings.BackupPath = $backupDir
    Save-Settings $Settings
    Write-Host "Backed up $copied file(s) to $backupDir" -ForegroundColor Green
    return $Settings
}

function Restore-GameFiles {
    param($Settings)
    if (-not $Settings.BackupPath -or -not (Test-Path $Settings.BackupPath)) {
        Write-Host "No backup recorded. Nothing to restore." -ForegroundColor Yellow
        return
    }
    $dir = Get-GameDir $Settings
    Get-ChildItem $Settings.BackupPath | ForEach-Object {
        Copy-Item $_.FullName -Destination $dir -Recurse -Force
    }
    Write-Host "Restored files from $($Settings.BackupPath)" -ForegroundColor Green
}

function Set-Sharpness {
    param($Settings)
    if (-not (Require-GamePath $Settings)) { return $Settings }
    $dir = Get-GameDir $Settings
    $preset = Join-Path $dir 'ReShadePreset.ini'
    if (-not (Test-Path $preset)) {
        Write-Host "No ReShadePreset.ini yet. Launch the game once, press Home, enable CAS in the overlay, then come back here." -ForegroundColor Yellow
        return $Settings
    }

    $value = Read-Host "Sharpness 0.0 - 1.0 (current target: $($Settings.Sharpness))"
    if ($value -notmatch '^\d*\.?\d+$') {
        Write-Host "Not a number, skipping." -ForegroundColor Red
        return $Settings
    }

    $lines = @(Get-Content $preset)
    $pattern = '(?i)^(?<prefix>.*sharp(ness)?\s*=\s*)(?<num>[\d.]+)(?<suffix>.*)$'
    $updated = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if (-not $updated -and $lines[$i] -match $pattern) {
            $lines[$i] = "$($Matches['prefix'])$value$($Matches['suffix'])"
            $updated = $true
        }
    }

    if ($updated) {
        Set-Content -Path $preset -Value $lines -Encoding UTF8
        $Settings.Sharpness = [double]$value
        Save-Settings $Settings
        Write-Host "Updated sharpness to $value in $preset" -ForegroundColor Green
    } else {
        Write-Host "Couldn't find a sharpness key in the preset - adjust it from the in-game overlay (Home key) instead." -ForegroundColor Yellow
    }
    return $Settings
}

function Launch-Game {
    param($Settings)
    if (-not (Require-GamePath $Settings)) { return }
    Write-Host "Launching GTA V Legacy (Story Mode)..." -ForegroundColor Cyan
    Start-Process -FilePath $Settings.GamePath -WorkingDirectory (Get-GameDir $Settings)
}

function Open-Readme {
    $readme = Join-Path $RepoRoot 'README.md'
    if (Test-Path $readme) {
        Start-Process -FilePath $readme
    } else {
        Write-Host "README.md not found at $readme" -ForegroundColor Yellow
    }
}

function Show-Menu {
    param($Settings)
    Clear-Host
    Write-Host "=============================================" -ForegroundColor DarkCyan
    Write-Host " GTA V Legacy - Clarity / Sharpening Menu" -ForegroundColor Cyan
    Write-Host " (Story Mode only - see README before using)" -ForegroundColor DarkYellow
    Write-Host "=============================================" -ForegroundColor DarkCyan
    Write-Host " Game path : $($Settings.GamePath)"
    Write-Host " ReShade   : $(if (Test-ReShadeInstalled $Settings) { 'detected' } else { 'not detected' })"
    Write-Host " Backup    : $($Settings.BackupPath)"
    Write-Host ""
    Write-Host " [1] Locate GTA V install"
    Write-Host " [2] Backup original files"
    Write-Host " [3] Adjust sharpness (after one-time overlay setup)"
    Write-Host " [4] Restore original files from backup"
    Write-Host " [5] Launch GTA V Legacy"
    Write-Host " [6] Open setup guide (README)"
    Write-Host " [0] Exit"
    Write-Host ""
}

$settings = Load-Settings
do {
    Show-Menu $settings
    $choice = Read-Host "Choose an option"
    try {
        switch ($choice) {
            '1' { $settings = Locate-Game $settings }
            '2' { $settings = Backup-GameFiles $settings }
            '3' { $settings = Set-Sharpness $settings }
            '4' { Restore-GameFiles $settings }
            '5' { Launch-Game $settings }
            '6' { Open-Readme }
            '0' { Write-Host "Bye." -ForegroundColor Cyan }
            default { Write-Host "Unknown option." -ForegroundColor Red }
        }
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
    if ($choice -ne '0') { Read-Host "`nPress Enter to continue" | Out-Null }
} while ($choice -ne '0')
