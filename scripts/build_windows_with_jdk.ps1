# Build Flutter Windows with JNI vars set (fix for "Could NOT find JNI").
# Usage: .\scripts\build_windows_with_jdk.ps1
# Or set JAVA_HOME first and run: flutter clean; flutter pub get; flutter build windows

$candidates = @()
if ($env:JAVA_HOME) { $candidates += $env:JAVA_HOME }
$candidates += (Get-ChildItem "C:\Program Files\Eclipse Adoptium\jdk-*" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
$candidates += (Get-ChildItem "C:\Program Files\Microsoft\jdk-*" -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName })
$candidates += "C:\Program Files\Android\Android Studio\jbr"

$jdkRoot = $null
foreach ($p in $candidates) {
    if ($p -and (Test-Path "$p\include\jni.h")) {
        $jdkRoot = $p
        break
    }
}

if ($jdkRoot) {
    $env:JAVA_HOME = $jdkRoot
    $env:JAVA_INCLUDE_PATH = "$jdkRoot\include"
    $env:JAVA_INCLUDE_PATH2 = "$jdkRoot\include\win32"
    Write-Host "Using JDK: $jdkRoot"
} else {
    Write-Host "No JDK with include/jni.h found. Set JAVA_HOME to a full JDK. See docs/windows_jni_fix.md"
    exit 1
}

Set-Location $PSScriptRoot\..
flutter clean
flutter pub get
flutter build windows
