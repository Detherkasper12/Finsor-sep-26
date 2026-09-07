@echo off
echo ===========================================
echo       FINSOR - Personal Finance App
echo ===========================================
echo.
echo Step 1: Installing dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to install dependencies
    echo Please make sure Flutter is properly installed
    pause
    exit /b 1
)

echo.
echo SUCCESS: Dependencies installed!
echo.
echo Step 2: Running Finsor app on Chrome...
echo This may take a moment...
echo.
flutter run -d chrome
echo.
echo App finished running.
pause
