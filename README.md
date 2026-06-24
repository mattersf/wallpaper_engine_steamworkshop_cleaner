# Wallpaper Engine Workshop Game Folder Cleanup Tool

**A smart, interactive PowerShell script to identify and manage duplicate game folders.** This tool was specifically designed for users who have multiple versions of the same game downloaded (e.g., from Steam Workshop, Wallpaper Engine, RPG Maker, Unity, or Ren'Py). It automatically detects older versions of the same game, presents them to you for a side-by-side comparison, and safely moves the duplicates to a trash folder upon your confirmation.

## ⚠️ Disclaimer & Notice

* **AI Generated:** This program was written by Gemini.
* **No Liability:** The author is **not responsible for any data loss, accidental deletions, or damage** caused by using this program.
* **Be Mindful:** This tool automates file detection but requires human confirmation for action. Users should be highly mindful, review the folder pairs carefully when prompted, and ensure important data is backed up before proceeding. Use entirely at your own risk.

## ✨ Features

* **🧠 Smart-Normalization Engine:** Accurately detects duplicates even when folder names differ due to versioning (e.g., `v1.0` vs `v1.5`) or copying (e.g., `Game - Copy` or `Game - 副本`).
* **⬆️ Dynamic Elevator (Grandparent Logic):** If a game's executable is buried deep inside generic folders (like `\bin\win64\` or `\www\`), the script automatically searches upward to find the correct identifying folder name.
* **🛡️ Auto-Generated Blocklist:** Includes a pre-loaded list of common generic engine components (like `[Tool]` or `MTool_Game.exe`) so it works effectively and safely right out of the box.
* **♻️ Safety First:** Duplicate folders are moved to a `_Duplicates_To_Trash` folder rather than being permanently deleted, allowing you to recover files if a mistake was made.

## 🚀 How to Use

### 1. Configuration

Open `gamecleanup.ps1` in a text editor like Notepad. On the second line, update the `$targetDir` variable to point to the directory you wish to scan (e.g., `$targetDir = "C:\Your\Path\Here"`).

### 2. Permissions (First-Time Setup)

If this is your first time running a PowerShell script on your system, you may need to allow local scripts to execute. Open an Administrator PowerShell window and run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

```

### 3. Run the Script

Right-click `gamecleanup.ps1` and select **"Run with PowerShell."**

## 🎮 Interactive Cleanup Menu

When the script identifies a duplicate, it will open both folders in Windows Explorer for you to compare and present the following prompt in the console:

* **`[Y]es` (Move to Trash):** Confirms the older folder is a true duplicate and moves it to the `_Duplicates_To_Trash` folder.
* **`[N]o` (Skip):** Keeps both folders and does nothing.
* **`[B]lock` (False Alarm):** Marks this match as a "False Alarm" and saves it to `saved_blocklist.txt`. The match will be ignored in all future scans, and the older folder will NOT be moved to the trash.
* **`[Q]uit`:** Immediately stops the script.
