@echo off
echo ===============================================
echo    MoneyTrail Play Store Builder (AAB)
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
    echo Please run this from Android Studio/VS Code terminal
    echo.
    echo Manual command: flutter build appbundle --release
    pause
    exit /b 1
)

echo Using Flutter at: %FLUTTER_PATH%
echo.

echo IMPORTANT: Make sure you have created a keystore file first!
echo If you haven't created a keystore, this build will be for testing only.
echo.
pause

REM Clean previous builds
echo [1/4] Cleaning previous builds...
"%FLUTTER_PATH%" clean

REM Get dependencies
echo [2/4] Getting dependencies...
"%FLUTTER_PATH%" pub get

REM Build App Bundle (AAB) for Play Store
echo [3/4] Building App Bundle for Play Store...
echo This may take a few minutes...
"C:\Users\ZULFIMUH\Flutter\flutter\bin\flutter.bat" build appbundle --release

REM Check if build was successful
if exist "build\app\outputs\bundle\release\app-release.aab" (
    echo.
    echo ===============================================
    echo       APP BUNDLE BUILD SUCCESSFUL! 🎉
    echo ===============================================
    echo.
    echo AAB Location: build\app\outputs\bundle\release\app-release.aab
    echo AAB Size: 
    for %%A in (build\app\outputs\bundle\release\app-release.aab) do echo %%~zA bytes
    echo.
    echo [4/4] Opening AAB folder...
    explorer build\app\outputs\bundle\release\
    echo.
    echo NEXT STEPS FOR PLAY STORE:
    echo 1. Create keystore file (for app signing)
    echo 2. Sign the AAB with your keystore
    echo 3. Create Google Play Developer account ($25)
    echo 4. Upload AAB to Play Console
    echo 5. Complete store listing (description, screenshots, etc.)
    echo.
    echo WARNING: This AAB is unsigned - you need to sign it first!
) else (
    echo.
    echo ===============================================
    echo       BUILD FAILED! ❌
    echo ===============================================
    echo Please check the error messages above.
)

echo.
pause 