# Repairs SkyrimNet's Actions.yaml after SkyrimNet Slave Auction 0.1.0.
#
# 0.1.0 set the cooldowns of the AI actions below on every auction (7200 seconds at a capture, 0 at
# the end), and SkyrimNet saved them in Actions.yaml. This removes those entries, so each action goes
# back to the default its own mod gives it.
#
# Only an entry that holds exactly what 0.1.0 leaves is removed: "enabled: true" and a cooldown of 0
# or 7200. An entry with anything else in it (the action switched off, another cooldown, another
# setting) is the player's own and is left as it is, and listed. Nothing else in the file is touched.
# If no entry is left, the file is deleted, which is how SkyrimNet starts on a fresh install.
#
# A copy of the file is made first, as Actions.yaml.bak (or with a date added, if that name is
# taken). To undo, delete Actions.yaml and rename the copy back to Actions.yaml.
#
# Use: drop Actions.yaml onto RepairSkyrimNetActions.bat, with the game closed.

param([string]$Path, [switch]$NoPause, [switch]$SkipGameCheck)   # the switches are for testing

$ErrorActionPreference = 'Stop'
$section = ''
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

function Say([string]$en, [string]$ja) {
    Write-Host $en
    Write-Host $ja
    Write-Host ''
}

function Finish([int]$code) {
    if (-not $NoPause) { Read-Host 'Press Enter to close / Enter キーで閉じます' | Out-Null }
    exit $code
}

# The actions 0.1.0 changed. SkyrimNet ignores case in these names and may save them in another case.
$names = @(
    'BDSMLOCK',
    'EQUIP_ARMBINDERS_', 'EQUIP_ARM_CUFFS_', 'EQUIP_BLINDFOLDS_', 'EQUIP_BOOTS_', 'EQUIP_BUTTERFLY_BINDERS_',
    'EQUIP_CHASTITY_BELTS_', 'EQUIP_CHASTITY_BELTS_Exp', 'EQUIP_CHASTITY_BRAS_', 'EQUIP_COLLARS_', 'EQUIP_CORSETS_',
    'EQUIP_ELBOW_BINDERS_', 'EQUIP_ELBOW_BINDERS___', 'EQUIP_GAGS_', 'EQUIP_GLOVES_', 'EQUIP_HARNESSES_',
    'EQUIP_HARNESSES_Exp', 'EQUIP_HOODS_', 'EQUIP_LEG_CUFFS_', 'EQUIP_PIERCINGS_', 'EQUIP_PLUGS_',
    'EQUIP_STRAITJACKETS_', 'EQUIP_SUITS_', 'EQUIP_YOKES_',
    'KidnapNPC', 'RestrainNPC', 'TieCaptiveToFurniture',
    'Start_Fighting', 'AttackTarget', 'ThugAttack', 'Brawl', 'ChallengeBrawl', 'AcceptBrawl',
    'GetDressed', 'outfit_dress', 'EquipArmor', 'DOMSlave_dress', 'ApplyOutfitPreset', 'SetSituationOutfit'
)
$wanted = @{}
foreach ($n in $names) { $wanted[$n.ToLowerInvariant()] = $true }

# True when an entry's setting lines are exactly what 0.1.0 leaves.
function Is-AuctionValue([string[]]$settings) {
    $enabled = $false
    $cooldown = $false
    foreach ($s in $settings) {
        $t = $s.Trim()
        if ($t -eq '') { continue }
        if ($t -match '^enabled:\s*true$') { $enabled = $true; continue }
        if ($t -match '^cooldownSeconds:\s*(0|7200)$') { $cooldown = $true; continue }
        return $false
    }
    return $enabled -and $cooldown
}

try {
    if (-not $Path) {
        Say 'Drop Actions.yaml onto RepairSkyrimNetActions.bat.' 'Actions.yaml を RepairSkyrimNetActions.bat の上にドロップしてください。'
        Finish 1
    }
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf) -or [System.IO.Path]::GetFileName($Path) -ne 'Actions.yaml') {
        Say "Not an Actions.yaml file: $Path" "Actions.yaml ではありません: $Path"
        Finish 1
    }
    if (-not $SkipGameCheck -and (Get-Process -Name 'SkyrimSE', 'SkyrimVR', 'Skyrim' -ErrorAction SilentlyContinue)) {
        Say 'Close Skyrim first: SkyrimNet saves this file again while the game runs. Nothing was changed.' '先に Skyrim を終了してください。ゲームの実行中は SkyrimNet がこのファイルを保存し直します。何も変更していません。'
        Finish 1
    }

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    $text = (New-Object System.Text.UTF8Encoding($false, $true)).GetString($bytes)   # throws on bytes that are not UTF-8
    if ($hasBom) { $text = $text.Substring(1) }
    if ($text.Contains("`t")) {
        Say 'This file uses tabs, which SkyrimNet does not write. Nothing was changed.' 'このファイルにはタブがあり、SkyrimNet が書いた形ではありません。何も変更していません。'
        Finish 1
    }
    $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $lines = $text -split "`r?`n"

    # Top-level keys start in the first column; the entries of "actions:" are indented by two spaces,
    # and their settings by more. Blank lines belong to whatever surrounds them.
    $out = New-Object System.Collections.Generic.List[string]
    $removed = New-Object System.Collections.Generic.List[string]
    $leftAlone = New-Object System.Collections.Generic.List[string]
    $sawActions = $false
    $remaining = 0
    $i = 0
    while ($i -lt $lines.Length) {
        $line = $lines[$i]
        if ($line -match '^\S') {
            $out.Add($line)
            if ($line -match '^actions:\s*$') { $sawActions = $true; $section = 'actions' } else { $section = '' }
            $i++
            continue
        }
        if ($section -eq 'actions' -and $line -match '^  (\S[^:]*):\s*$') {
            $name = $Matches[1].Trim().Trim('"', "'")
            $block = New-Object System.Collections.Generic.List[string]
            $block.Add($line)
            $j = $i + 1
            while ($j -lt $lines.Length -and ($lines[$j] -match '^   ' -or ($lines[$j].Trim() -eq '' -and $j + 1 -lt $lines.Length -and $lines[$j + 1] -match '^   '))) {
                $block.Add($lines[$j])
                $j++
            }
            $settings = @($block | Select-Object -Skip 1)
            if ($wanted.ContainsKey($name.ToLowerInvariant()) -and (Is-AuctionValue $settings)) {
                $removed.Add($name)
            } else {
                if ($wanted.ContainsKey($name.ToLowerInvariant())) { $leftAlone.Add($name) }
                foreach ($b in $block) { $out.Add($b) }
                $remaining++
            }
            $i = $j
            continue
        }
        $out.Add($line)
        $i++
    }

    if (-not $sawActions) {
        Say 'This file does not look like SkyrimNet''s Actions.yaml. Nothing was changed.' 'SkyrimNet の Actions.yaml ではないようです。何も変更していません。'
        Finish 1
    }
    if ($leftAlone.Count -gt 0) {
        Say "Left as they are, because they hold your own settings: $([string]::Join(', ', $leftAlone))" "あなたの設定が入っているため、そのままにした項目: $([string]::Join(', ', $leftAlone))"
    }
    if ($removed.Count -eq 0) {
        Say 'Nothing to repair. Nothing was changed.' '修復が必要な項目はありません。何も変更していません。'
        Finish 0
    }

    $backup = "$Path.bak"
    if (Test-Path -LiteralPath $backup) { $backup = "$Path.$(Get-Date -Format 'yyyyMMdd-HHmmss').bak" }
    Copy-Item -LiteralPath $Path -Destination $backup
    if (-not (Test-Path -LiteralPath $backup -PathType Leaf) -or (Get-Item -LiteralPath $backup).Length -ne $bytes.Length) {
        Say 'The backup could not be made. Nothing was changed.' '控えを作れませんでした。何も変更していません。'
        Finish 1
    }

    $otherTopLevel = @($out | Where-Object { $_ -match '^\S' -and $_ -notmatch '^actions:\s*$' }).Count
    if ($remaining -eq 0 -and $otherTopLevel -eq 0) {
        Remove-Item -LiteralPath $Path
        Say 'No entry was left, so Actions.yaml was deleted: SkyrimNet starts without it on a fresh install.' '項目が残らないため、Actions.yaml を削除しました。SkyrimNet は新規インストールのとき、このファイルなしで始まります。'
    } else {
        $encoding = New-Object System.Text.UTF8Encoding($hasBom)
        [System.IO.File]::WriteAllText($Path, [string]::Join($newline, $out), $encoding)
    }

    Say "Removed $($removed.Count) entries: $([string]::Join(', ', $removed))" "$($removed.Count) 件を削除しました: $([string]::Join(', ', $removed))"
    Say "Backup: $backup" "控え: $backup"
    Say 'To undo, delete Actions.yaml (if it is there) and rename the backup to Actions.yaml.' '元に戻すには、Actions.yaml があれば削除し、控えの名前を Actions.yaml に戻してください。'
    Finish 0
} catch {
    Say "Something went wrong: $($_.Exception.Message)" "問題が起きました: $($_.Exception.Message)"
    Say 'If a backup was made, it is next to Actions.yaml.' '控えを作っていれば、Actions.yaml と同じ場所にあります。'
    Finish 2
}
