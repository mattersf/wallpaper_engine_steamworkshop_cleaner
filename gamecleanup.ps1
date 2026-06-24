# CHANGE THIS to the folder you want to scan
$targetDir = "C:\Users\Eric\Desktop\CleanupDemo"

$trashDir = Join-Path -Path $targetDir -ChildPath "_Duplicates_To_Trash"
$blockListFile = Join-Path -Path $targetDir -ChildPath "saved_blocklist.txt"

# --- DEFAULT BLOCKLIST (Pre-loaded for your friends) ---
$defaultBlocks = @(
    "[Tool]", "[Wolfexe224p]", "MTool_Game.exe", "Game_zh-CN.exe", 
    "Lec.ExtProtocol.exe", "link.exe", "上传用.exe", "MTool.exe", 
    "[rm2k]", "GamePro.exe", "chromedriver.exe", "zsync.exe", 
    "elevate.exe", "zsyncmake.exe", "ReiPatcher.exe", "wolfexe224p", 
    "rm2k", "mtool"
)

# 1. LOAD OR GENERATE PERSISTENT BLOCKLIST
if (-not (Test-Path -Path $blockListFile)) { 
    $defaultBlocks | Out-File -FilePath $blockListFile -Encoding utf8
}
$savedBlocks = Get-Content -Path $blockListFile | Where-Object { $_.Trim() -ne "" }
if ($savedBlocks -eq $null) { $savedBlocks = @() }

# 2. SYSTEMIC FILTERS
$junkFiles = @("notification_helper", "vbhi", "unins", "setup", "crash", "unity", "redist", "prereq", "cef", "chromium", "python", "CPUInstructionCheck", "payload", "PIDDLLInject64", "steam_api", "d3d", "dx", "inject", "上传", "upload", "nwjc")
$genericExes = @("nw", "nwjs", "game", "play", "start", "launcher", "player", "app", "run")

# NEW: Folders to ignore when looking for the game name (forces script to go up one level)
$junkFolders = @("tool", "tools", "bin", "release", "win", "win32", "win64", "windows", "www", "data", "build")

Write-Host "Scanning... (Grandparent Folder Logic Enabled)" -ForegroundColor Cyan

$folders = Get-ChildItem -Path $targetDir -Directory | Where-Object { $_.Name -ne "_Duplicates_To_Trash" }
$gameLibrary = @{}

foreach ($folder in $folders) {
    $exes = Get-ChildItem -Path $folder.FullName -Filter *.exe -Recurse -File -ErrorAction SilentlyContinue | 
            Where-Object { 
                $fileName = $_.Name
                $isJunk = $false
                foreach ($j in $junkFiles) { if ($fileName -match "(?i)$j") { $isJunk = $true; break } }
                -not $isJunk
            }
    
    if ($exes.Count -gt 0) {
        $topExes = $exes | Sort-Object Length -Descending | Select-Object -First 3
        
        foreach ($exe in $topExes) {
            $baseName = $exe.BaseName
            $isGeneric = $false
            
            foreach ($g in $genericExes) { if ($baseName -match "(?i)^$g$") { $isGeneric = $true; break } }
            
            if ($isGeneric) {
                # Look at the folder where the generic engine is sitting
                $identityDir = $exe.Directory
                
                # --- GRANDPARENT FOLDER LOGIC ---
                # If the folder is named something generic like "Tool" or "bin", go up one level!
                if ($junkFolders -contains $identityDir.Name.ToLower()) {
                    if ($identityDir.Parent) {
                        $identityDir = $identityDir.Parent
                    }
                }
                
                $identityName = $identityDir.Name
                $displayGameName = "[$identityName] (Generic Engine: $($exe.Name))"
            } else {
                $identityName = $exe.Name
                $displayGameName = $exe.Name
            }
            
            # --- SMART NORMALIZATION ---
            $matchKey = $identityName.ToLower()
            $matchKey = $matchKey -replace '\s*-\s*copy.*|\s*-\s*副本.*|_\s*copy.*|_\s*副本.*', ''
            $matchKey = $matchKey -replace '\s+v?\d+(\.\d+)*.*|_v?\d+(\.\d+)*.*', ''
            $matchKey = $matchKey.Trim()
            
            if (-not $gameLibrary.ContainsKey($matchKey)) { 
                $gameLibrary[$matchKey] = @{
                    DisplayName = $displayGameName
                    Folders     = @()
                } 
            }
            
            if (-not ($gameLibrary[$matchKey].Folders | Where-Object { $_.RootPath -eq $folder.FullName })) {
                $gameLibrary[$matchKey].Folders += [PSCustomObject]@{
                    RootPath   = $folder.FullName
                    FolderName = $folder.Name
                    Date       = $folder.LastWriteTime
                }
            }
        }
    }
}

# ----------------------------------------------------
# INTERACTIVE CLEANUP
# ----------------------------------------------------
if (-not (Test-Path -Path $trashDir)) { New-Item -ItemType Directory -Path $trashDir | Out-Null }

$skippedPairs = @()
$foundAny = $false

foreach ($matchKey in $gameLibrary.Keys) {
    if ($savedBlocks -contains $matchKey) { continue }

    $group = $gameLibrary[$matchKey].Folders | Sort-Object Date -Descending
    $displayTitle = $gameLibrary[$matchKey].DisplayName
    
    if ($group.Count -gt 1) {
        $newest = $group[0]
        for ($i = 1; $i -lt $group.Count; $i++) {
            $older = $group[$i]
            
            $pairID = ($newest.FolderName, $older.FolderName | Sort-Object) -join "_"
            if ($skippedPairs -contains $pairID) { continue }
            
            $foundAny = $true
            Write-Host "`n==================================================" -ForegroundColor Yellow
            Write-Host "DUPLICATE FOUND" -ForegroundColor Cyan
            Write-Host "Matched Identity: $displayTitle" -ForegroundColor Cyan
            Write-Host "Keep Newest: $($newest.FolderName) (Edited: $($newest.Date))" -ForegroundColor Green
            Write-Host "Trash Older: $($older.FolderName) (Edited: $($older.Date))" -ForegroundColor Red
            
            Invoke-Item $newest.RootPath
            Invoke-Item $older.RootPath
            
            $resp = Read-Host "Move to trash? [Y]es / [N]o (Skip pair) / [B]lock this match forever / [Q]uit"
            
            if ($resp -match "^(?i)q") { exit }
            elseif ($resp -match "^(?i)b") {
                Write-Host "Permanently blocking '$matchKey'." -ForegroundColor Magenta
                $savedBlocks += $matchKey
                Add-Content -Path $blockListFile -Value $matchKey
                break
            }
            elseif ($resp -match "^(?i)n") {
                Write-Host "Skipping this specific folder pair." -ForegroundColor Gray
                $skippedPairs += $pairID
            }
            elseif ($resp -match "^(?i)y") {
                Move-Item -Path $older.RootPath -Destination (Join-Path $trashDir $older.FolderName) -Force
                Write-Host "Moved to trash." -ForegroundColor Yellow
                $skippedPairs += $pairID
            }
        }
    }
}

if (-not $foundAny) { Write-Host "No duplicates found." -ForegroundColor Green }
Write-Host "`nDone!" -ForegroundColor Green
Pause