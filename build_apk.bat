@echo off
echo ===============================================
echo       MoneyTrail APK Builder
echo ===============================================
echo.

REM Try to find Flutter installation
set FLUTTER_PATH=
for /f "tokens=*" %%i in ('where flutter 2^>nul') do set FLUTTER_PATH=%%i

if not defined FLUTTER_PATH (
    echo Flutter not found in PATH. Trying common locations...
    
    REM Check common Flutter installation paths
    if exist "C:\flutter\bin\flutter.bat" set FLUTTER_PATH=C:\flutter\bin\flutter.bat
    if exist "%USERPROFILE%\flutter\bin\flutter.bat" set FLUTTER_PATH=%USERPROFILE%\flutter\bin\flutter.bat
    if exist "C:\src\flutter\bin\flutter.bat" set FLUTTER_PATH=C:\src\flutter\bin\flutter.bat
    if exist "%LOCALAPPDATA%\flutter\bin\flutter.bat" set FLUTTER_PATH=%LOCALAPPDATA%\flutter\bin\flutter.bat
)

if not defined FLUTTER_PATH (
    echo ERROR: Flutter installation not found!
    echo Please install Flutter or run this from Android Studio/VS Code terminal
    echo.
    echo Alternative: Open Android Studio/VS Code and run:
    echo flutter build apk --release
    pause
    exit /b 1
)

echo Using Flutter at: %FLUTTER_PATH%
echo.

REM Clean previous builds
echo [1/4] Cleaning previous builds...
"%FLUTTER_PATH%" clean

REM Get dependencies
echo [2/4] Getting dependencies...
"%FLUTTER_PATH%" pub get

REM Build APK in release mode
echo [3/4] Building APK (Release Mode)...
echo This may take a few minutes...
"%FLUTTER_PATH%" build apk --release

REM Check if build was successful
if exist "build\app\outputs\flutter-apk\app-release.apk" (
    echo.
    echo ===============================================
    echo       BUILD SUCCESSFUL! 🎉
    echo ===============================================
    echo.
    echo APK Location: build\app\outputs\flutter-apk\app-release.apk
    echo APK Size: 
    for %%A in (build\app\outputs\flutter-apk\app-release.apk) do echo %%~zA bytes
    echo.
    echo [4/4] Opening APK folder...
    explorer build\app\outputs\flutter-apk\
    echo.
    echo TO INSTALL ON YOUR PHONE:
    echo 1. Copy app-release.apk to your phone
    echo 2. Enable "Install from Unknown Sources" in Settings
    echo 3. Tap the APK file to install
    echo 4. Enjoy MoneyTrail! 📱💰
) else (
    echo.
    echo ===============================================
    echo       BUILD FAILED! ❌
    echo ===============================================
    echo Please check the error messages above.
    echo Try running from Android Studio/VS Code terminal instead.
)

echo.
pause 