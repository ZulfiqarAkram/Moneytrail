@echo off
echo Generating app icons for MoneyTrail...

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
    pause
    exit /b 1
)

echo Using Flutter at: %FLUTTER_PATH%

REM Get dependencies
echo Getting packages...
"%FLUTTER_PATH%" pub get

REM Generate icons
echo Generating app icons...
"%FLUTTER_PATH%" pub run flutter_launcher_icons

echo.
echo App icon generation complete!
echo Please restart your app and simulator to see the new icon.
pause 