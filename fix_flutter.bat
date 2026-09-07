@echo off
echo Fixing Flutter Dart SDK issue...
echo.
echo Killing all Dart and Flutter processes...
taskkill /f /im dart.exe 2>nul
taskkill /f /im flutter.exe 2>nul
taskkill /f /im flutter_tools.exe 2>nul
taskkill /f /im dartaotruntime.exe 2>nul

echo.
echo Waiting 3 seconds...
timeout /t 3 /nobreak >nul

echo.
echo Trying to run Flutter commands...
flutter pub get
if %errorlevel% neq 0 (
    echo.
    echo Flutter pub get failed. Try running this script as Administrator.
    pause
    exit /b 1
)

echo.
echo Running Flutter app...
flutter run -d chrome
pause
