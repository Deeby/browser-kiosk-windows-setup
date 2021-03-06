# Scriptoteket startup script for kiosk screens
# Author: Dan Michael
# Modified: 2019-07-01

# ------------------------------------------------------------------------------------
# Settings:

# Path to some powerpoint file that can run in the background to prevent lock screen:
$powerpointFile = "C:\scriptotek\background.pptx"

# The URL for the Kiosk application:
$kioskUrl = "http://ub-www01.uio.no/propaganda/kommende-disputaser/mn.html"

# ------------------------------------------------------------------------------------


# 1. Ensure clean slate where nothing is running already
$apps = @("POWERPNT", "chrome")
foreach ($app in $apps) {
	Get-Process -Name $app -ErrorAction SilentlyContinue | Stop-Process
	Wait-Process -Name $app -ErrorAction SilentlyContinue
}

# 2. Start Powerpoint in background to prevent lock screen
Write-Host "Starting powerpoint..."
$powerpoint = New-Object -ComObject powerpoint.application
$powerpoint.visible = [Microsoft.Office.Core.MsoTriState]::msoTrue
$presentation = $powerpoint.Presentations.open($powerpointFile) 
$presentation.SlideShowSettings.Run()

# 3. Avoid Chrome restore dialog if Chrome did not exit cleanly
Write-Host "Fixing Chrome prefs..."
$chrome_prefs_file = Join-Path ${env:LOCALAPPDATA} "Google\Chrome\User Data\Default\Preferences"
$prefs = Get-Content $chrome_prefs_file -raw | ConvertFrom-Json
$prefs.profile.exit_type = "Normal"
$prefs.profile.exited_cleanly = $true
$prefs | ConvertTo-Json -depth 32 | set-content $chrome_prefs_file
      
# 4. Wait for network	  
Write-Host "Waiting for network..."
do {
	$ping = Test-Connection -ComputerName uio.no -Count 1 -Quiet
} until ($ping)

# 5. Start Chrome
Write-Host "Starting browser"
$chrome = Join-Path ${env:ProgramFiles(x86)} "Google\Chrome\Application\chrome.exe"
$chrome_args = "--kiosk --noerrdialogs --disable-infobars $kioskUrl"
Start-Process $chrome $chrome_args

# Debug:
# write-host "Press any key to close"
# [void][System.Console]::ReadKey($true)
