# A PowerShell script to verify Unity app installation and test deep links

Write-Host "==== Unity App Installation Verification ====" -ForegroundColor Cyan
Write-Host "Checking if the Unity app is installed..." -ForegroundColor Cyan

# Check if adb is available
try {
    $adbVersion = & adb version
    if (-not $adbVersion) {
        throw "No output from adb command"
    }
}
catch {
    Write-Host "Error: adb is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Android Debug Bridge (adb) to use this script" -ForegroundColor Red
    exit 1
}

# Check for connected devices
$devices = & adb devices | Select-String -Pattern "device$" -NotMatch "List"
if (-not $devices) {
    Write-Host "Error: No connected Android device found" -ForegroundColor Red
    Write-Host "Please connect an Android device and enable USB debugging" -ForegroundColor Red
    exit 1
}

Write-Host "Device(s) found:" -ForegroundColor Green
& adb devices | Where-Object { $_ -notmatch "List" }
Write-Host ""

# Check if the Unity app is installed
Write-Host "Checking for Unity Classroom app..." -ForegroundColor Cyan
$packageExists = & adb shell "pm list packages | grep -i 'DefaultCompany.classroomtest'"

if (-not $packageExists) {
    Write-Host "❌ Unity Classroom app NOT found on the device" -ForegroundColor Red
    Write-Host "   Please make sure you've built and installed the Unity app correctly" -ForegroundColor Yellow
}
else {
    Write-Host "✅ Unity Classroom app found: $packageExists" -ForegroundColor Green
}

# Find the exact package name
Write-Host ""
Write-Host "Searching for all packages containing 'DefaultCompany'..." -ForegroundColor Cyan
$defaultPackages = & adb shell "pm list packages | grep -i 'DefaultCompany'"
Write-Host $defaultPackages

Write-Host ""
Write-Host "==== Testing Deep Links ===="
Write-Host "1. Testing direct package launch" -ForegroundColor Cyan
& adb shell "am start -n com.DefaultCompany.classroomtest/com.unity3d.player.UnityPlayerActivity"
Write-Host ""

Write-Host "2. Testing original deep link (unityapp://open)" -ForegroundColor Cyan
& adb shell "am start -a android.intent.action.VIEW -d 'unityapp://open'"
Write-Host ""

Write-Host "3. Testing alternative deep link (bravespace://vr/launch)" -ForegroundColor Cyan
& adb shell "am start -a android.intent.action.VIEW -d 'bravespace://vr/launch'"
Write-Host ""

Write-Host ""
Write-Host "==== Unity App Manifest Information ====" -ForegroundColor Cyan
Write-Host "Getting manifest information for package: com.DefaultCompany.classroomtest" -ForegroundColor Cyan
& adb shell "dumpsys package com.DefaultCompany.classroomtest | grep -A 10 'intent filter'"

Write-Host ""
Write-Host "Tests completed. Check the output above for any errors or issues." -ForegroundColor Green
Write-Host "If deep linking is not working, verify that your AndroidManifest.xml has the correct intent filters." -ForegroundColor Yellow 